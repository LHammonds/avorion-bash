#!/bin/bash
#############################################################
## Name          : avorion-stop.sh
## Version       : 1.0
## Date          : 2021-09-11
## Author        : LHammonds
## Purpose       : Stop a specific game instance.
## Compatibility : Verified on Ubuntu Server 20.04 LTS
## Requirements  : Run as root or the specified low-rights user.
## Run Frequency : As needed or when stoping the server.
## Parameters    : Game Instance
## Exit Codes    :
##    0 = Success
##    1 = ERROR Missing parameter
##    2 = ERROR Invalid parameter
######################## CHANGE LOG #########################
## DATE       VER WHO WHAT WAS CHANGED
## ---------- --- --- ---------------------------------------
## 2021-09-11 1.0 LTH Created script.
#############################################################

## Import standard variables and functions. ##
source /etc/avorion.conf
LogFile="${LogDir}/avorion-stop.log"

#######################################
##            FUNCTIONS              ##
#######################################

function f_showhelp()
{
  printf "`date +%Y-%m-%d_%H:%M:%S` - [ERROR] Missing required parameter(s)\n" | tee -a ${LogFile}
  printf "Syntax : ${0} {InstanceName}\n"
  printf "Example: ${0} galaxy1\n"
  printf "List of existing game instances\n"
  printf "===============================\n"
  ls ${GameSaveDir}
}

#######################################
##          PREREQUISITES            ##
#######################################

## Check existence of required command-line parameters ##
case "$1" in
  "")
    f_showhelp
    exit 1
    ;;
  --help|-h|-?)
    f_showhelp
    exit 1
    ;;
  *)
    GameInstance=$1
    ;;
esac

## Validate GameInstance ##
if [ ! -f "${GameSaveDir}/${GameInstance}/server.ini" ]; then
  printf "`date +%Y-%m-%d_%H:%M:%S` - [ERROR] Invalid parameter. ${GameSaveDir}/${GameInstance} is not a valid instance.\n" | tee -a ${LogFile}
  exit 2
fi

#######################################
##           MAIN PROGRAM            ##
#######################################

## Get the current game version. ##
GameVersion=`${GameRootDir}/bin/AvorionServer --version`

printf "`date +%Y-%m-%d_%H:%M:%S` - Stopping ${GameInstance} on version ${GameVersion}\n" >> ${LogFile}
printf "[INFO] /save ${GameInstance}\n" >> ${LogFile}
${ScriptDir}/rcon -f ${RCONPrefix}${GameInstance}${RCONSuffix} "/save"
sleep 5
printf "[INFO] /stop ${GameInstance}\n" >> ${LogFile}
${ScriptDir}/rcon -f ${RCONPrefix}${GameInstance}${RCONSuffix} "/stop"
printf "`date +%Y-%m-%d_%H:%M:%S` - Stopped ${GameInstance}\n" >> ${LogFile}
exit 0
