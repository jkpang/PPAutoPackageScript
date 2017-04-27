# !/bin/bash

#
# ################################################################################
#
# 联系方式 :
# Weibo : jkpang-庞 http://weibo.com/u/5743737098/home?wvr=5&uut=fin&from=reg
# Email : jkpang@outlook.com
# QQ 群 : 323408051
# GitHub: https://github.com/jkpang
#
# ################################################################################
#

# 使用方法:
# step1 : 将PPAutoPackageScript整个文件夹拖入到项目主目录,项目主目录,项目主目录~~~(重要的事情说3遍!😊😊😊)
# step2 : 打开PPAutoPackageScript.sh文件,修改 "项目自定义部分" 配置好项目参数
# step3 : 打开终端, cd到PPAutoPackageScript文件夹 (ps:在终端中先输入cd ,直接拖入PPAutoPackageScript文件夹,回车)
# step4 : 输入 sh PPAutoPackageScript.sh 命令,回车,开始执行此打包脚本

# ===============================项目自定义部分(自定义好下列参数后再执行该脚本)============================= #
# 计时
SECONDS=0
# 是否编译工作空间 (例:若是用Cocopods管理的.xcworkspace项目,赋值true;用Xcode默认创建的.xcodeproj,赋值false)
is_workspace="true"
# 指定项目的scheme名称
# (注意: 因为shell定义变量时,=号两边不能留空格,若scheme_name与info_plist_name有空格,脚本运行会失败,暂时还没有解决方法,知道的还请指教!)
scheme_name="项目的scheme名称"
# 工程中Target对应的配置plist文件名称, Xcode默认的配置文件为Info.plist
info_plist_name="Info"
# 指定要打包编译的方式 : Release,Debug...
build_configuration="Release"


# ===============================自动打包部分(无特殊情况不用修改)============================= #

# 导出ipa所需要的plist文件路径 (默认为AdHocExportOptionsPlist.plist)
ExportOptionsPlistPath="./PPAutoPackageScript/AdHocExportOptionsPlist.plist"
# 返回上一级目录,进入项目工程目录
cd ..
# 获取项目名称
project_name=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`
# 获取版本号,内部版本号,bundleID
InfoPlistPath="$project_name/$info_plist_name.plist"
bundle_version=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $InfoPlistPath`
bundle_build_version=`/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" $InfoPlistPath`
bundle_identifier=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $InfoPlistPath`

# 删除旧.xcarchive文件
rm -rf ~/Desktop/$scheme_name-IPA/$scheme_name.xcarchive
# 指定输出ipa路径
export_path=~/Desktop/$scheme_name-IPA
# 指定输出归档文件地址
export_archive_path="$export_path/$scheme_name.xcarchive"
# 指定输出ipa地址
export_ipa_path="$export_path"
# 指定输出ipa名称 : scheme_name + bundle_version
ipa_name="$scheme_name-v$bundle_version"

# AdHoc,AppStore,Enterprise三种打包方式的区别: http://blog.csdn.net/lwjok2007/article/details/46379945
echo "\033[36;1m请选择打包方式(输入序号,按回车即可) \033[0m"
echo "\033[33;1m 1. AdHoc \033[0m"
echo "\033[33;1m 2. AppStore  \033[0m"
echo "\033[33;1m 3. Enterprise \033[0m"
# 读取用户输入并存到变量里
read parameter
sleep 0.5
method="$parameter"

# 判读用户是否有输入
if [ -n "$method" ]
then
    if [ "$method" = "1" ] ; then
    ExportOptionsPlistPath="./PPAutoPackageScript/AdHocExportOptionsPlist.plist"
    elif [ "$method" = "2" ] ; then
    ExportOptionsPlistPath="./PPAutoPackageScript/AppStoreExportOptionsPlist.plist"
    elif [ "$method" = "3" ] ; then
    ExportOptionsPlistPath="./PPAutoPackageScript/EnterpriseExportOptionsPlist.plist"
    else
    echo "输入的参数无效!!!"
    exit 1
    fi
fi

echo "**************************开始编译代码...*********************************"
# 指定输出文件目录不存在则创建
if [ -d "$export_path" ] ; then
echo $export_path
else
mkdir -pv $export_path
fi

# 判断编译的项目类型是workspace还是project
if $is_workspace ; then
# 编译前清理工程
xcodebuild clean -workspace ${project_name}.xcworkspace \
                 -scheme ${scheme_name} \
                 -configuration ${build_configuration}

xcodebuild archive -workspace ${project_name}.xcworkspace \
                   -scheme ${scheme_name} \
                   -configuration ${build_configuration} \
                   -archivePath ${export_archive_path}
else
# 编译前清理工程
xcodebuild clean -project ${project_name}.xcodeproj \
                 -scheme ${scheme_name} \
                 -configuration ${build_configuration}

xcodebuild archive -project ${project_name}.xcodeproj \
                   -scheme ${scheme_name} \
                   -configuration ${build_configuration} \
                   -archivePath ${export_archive_path}
fi

#  检查是否构建成功
#  xcarchive 实际是一个文件夹不是一个文件所以使用 -d 判断
if [ -d "$export_archive_path" ] ; then
echo "\033[32;1m项目构建成功 🚀 🚀 🚀  \033[0m"
else
echo "\033[31;1m项目构建失败 😢 😢 😢  \033[0m"
exit 1
fi

echo "**************************开始导出ipa文件....*********************************"
xcodebuild  -exportArchive \
            -archivePath ${export_archive_path} \
            -exportPath ${export_ipa_path} \
            -exportOptionsPlist ${ExportOptionsPlistPath}
# 修改ipa文件名称
mv $export_ipa_path/$scheme_name.ipa $export_ipa_path/$ipa_name.ipa

# 检查文件是否存在
if [ -f "$export_ipa_path/$ipa_name.ipa" ] ; then
echo "\033[32;1m导出 ${ipa_name}.ipa 包成功 🎉  🎉  🎉  \033[0m"
open $export_path
else
echo "\033[31;1m导出 ${ipa_name}.ipa 包失败 😢 😢 😢  \033[0m"
# 相关的解决方法
echo "\033[34mps:以下类型的错误可以参考对应的链接\033[0m"
echo "\033[34m  1.\"error: exportArchive: No applicable devices found.\" --> 可能是ruby版本过低导致,升级最新版ruby再试,升级方法自行百度/谷歌,GitHub issue: https://github.com/jkpang/PPAutoPackageScript/issues/1#issuecomment-297589697"
echo "\033[34m  2.\"No valid iOS Distribution signing identities belonging to team 6F4Q87T7VD were found.\" --> http://fight4j.github.io/2016/11/21/xcodebuild/ \033[0m"
exit 1
fi
# 输出打包总用时
echo "\033[36;1m使用PPAutoPackageScript打包总用时: ${SECONDS}s \033[0m"


