#!/bin/bash

# ------- 用户可自定义的变量 -------
# mysql 数据库 root 用户密码
XXX_DB_ROOT_PASS='XxxPass!1'
# 配置文件,说明:
# 	key - 必须手动指定的参数
# 	key="xxx" - 未提供时的默认参数
config_keys='
# [xxx system]
initTimeStamp="placeholder"

# [portal]
PORTAL_IPADDRESS="192.168.1.60"
PORTAL_HTTPS_PORT="443"
PORTAL_USER="shark"
PORTAL_PASSWORD="password"

# [xxx DB]
XXX_DB_HOST="localhost"
XXX_DB_PORT="3306"
XXX_DB_USER="xxx"
XXX_DB_PASSWORD="XxxPS!11"
XXX_DB_DATABASE="xxx"
'
# ------- 用户可自定义的变量 -------

# ------- 全局变量 -------
source_path=$(cd $(dirname $0); pwd)
conf_dir=/etc/xxx
conf_filename=xxx.conf
yum_repo_dir=/etc/yum.repos.d
install_repo_dir=${source_path}/xxxinstallrepo
update_repo_dir=${source_path}/xxxupdaterepo
install_repo_file=${yum_repo_dir}/xxxinstallrepo.repo
update_repo_file=${yum_repo_dir}/xxxupdaterepo.repo
now_str=$(date +"%Y%m%d%H%M%S")
repo_backup_dir=${yum_repo_dir}/backup
log_file=./xxx_setup_${now_str}.log

noout_str=">/dev/null 2>&1"
tolog_str="2>&1 | tee -a $log_file"
# ------- 全局变量 -------

# ------- 通用模块 -------
log() {
	echo "$@" >> "$log_file"
}

pinfo() {
	echo -e "[\033[32m INFO \033[0m] $*"
	log [ INFO ] "$@"
}

pwarn() {
	echo -e "[\033[33m WARN \033[0m] $*"
	log [ WARN ] "$@"
}

perror() {
	echo -e "[\033[31mFAILED\033[0m] $*"
	log [FAILED] "$@"
}

warn_action() {
	pwarn "$*"
	read -p "         Press [Enter] to continue or [Ctrl+c] to exit: "
}

quit() {
	exit 1
}

now() {
	date +"%Y%m%d%H%M%S"
}
# ------- 通用模块 -------

