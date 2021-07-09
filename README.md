# xxx 自动化部署脚本
当前的 rpm 文件夹需要压缩后方可在部署时使用

## 版本
使用 `git tag` 获取版本号，每次在部署过程或部署结果上有更新时都需要递增版本号。

## 打包
为了缩小更新包的体积，分为两种压缩包，安装包只在初次安装时需要，后续使用更新包进行更新。

- 安装包：`cd xxx-setup && sh build.sh install`
- 更新包：`cd xxx-setup && sh build.sh update`

## 使用
解开 tar 文件，进入解压后的目录，执行：

- 安装：`./xxx-setup 1`
- 更新：`./xxx-setup 2`
- 卸载：`./xxx-setup 3`
