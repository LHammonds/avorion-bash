#!/bin/bash
#############################################################
## Name          : avorion-start.sh
## Version       : 1.0
## Date          : 2021-09-11
## Author        : LHammonds
## Purpose       : Start a specific game instance.
## Compatibility : Verified on Ubuntu Server 20.04 LTS
## Requirements  : Run as root or the specified low-rights user.
## Run Frequency : As needed or when starting the server.
## Parameters    : Game Instance
## Exit Codes    :
##    0 = Success
##    1 = ERROR Missing parameter
##    2 = ERROR Invalid parameter
##    3 = ERROR Invalid user
##    4 = ERROR Invalid configuration
######################## CHANGE LOG #########################
## DATE       VER WHO WHAT WAS CHANGED
## ---------- --- --- ---------------------------------------
## 2021-09-11 1.0 LTH Created script.
#############################################################

## Import standard variables and functions. ##
source /etc/avorion.conf
LogFile="${LogDir}/avorion-start.log"

#######################################
##            FUNCTIONS              ##
#######################################

function f_start()
{
  ## Parameter #1 = Instance Name
  printf "\n[INFO] systemctl start ${1}\n"
  systemctl start ${1}
} ## f_start() ##

function f_showhelp()
{
  printf "`date +%Y-%m-%d_%H:%M:%S` - [ERROR] Missing required parameter(s)\n" | tee -a ${LogFile}
  printf "Syntax : ${0} {InstanceName}\n"
  printf "Example: ${0} galaxy1\n"
  printf "List of existing game instances\n"
  printf "===============================\n"
  for intIndex in "${!arrInstanceName[@]}"
  do
    ## Verify instance is installed ##
    if [ -f "${GameSaveDir}/${arrInstanceName[${intIndex}]}/server.ini" ]; then
      printf "${arrInstanceName[${intIndex}]}\n"
    fi
  done
} ## f_showhelp() ##

function f_sanity_check()
{
  ## Parameter #1 = Variable name. ##
  ## Parameter #2 = Variable contents. ##
  if [ "${2}" == "" ]; then
    printf "`date +%Y-%m-%d_%H:%M:%S` - [ERROR] ${1} could not be matched.\n" | tee -a ${LogFile}
    exit 4
  fi
} ## f_sanity_check() ##

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

## Get all options based on instance name ##
for intIndex in "${!arrInstanceName[@]}"
do
  if [ "${GameInstance}" == "${arrInstanceName[${intIndex}]}" ]; then
    Desc=${arrDesc[${intIndex}]}
    GamePort=${arrGamePort[${intIndex}]}
    SteamMasterPort=${arrSteamMasterPort[${intIndex}]}
    SteamQueryPort=${arrSteamQueryPort[${intIndex}]}
    QueryPort=${arrQueryPort[${intIndex}]}
    RCONPort=${arrRCONPort[${intIndex}]}
    Seed=${arrSeed[${intIndex}]}
    break
  fi
done

## Sanity check on imported array variables. ##
f_sanity_check "Desc" ${Desc}
f_sanity_check "GamePort" ${GamePort}
f_sanity_check "SteamMasterPort" ${SteamMasterPort}
f_sanity_check "SteamQueryPort" ${SteamQueryPort}
f_sanity_check "QueryPort" ${QueryPort}
f_sanity_check "RCONPort" ${RCONPort}
f_sanity_check "Seed" ${Seed}

## Build command-line parameter list. ##

CommandParameters="--multiplayer true --listed true --galaxy-name ${GameInstance} --admin ${SteamAdmin} --datapath ${GameSaveDir} --server-name '${Desc}' --ip 127.0.0.1 --port ${GamePort} --steam-master-port ${SteamMasterPort} --steam-query-port ${SteamQueryPort} --query-port ${QueryPort} --rcon-port ${RCONPort} --seed ${Seed} --same-start-sector true --max-players ${MaxPlayers}"

#######################################
##           MAIN PROGRAM            ##
#######################################

## Get the current game version. ##
GameVersion=`${GameRootDir}/bin/AvorionServer --version`

if [ "${USER}" == "${GameService}" ]; then
  ## Already running as the low-rights user, start the instance. ##
  printf "`date +%Y-%m-%d_%H:%M:%S` - [INFO] Start ${GameInstance} on version ${GameVersion}\n" >> ${LogFile}
  f_verbose "Command = ${GameRootDir}/server.sh ${CommandParameters}"
  ${GameRootDir}/server.sh ${CommandParameters}
elif [ "${USER}" == "root" ]; then
  ## Run command using low-rights user ##
  printf "`date +%Y-%m-%d_%H:%M:%S` - [INFO] Start ${GameInstance} on version ${GameVersion}\n" >> ${LogFile}
  f_verbose "Command = su --command='${GameRootDir}/server.sh ${CommandParameters}' ${GameService}"
  su --command="${GameRootDir}/server.sh ${CommandParameters}" ${GameService}
else
  ## Exit script with reason and error code ##
  printf "`date +%Y-%m-%d_%H:%M:%S` - [ERROR] ${GameInstance} service must be started by ${GameService}\n" | tee -a ${LogFile}
  exit 3
fi
exit 0
