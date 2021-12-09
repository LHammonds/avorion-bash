#!/bin/bash
#############################################################
## Name          : avorion-update.sh
## Version       : 1.0
## Date          : 2021-09-11
## Author        : LHammonds
## Purpose       : Update to latest version.
## Compatibility : Verified on Ubuntu Server 20.04 LTS
## Requirements  : Run as root or the specified low-rights user.
## Run Frequency : As needed or when stoping the server.
## Parameters    : None for standard version, /beta for BETA version.
## Exit Codes    :
##    0 = Success
##    1 = ERROR Running instances detected
######################## CHANGE LOG #########################
## DATE       VER WHO WHAT WAS CHANGED
## ---------- --- --- ---------------------------------------
## 2021-09-11 1.0 LTH Created script.
#############################################################

## Import standard variables and functions. ##
source /etc/avorion.conf
LogFile="${LogDir}/avorion-update.log"
SteamOut="${TempDir}/steam.out"
NoUpdate="already up to date"
UpgradeSuccess="fully installed"
Beta="0"

#######################################
##          PREREQUISITES            ##
#######################################

## Check existence of optional command-line parameter ##
case "$1" in
  --beta|-beta|-b)
    Beta="1"
    ;;
esac

## Abort if any instances are running ##
cd ${GameSaveDir}
for folder in *; do
  if [ -d "${folder}" ]; then
    systemctl is-active --quiet avservice@${folder}
    ReturnCode=$?
    if [ "${ReturnCode}" == "0" ]; then
      printf "`date +%Y-%m-%d_%H:%M:%S` [ERROR] ${folder} instance is running. Update aborted.\n" | tee -a ${LogFile}
      exit 1
    fi
  fi
done

#######################################
##           MAIN PROGRAM            ##
#######################################

if [ -f ${SteamOut} ]; then
  ## Remove the temp file before we use it ##
  rm ${SteamOut}
fi
printf "`date +%Y-%m-%d_%H:%M:%S` - Started update.\n" | tee -a ${LogFile}
## Get the pre-update game version. ##
PreUpdateVersion=`${GameRootDir}/bin/AvorionServer --version`
if [ "${Beta}" == "1" ]; then
  ## Install BETA version ##
  printf "[INFO] Beta option enabled.\n" | tee -a ${LogFile}
  f_verbose "su --command='steamcmd +login anonymous +force_install_dir ${GameRootDir} +app_update ${ServerID} -beta beta validate +exit' ${GameUser}"
  su --command="steamcmd +login anonymous +force_install_dir ${GameRootDir} +app_update ${ServerID} -beta beta validate +exit > ${SteamOut}" ${GameUser}
  ReturnCode=$?
else
  ## Install Standard version ##
  f_verbose "su --command='steamcmd +login anonymous +force_install_dir ${GameRootDir} +app_update ${ServerID} validate +exit' ${GameUser}"
  su --command="steamcmd +login anonymous +force_install_dir ${GameRootDir} +app_update ${ServerID} validate +exit > ${SteamOut}" ${GameUser}
  ReturnCode=$?
fi
f_verbose "[INFO] SteamCMD ReturnCode=${ReturnCode}"
if grep -Fq "${NoUpdate}" ${SteamOut}; then
  ## No update found ##
  printf "[INFO] No update found.\n" | tee -a ${LogFile}
else
  if grep -Fq "${UpgradeSuccess}" ${SteamOut}; then
    ## Upgrade peformed and was successful ##
    printf "[INFO] Update performed and was successful.\n" | tee -a ${LogFile}
  else
    ## Other issue (could be error, lack of space, timeout, etc.) ##
    printf "[UNKNOWN] Unknown result...need exact wording.\n" | tee -a ${LogFile}
    printf "[SAVE] Output text saved to ${BackupDir}/`date +%Y-%m-%d_%H-%M-%S`-steam.out\n" | tee -a ${LogFile}
    cp ${SteamOut} ${BackupDir}/`date +%Y-%m-%d_%H-%M-%S`-steam.out
  fi
fi
## Get the post-update game version. ##
PostUpdateVersion=`${GameRootDir}/bin/AvorionServer --version`
printf "[INFO] Old version: ${PreUpdateVersion}\n" | tee -a ${LogFile}
printf "[INFO] New version: ${PostUpdateVersion}\n" | tee -a ${LogFile}
printf "`date +%Y-%m-%d_%H:%M:%S` - Completed update.\n" | tee -a ${LogFile}
exit ${ReturnCode}
