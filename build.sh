#!/bin/sh
vers=$(git tag -l | tail -1)
chmod +x xxx-setup.sh
case "$1" in
	"install")
		dir=xxx-setup-install-${vers}
		tar_name=${dir}.tar
		tar -czf xxxinstallrepo.tar.gz xxxinstallrepo
		[[ -d ${dir} ]] && rm -r ${dir}
		mkdir ${dir}
		cp -a xxx.conf.in xxx-setup.sh ${dir}
		mv xxxinstallrepo.tar.gz ${dir}
		tar -cf ${tar_name} ${dir}
		rm -r ${dir}
		;;
	"update")
		dir=xxx-setup-update-${vers}
		tar_name=${dir}.tar
		tar -czf xxxupdaterepo.tar.gz xxxupdaterepo
		[[ -d ${dir} ]] && rm -r ${dir}
		mkdir ${dir}
		cp -a xxx.conf.in xxx-setup.sh ${dir}
		mv xxxupdaterepo.tar.gz ${dir}
		tar -cf ${tar_name} ${dir}
		rm -r ${dir}
		;;
	*)
		echo "install or update ?"
		exit 1
		;;
esac