# ------- 本地 yum 仓库构建模块 -------
create_repo() {
	local action=${1:-install}
	if [[ "${action}" == "install" ]]; then
		if [[ ! -d ${install_repo_dir} ]]; then
			eval tar -xf ${install_repo_dir}.tar.gz -C ${source_path} ${tolog_str}
			[[ $? -ne 0 ]] && exit
		fi
		pinfo "create temporary xxx install repo"
		createrepo ${install_repo_dir}
		[[ $? -ne 0 ]] && perror "failed to create temporary xxx install repo" && quit
                pinfo "done"

		pinfo "backup /etc/yum.repo.d/*.repo to ${repo_backup_dir}"
		[[ ! -d ${repo_backup_dir} ]] && mkdir ${repo_backup_dir}
		mv /etc/yum.repos.d/*.repo ${repo_backup_dir}
		pinfo "create file ${install_repo_file}"
		cat > ${install_repo_file} << eof
[xxxinstallrepo]
name=xxxinstallrepo
baseurl=file://${install_repo_dir}
enabled=1
gpgcheck=0
eof
	        [[ $? != 0 ]] && quit
		pinfo "done"
	elif [[ "${action}" == "update" ]]; then
                if [[ ! -d ${update_repo_dir} ]]; then
                        eval tar -xf ${update_repo_dir}.tar.gz -C ${source_path} ${tolog_str}
			[[ $? -ne 0 ]] && exit
                fi
		pinfo "create temporary xxx update repo"
                createrepo ${update_repo_dir}
		[[ $? -ne 0 ]] && perror "failed to create temporary xxx update repo" && quit
                pinfo "done"

                pinfo "backup /etc/yum.repo.d/*.repo to ${repo_backup_dir}"
                [[ ! -d ${repo_backup_dir} ]] && mkdir ${repo_backup_dir}
                mv /etc/yum.repos.d/*.repo ${repo_backup_dir}
                pinfo "create file ${update_repo_file}"
                cat > ${update_repo_file} << eof
[xxxupdaterepo]
name=xxxupdaterepo
baseurl=file://${update_repo_dir}
enabled=1
gpgcheck=0
eof
                [[ $? != 0 ]] && quit
                pinfo "done"
	fi
}
# ------- 本地 yum 仓库构建模块 -------

# ------- 安装模块 -------
install_createrepo() {
	pinfo "start to install rpm [createrepo]"
	if [ $(rpm -qa | grep -c createrepo) -ge 1 ]; then
        	pinfo "rpm [createrepo] has been installed"
		return
        fi
	if [[ ! -d ${install_repo_dir} ]]; then
		eval tar -xf ${install_repo_dir}.tar.gz -C ${source_path} ${tolog_str}
	fi
        yum install -y ${install_repo_dir}/pre/*.rpm
        [[ $? != 0 ]] && quit
        pinfo "done"
}
# 安装软件，update 可选
# 格式：install_xxx "tree" [update]
install_xxx() {
	for i in $1; do
		pinfo "start to install rpm [$i]"
		if [[ "$2" != "update" && $(rpm -qa | grep -c $i) -ge 1 ]]; then
	            pinfo "rpm [$i] has been installed"
	            continue
	        fi
		yum install -y $i
		[[ $? != 0 ]] && quit
		pinfo "done"
	done
}

uninstall_xxx() {
	for i in $1; do
		pinfo "start to uninstall rpm [$i]"
		yum remove -y xxx
		[[ $? != 0 ]] && quit
		pinfo "done"
	done
}
# ------- 安装模块 -------

# ------- 善后模块 -------
# 恢复备份文件
restore_repo_file() {
	pinfo "restore repo files from backup"
	eval mv ${repo_backup_dir}/*.repo ${yum_repo_dir} ${tolog_str}
	[[ $? -eq 0 ]] && pinfo "done"
	pinfo "remove ${repo_backup_dir}"
	eval rm -r ${repo_backup_dir} ${tolog_str}
	[[ $? -eq 0 ]] && pinfo "done"
}
# 安装成功后的步骤
after_install() {
	pinfo "clean repo directory"
	eval rm -r ${install_repo_dir} ${tolog_str}
	[[ $? -eq 0 ]] && pinfo "done"

	restore_repo_file

	pinfo "clean temporary repo file"
	eval rm ${install_repo_file} ${tolog_str}
	[[ $? -eq 0 ]] && pinfo "done"
}
# 更新成功后的步骤
after_update() {
	pinfo "clean repo directory"
	eval rm -r ${update_repo_dir} ${tolog_str}
	[[ $? -eq 0 ]] && pinfo "done"

	restore_repo_file

	pinfo "clean temporary repo file"
	eval rm ${update_repo_file} ${tolog_str}
	[[ $? -eq 0 ]] && pinfo "done"
}
# ------- 善后模块 -------

# ------- 配置模块 -------
check_config() {
	pinfo "start to check the configuration"
	local conf_file="${source_path}/${conf_filename}.in"
	if [[ ! -r "${conf_file}" ]]; then
		perror "file ${conf_file} not exist!"
		quit
	fi
	if [[ ! -d ${conf_dir} ]]; then
		pinfo "create directory ${conf_dir}"
		eval mkdir ${conf_dir} ${tolog_str}
		[[ $? -ne 0 ]] && quit
	fi

	local conf_file="${conf_dir}/${conf_filename}"
	local conf_infile="${conf_dir}/${conf_filename}.in"
	oldifs=${IFS}
        IFS=$'\n'
	# 如果配置文件已存在则说明已经配置过了，需要根据配置文件更新 mysql 数据库配置，否则就新建配置文件
	if [[ -r "${conf_dir}/${conf_filename}" ]]; then
		for i in ${config_keys}; do
			if [[ ! "$i" || "$i" =~ ^# ]]; then
					continue
			fi
			if [[ $i =~ '="' ]]; then
					local key=${i%%=*}
					local default_val=${i#*=}
			else
					local key=$i
			fi
			if [[ $(grep -c "${key}" ${conf_file}) -ne 1 && ! ${default_val} ]]; then
					perror "the key [${key}] does not exist or is repeatedly defined in the configuration file [${conf_file}]"
					quit
			else
					local default_trim_val=${default_val//\"/}
					case ${key} in
							"XXX_DB_PORT")
									XXX_DB_PORT=${default_trim_val}
									;;
							"XXX_DB_USER")
									XXX_DB_USER=${default_trim_val}
									;;
							"XXX_DB_PASSWORD")
									XXX_DB_PASSWORD=${default_trim_val}
									;;
							"XXX_DB_DATABASE")
									XXX_DB_DATABASE=${default_trim_val}
									;;
					esac
					local kv=$(grep "${key}" ${conf_file})
					if [[ ${kv} =~ '=' ]]; then
							local kv=${kv//\"/}
							local val=${kv#*=}
							case ${key} in
									"XXX_DB_PORT")
											XXX_DB_PORT=${val}
											;;
									"XXX_DB_USER")
											XXX_DB_USER=${val}
											;;
									"XXX_DB_PASSWORD")
											XXX_DB_PASSWORD=${val}
											;;
									"XXX_DB_DATABASE")
											XXX_DB_DATABASE=${val}
											;;
							esac
					fi
			fi
		done
	else
		pinfo "copy template configuration file to ${conf_infile}"
		eval cp -f ${source_path}/${conf_filename}.in ${conf_dir} ${tolog_str}
		[[ $? -ne 0 ]] && quit
		for i in ${config_keys}; do
			if [[ ! "$i" || "$i" =~ ^# ]]; then
				continue
			fi
			if [[ $i =~ '="' ]]; then
				local key=${i%%=*}
				local default_val=${i#*=}
			else
				local key=$i
			fi
			if [[ $(grep -c "${key}" ${conf_infile}) -ne 1 && ! ${default_val} ]]; then
				perror "the key [${key}] does not exist or is repeatedly defined in the configuration file [${conf_infile}]"
				quit
			else
				local default_trim_val=${default_val//\"/}
				case ${key} in
					"initTimeStamp")
						i="initTimeStamp=$(date +%s)"
						;;
					"XXX_DB_PORT")
						XXX_DB_PORT=${default_trim_val}
						;;
					"XXX_DB_USER")
						XXX_DB_USER=${default_trim_val}
						;;
					"XXX_DB_PASSWORD")
						XXX_DB_PASSWORD=${default_trim_val}
						;;
					"XXX_DB_DATABASE")
						XXX_DB_DATABASE=${default_trim_val}
						;;
				esac
				if [[ $(grep -c "${key}" ${conf_infile}) -ne 1 ]]; then
					pinfo "add configuration [ $i ]"
					if [[ ${key} =~ ^PORTAL_ ]]; then
						sed -i "/\[portal]/a $i" ${conf_infile}
					elif [[ ${key} =~ ^XXX_DB_ ]]; then
						sed -i "/\[xxx DB]/a $i" ${conf_infile}
					else
						sed -i "/\[xxx system]/a $i" ${conf_infile}
					fi
				else
					local kv=$(grep "${key}" ${conf_infile})
					if [[ ${kv} =~ '=' ]]; then
						local kv=${kv//\"/}
						local val=${kv#*=}
						case ${key} in
							"XXX_DB_HOST")
								pinfo "change configuration [ $i ]"
								sed -i "/XXX_DB_HOST/c $i" ${conf_infile}
								;;
							"XXX_DB_PORT")
								XXX_DB_PORT=${val}
								;;
							"XXX_DB_USER")
								XXX_DB_USER=${val}
								;;
							"XXX_DB_PASSWORD")
								XXX_DB_PASSWORD=${val}
								;;
							"XXX_DB_DATABASE")
								XXX_DB_DATABASE=${val}
								;;
						esac
					fi
				fi
			fi
		done
		pinfo "create configuration file ${conf_file}"
		eval mv ${conf_infile} ${conf_file} ${tolog_str}
		[[ $? -ne 0 ]] && quit
	fi
	IFS=${oldifs}
	pinfo "done"
}

config_mysql() {
	pinfo "start to config mysql"
	local xxx_pass="${XXX_DB_PASSWORD}"
	mysql -P ${XXX_DB_PORT} -u${XXX_DB_USER} -p${xxx_pass} -e "show databases" 2>&1 | grep "${XXX_DB_DATABASE}" 2>&1 >/dev/null
	if [[ $? -eq 0 ]]; then
                pinfo "mysql has been configed"
                return
        fi
	if [ $(rpm -qa | grep -c mysql-community-server) -lt 1 ]; then
                perror "mysql has not been installed"
		quit
        fi
	eval grep "port=" /etc/my.cnf ${noout_str}
	if [[ $? -eq 0 ]]; then
		sed -i "/port=/c port=${XXX_DB_PORT}" /etc/my.cnf
	else
		sed -i "/\[mysqld]/a port=${XXX_DB_PORT}" /etc/my.cnf
	fi
	eval mysqld --initialize-insecure --user=mysql ${noout_str}
	sleep 3
	systemctl start mysqld
	systemctl --quiet is-active mysqld
	if [[ $? -ne 0 ]]; then
		perror "failed to start mysql service"
		quit
	fi
	eval systemctl enable mysqld ${noout_str}

	local root_pass="${XXX_DB_ROOT_PASS}"
	mysql -P ${XXX_DB_PORT} -u root -e "select 1" 2>&1 >/dev/null
	if [[ $? -eq 0 ]]; then
		pinfo "alter mysql db user root's password"
		mysql -P ${XXX_DB_PORT} -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${root_pass}';"
		if [[ $? -ne 0 ]]; then
			perror "failed to alter mysql db user [root]s password"
			quit
		fi
	fi
	pinfo "create mysql db user [${XXX_DB_USER}]"
	mysql -P ${XXX_DB_PORT} -u root -p${root_pass} -e "CREATE USER IF NOT EXISTS '${XXX_DB_USER}'@'localhost' IDENTIFIED BY '${XXX_DB_PASSWORD}';"
	if [[ $? -ne 0 ]]; then
		perror "failed to create mysql db user [${XXX_DB_USER}]"
		quit
	fi
	pinfo "create mysql db [${XXX_DB_DATABASE}]"
	mysql -P ${XXX_DB_PORT} -u root -p${root_pass} -e "CREATE DATABASE IF NOT EXISTS \`${XXX_DB_DATABASE}\` CHARACTER SET 'utf8';"
	if [[ $? -ne 0 ]]; then
		perror "failed to create mysql db [${XXX_DB_DATABASE}]"
		quit
	fi
        pinfo "grant PRIVILEGES to mysql db user '${XXX_DB_USER}'@'localhost'"
	mysql -P ${XXX_DB_PORT} -u root -p${root_pass} -e "GRANT ALL ON \`${XXX_DB_DATABASE}\`.* TO '${XXX_DB_USER}'@'localhost';"
	if [[ $? -ne 0 ]]; then
                perror "failed to grant PRIVILEGES to mysql db user '${XXX_DB_USER}'@'localhost'"
                quit
        fi
	pinfo "done"
}

config_xxx() {
	pinfo "start to config xxx"
	local xxx_pass="${XXX_DB_PASSWORD}"
	local xxx_db_name="${XXX_DB_DATABASE}"
	mysql -P ${XXX_DB_PORT} -u${XXX_DB_USER} -p${xxx_pass} -D${xxx_db_name} -e "select * from xxx_datacenter_peak_status_daily" >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		mysql -P ${XXX_DB_PORT} -u${XXX_DB_USER} -p${xxx_pass} -D${xxx_db_name} < ${conf_dir}/sql/xxx.sql
		mysql -P ${XXX_DB_PORT} -u${XXX_DB_USER} -p${xxx_pass} -D${xxx_db_name} < ${conf_dir}/sql/quartz.sql
		mysql -P ${XXX_DB_PORT} -u${XXX_DB_USER} -p${xxx_pass} -D${xxx_db_name} < ${conf_dir}/sql/ry.sql
		[[ $? -ne 0 ]] && perror "failed to initialize the xxx database ${xxx_db_name}" && quit
	fi

	# 添加统计数据
	if [[ $(mysql -P ${XXX_DB_PORT} -u${XXX_DB_USER} -p${xxx_pass} -D${xxx_db_name} -e "select * from xxx_datacenter_peak_status_daily" 2>&1 | wc -l) -le 1 ]]; then
		pinfo "add statistics data to mysql db"
		eval xxx-statistics -from $(date -d "6 months ago" +"%Y-%m-%d") -to $(date +"%Y-%m-%d") ${tolog_str}
		pinfo "done"
	fi
	pinfo "done"
}

# 参数格式："http:perma 8080/tcp"
# 参数说明：每个服务或端口用空格分隔，后可跟 perma 表示添加持久性规则
config_firewall() {
	pinfo "start to config firewall"
	systemctl --quiet is-active firewalld
	if [[ $? -ne 0 ]]; then
		pinfo "firewalld service not started, skip the firewall configuration"
		return
	fi
	for i in $1; do
		local perma=${i##*:}
                i=${i%%:*}
		case $i in
		*/*)
			pinfo "add $i port to the firewall"
			eval firewall-cmd --zone=public --add-port=$i ${noout_str}
			[[ $? -ne 0 ]] && perror "failed to add $i port to the firewall" && quit
			pinfo "done"
			[[ "${perma}" == "perma" ]] && pinfo "add $i port to the firewall permanently" && eval firewall-cmd --zone=public --permanent --add-port=$i ${noout_str}
			[[ $? -ne 0 ]] && perror "failed to add $i port to the firewall permanently" && quit
			pinfo "done"
			;;
		*)
			pinfo "add $i service to the firewall"
			eval firewall-cmd --zone=public --add-service=$i ${noout_str}
			[[ $? -ne 0 ]] && perror "failed to add $i service to the firewall" && quit
			pinfo "done"
			[[ "${perma}" == "perma" ]] && pinfo "add $i service to the firewall permanently" && eval firewall-cmd --zone=public --permanent --add-service=$i ${noout_str}
			[[ $? -ne 0 ]] && perror "failed to add $i service to the firewall permanently" && quit
			pinfo "done"
			;;
		esac
	done
	pinfo "done"
}

