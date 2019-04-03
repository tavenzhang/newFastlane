#!/bin/sh
scriptPath=$(cd `dirname $0`; pwd)
#工程根目录 需要替换成自己本机的工程根目录
workRoot=${scriptPath}/work 
#ios工程目录
iosRoot=${workRoot}/ios

androidRoot=${workRoot}/android
#scriptPath=$(cd `dirname $0`; pwd)
#产品输出目录
outPutDir=${scriptPath}/out
#工程名
targetName="JD"
#时间
buildTime=`date "+%Y%m%d"`

configDir=${scriptPath}/BBL_Game_Config
deployDir="/Volumes/jxshare/deploy/game/release"
outputApkDir=${androidRoot}/app/build/outputs/apk/taven/release
#更新config文件
cd ${configDir}
git checkout develop
if [ $? -eq 0 ];then
   echo checkout config develop 分支切换成功
  else
    echo checkout config develop 分支切换成功分支不存在 
    exit -1;
 fi
git pull 


appBranch=($@)

if [ "$@" = "all" ]; then
  appBranch=(uat 365)
fi  
#allAppBranch=($@)
for app in ${appBranch[@]}
do
   apkName=${app}_release.apk
   echo ipa = ${app} release/${app} 
   cd ${workRoot} 
   git fetch
   git checkout  release/${app} 
   git pull 
     #如果输入分支不存在 退出报错
   if [ $? -eq 0 ];then
      echo  release/${app}  分支切换成功 ${workRoot}
     else
      echo  release/${app}  分支不存在 ${workRoot}
   exit -1;
   fi
  # git merge  app/develop -m 'app/develop'
   git merge -Xtheirs app/develop -m 'autoMerge release'
   if [ $? -eq 0 ];then
    echo ${app} merge成功
   else
    echo ${app} merge 失败 
    exit -1;
   fi
   sh JDInit
  
      #第0步判断 对应的config 分支是否存在 避免命令不一致的情况，早点发现
   #  if [ -d ${configDir}/${app}/ios ]; then
   #    echo 开始拷贝和替换 ${configDir}/${app}/ios 文件
   #  else
   #    echo  ${configDir}/${app}/ios 目录不存在
   #    exit -1;
   # fi
   #替换ios资源
  rm -rf ${iosRoot}/JD/Images.xcassets
  cp -rf ${configDir}/game/*   ${androidRoot}/app/src/main/assets/gamelobby/
  cp -rf ${configDir}/${app}/ios/*   ${iosRoot}/JD/
  cp -rf ${configDir}/${app}/android/*   ${androidRoot}/
  cp -rf ${configDir}/${app}/js/* ./src
   #PRODUCT_BUNDLE_IDENTIFIER="com.id.org.${app}"
   if [ $? -eq 0 ];then
      echo ${app} '压缩成功'
   else
     echo '压缩失败'  
     exit -1;
   fi
   #先删除已经存在的
   rm -rf ${outPutDir}/${apkName}
   cd  ${androidRoot}
   #打包
   ./gradlew assembleTavenRelease
  if [ $? -eq 0 ];then	
      echo '打包签名成功'
      cd ${workRoot} 
      #git add -A
       git add ./
       git commit -m 'autoMerge-release and replace config'
      # git push
        @echo ${app} commit===成功
        #上传deployGate
        mv ${outputApkDir}/release.apk    ${outPutDir}/${apkName}
        dg deploy ${outPutDir}/${apkName}
        if [ -d $deployDir ]; then
          mkdir -p $deployDir/${app}
          cp -rf ${outPutDir}/${apkName} $deployDir/${app}/${apkName}
        fi
  else
      echo "打包失败 签名错误" 
      exit -1;
  fi
  echo "ipa包在 ${outPutDir}/${app} 目录下,上传 deploy成功！"
done

