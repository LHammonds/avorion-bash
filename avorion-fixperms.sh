#!/bin/bash
#############################################################
## Name          : avorion-fixperms.sh
## Version       : 1.0
## Date          : 2021-09-11
## Author        : LHammonds
## Purpose       : Fix ownership/permissions on files/folders.
## Compatibility : Verified on Ubuntu Server 20.04 LTS
## Requirements  : Run as root
## Run Frequency : As needed.
## Parameters    : None
## Exit Codes    :
##    0 = Normal
##    1 = Not run as root
######################## CHANGE LOG #########################
## DATE       VER WHO WHAT WAS CHANGED
## ---------- --- --- ---------------------------------------
## 2021-09-11 1.0 LTH Created script.
#############################################################

## Import standard variables and functions. ##
source /etc/avorion.conf

LogFile="${LogDir}/avorion-fixperms.log"

#######################################
##            FUNCTIONS              ##
#######################################

function f_abort()
{
  printf "`date +%Y-%m-%d_%H:%M:%S` [ABORT] ErrorCode=${1}\n" >> ${LogFile}
  exit ${1}
} ## f_abort()

#######################################
##           MAIN PROGRAM            ##
#######################################
## Requirement Check: Script must run as root user.
if [ "$(id -u)" != "0" ]; then
  ## FATAL ERROR DETECTED: Document problem and terminate script.
  printf "\n[ERROR] Root user required to run this script.\n"
  printf "Type 'sudo $0' to run with root privileges.\n"
  f_abort 1
fi

StartTime="$(date +%s)"

printf "`date +%Y-%m-%d_%H:%M:%S` [INFO] fixperms started.\n" | tee -a ${LogFile}

## Reset ownership on everything ##
f_verbose "`date +%Y-%m-%d_%H:%M:%S` [INFO] Setting ownership."
chown --recursive ${GameUser}:${GameGroup} ${GameRootDir}
chown ${GameUser}:${GameGroup} ${LogDir}/avorion-*.log
chown ${GameUser}:${GameGroup} /etc/avorion.conf

## Set basic permissions for all folders ##
find ${GameRootDir} -type d -exec chmod 0750 {} \;

## Set basic permissions for all files ##
find ${GameRootDir} -type f -exec chmod 0440 {} \;

## Fix savegame permissions ##
find ${GameSaveDir} -type d -exec chmod 0770 {} \;
find ${GameRootDir} -type f -exec chmod 0660 {} \;

## Fix binary execution permissions ##
find ${GameRootDir}/bin -type f -exec chmod 0550 {} \;
find ${GameRootDir}/*.sh -type f -exec chmod 0550 {} \;
find ${GameRootDir}/*.so -type f -exec chmod 0550 {} \;

chmod 0750 ${GameRootDir}/.steam/steamcmd/steamcmd.sh
chmod 0750 ${GameRootDir}/.steam/steamcmd/linux32/steamcmd

chmod 0660 ${LogDir}/avorion-*.log
chmod 0640 /etc/avorion.conf

## Calculate total runtime ##
FinishTime="$(date +%s)"
ElapsedTime="$(expr ${FinishTime} - ${StartTime})"
Hours=$((${ElapsedTime} / 3600))
ElapsedTime=$((${ElapsedTime} - ${Hours} * 3600))
Minutes=$((${ElapsedTime} / 60))
Seconds=$((${ElapsedTime} - ${Minutes} * 60))
printf "  Total runtime: ${Hours} hour(s) ${Minutes} minute(s) ${Seconds} second(s)\n" | tee -a ${LogFile}
printf "`date +%Y-%m-%d_%H:%M:%S` [INFO] fixperms completed.\n" | tee -a ${LogFile}
exit 0