config_selinux() {
	selinuxenabled
	if [[ $? == 0 ]]; then
		pinfo "start to set selinux"
		setsebool -P httpd_can_network_connect 1
		pinfo "done"
	fi
}
# ------- 配置模块 -------

# ------- 服务模块 -------
# 启动服务
# 参数格式："service1 service2:enable service3"
# 参数说明：每个服务用空格分隔，服务后可跟 enable 表示设置开机自启
service_startxxx() {
	for i in $1; do
		local enabled=${i##*:}
		i=${i%%:*}
		systemctl --quiet is-active $i
		if [[ $? -eq 0 ]]; then
			pinfo "$i service has been started"
			if [[ "${enabled}" == "enable" ]]; then
				pinfo "enable $i service"
				eval systemctl enable $i ${noout_str}
			fi
			continue
		fi
		pinfo "start $i service"
		eval systemctl start $i ${tolog_str}
		# 等待服务启动完成
		sleep 5
		systemctl --quiet is-active $i
		if [[ $? -ne 0 ]]; then
			perror "failed to start $i service"
			quit
		fi
		if [[ "${enabled}" == "enable" ]]; then
			pinfo "enable $i service"
			eval systemctl enable $i ${noout_str}
		fi
		pinfo "done"
	done
}

# 停止服务
# 参数格式："service1 service2:disable service3"
# 参数说明：每个服务用空格分隔，服务后可跟 disable 表示取消开机自启
service_stopxxx() {
        for i in $1; do
		local disabled=${i##*:}
                i=${i%%:*}
                systemctl --quiet is-active $i
                if [[ $? -ne 0 ]]; then
                        pinfo "$i service has been stopped"
               		if [[ "${disabled}" == "disable" ]]; then
               		        pinfo "disable $i service"
               		        eval systemctl disable $i ${noout_str}
               		fi
                        continue
                fi
                pinfo "stop $i service"
                eval systemctl stop $i ${tolog_str}
		sleep 5
                systemctl --quiet is-active $i
                if [[ $? -eq 0 ]]; then
                        perror "failed to stop $i service"
                        quit
                fi
                if [[ "${disabled}" == "disable" ]]; then
                        pinfo "disable $i service"
                        eval systemctl disable $i ${noout_str}
                fi
		pinfo "done"
        done
}
# ------- 服务模块 -------

# ------- 参数解析 -------
if [ ! $1 ];then
	read -p "usage: $0 <1.install | 2.update | 3.uninstall> " num
else
	num=$1
fi

case $num in
1|"install")
	warn_action "Make sure that the [xxx.conf.in] or [${conf_dir}/${conf_filename}] file is configured correctly before starting operation !!!"
	pinfo "start to install xxx ..."
	pinfo "the log file is located in ${log_file}"
	check_config

	install_createrepo
	create_repo
	install_xxx "nginx redis java-1.8.0-openjdk mysql-community-server"
	config_mysql

	install_xxx "xxx"
	config_xxx

	service_startxxx "nginx:enable redis:enable xxx:enable"
	config_firewall "http:perma 8080/tcp:perma"
	config_selinux

	after_install

	pinfo "xxx successfully installed"
	;;
2|"update")
	warn_action "Make sure that the [${conf_dir}/${conf_filename}] file is configured correctly before starting operation !!!"
	pinfo "start to update xxx ..."
	pinfo "the log file is located in ${log_file}"
	check_config

	create_repo update
	service_stopxxx "nginx redis xxx"
	install_xxx "xxx" update
	config_xxx
	service_startxxx "nginx redis xxx"
	
	after_update

	pinfo "xxx successfully updated"
	;;
3|"uninstall")
	pinfo "start to uninstall xxx ..."
	pinfo "the log file is located in ${log_file}"

	service_stopxxx "nginx:disable redis:disable xxx:disable"
	uninstall_xxx "xxx"

	pinfo "xxx successfully uninstalled"
	;;
*)
	perror "unrecognized arguments: $num"
	quit
	;;
esac
# ------- 参数解析 -------
