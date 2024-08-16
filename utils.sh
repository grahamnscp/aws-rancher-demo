#!/usr/bin/env bash

# Logging Functions
# =================

Log ()
{
  if $verbose; then
    local timestamp
    timestamp=$(date '+%Y-%m-%d %T')
    echo "[${IYel}$timestamp ${RCol}INFO] $1"
  fi
}

LogStarted ()
{
  local timestamp
  timestamp=$(date '+%Y-%m-%d %T')
  echo "[${IGre}$timestamp ${BIGre}STARTED${RCol}] ${BIGre}$1${RCol}"
}

LogImportant ()
{
  local timestamp
  timestamp=$(date '+%Y-%m-%d %T')
  echo "[${IYel}$timestamp${RCol} ${Cya}IMPORTANT${RCol}] ${Cya}$1${RCol}"
}

LogWarning ()
{
  local timestamp
  timestamp=$(date '+%Y-%m-%d %T')
  echo "[${IYel}$timestamp ${Yel}WARNING${RCol}] ${Yel}$1${RCol}"
}

LogSuccess ()
{
  local timestamp
  timestamp=$(date '+%Y-%m-%d %T')
  echo "[${IYel}$timestamp ${BIBlu}SUCCESS${RCol}] ${BIWhi}$1${RCol}"
}

LogDuration ()
{
  local timestamp
  timestamp=$(date '+%Y-%m-%d %T')
  echo "[${IYel}$timestamp ${Yel}DURATION${RCol}] ${Yel}$1${RCol}"
}

LogCompleted ()
{
  local timestamp
  timestamp=$(date '+%Y-%m-%d %T')
  echo "[${IGre}$timestamp ${BIGre}COMPLETED${RCol}] ${BIGre}$1${RCol}"
}

LogComplete ()
{
  local timestamp
  timestamp=$(date '+%Y-%m-%d %T')
  echo "[${IGre}$timestamp ${BIGre}COMPLETE${RCol}] ${BIGre}$1${RCol}"
}

LogError ()
{
  local timestamp
  timestamp=$(date '+%Y-%m-%d %T')
  printf '\n%s\n\n' "[${Red}$timestamp${BIRed} ERROR${RCol}] ${Red}$1${RCol}"
  if ! $verbose; then
    echo "Use -v for verbose debug output"
  fi
  exit -1
}

SECONDS=0
function LogElapsedDuration
{
  duration=$SECONDS
  DURATION=`echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."`
  LogDuration "$DURATION"
}

# Colour Definitions
# ==================

# shellscheck disable=SC2034
RCol=$'\e[0m'    # Text Reset

# Regular            Bold                Underline           High Intensity      BoldHigh Intens     Background          High Intensity Backgrounds
# shellcheck disable=SC2034
Bla=$'\e[0;30m'     BBla=$'\e[1;30m'    UBla=$'\e[4;30m'    IBla=$'\e[0;90m'    BIBla=$'\e[1;90m'   On_Bla=$'\e[40m'    On_IBla=$'\e[0;100m' \
Red=$'\e[0;31m'     BRed=$'\e[1;31m'    URed=$'\e[4;31m'    IRed=$'\e[0;91m'    BIRed=$'\e[1;91m'   On_Red=$'\e[41m'    On_IRed=$'\e[0;101m' \
Gre=$'\e[0;32m'     BGre=$'\e[1;32m'    UGre=$'\e[4;32m'    IGre=$'\e[0;92m'    BIGre=$'\e[1;92m'   On_Gre=$'\e[42m'    On_IGre=$'\e[0;102m' \
Yel=$'\e[0;33m'     BYel=$'\e[1;33m'    UYel=$'\e[4;33m'    IYel=$'\e[0;93m'    BIYel=$'\e[1;93m'   On_Yel=$'\e[43m'    On_IYel=$'\e[0;103m' \
Blu=$'\e[0;34m'     BBlu=$'\e[1;34m'    UBlu=$'\e[4;34m'    IBlu=$'\e[0;94m'    BIBlu=$'\e[1;94m'   On_Blu=$'\e[44m'    On_IBlu=$'\e[0;104m' \
Pur=$'\e[0;35m'     BPur=$'\e[1;35m'    UPur=$'\e[4;35m'    IPur=$'\e[0;95m'    BIPur=$'\e[1;95m'   On_Pur=$'\e[45m'    On_IPur=$'\e[0;105m' \
Cya=$'\e[0;36m'     BCya=$'\e[1;36m'    UCya=$'\e[4;36m'    ICya=$'\e[0;96m'    BICya=$'\e[1;96m'   On_Cya=$'\e[46m'    On_ICya=$'\e[0;106m' \
Whi=$'\e[0;37m'     BWhi=$'\e[1;37m'    UWhi=$'\e[4;37m'    IWhi=$'\e[0;97m'    BIWhi=$'\e[1;97m'   On_Whi=$'\e[47m'    On_IWhi=$'\e[0;107m'


# Utility Functions
# =================

# Converts a number of seconds into h m s
hms ()
{
  local secs=${1:?}
  (( h = secs / 3600 ))
  (( m = ( secs / 60 ) % 60 ))
  (( s = secs % 60 ))

  if (( h > 0 )); then echo "${h}h ${m}m ${s}s"; return 0; fi
  if (( m > 0 )); then echo "${m}m ${s}s"; return 0; fi
  if (( s > 0 )); then echo "${s}s"; return 0; fi
  echo "0s"
}

# Execute [-s for silent] Command...
logFilename="/tmp/log.txt"
Execute ()
{
  local verbose=$verbose
  if [[ $1 = -s ]]; then
    verbose=false
    shift
  fi
  if $verbose; then
    Log "$*"
    "$@" 2>&1 | tee -a "${logFilename}"
    exitCode=${PIPESTATUS[0]}
  else
    "$@" >> "${logFilename}" 2>&1
    exitCode=${PIPESTATUS[0]}
  fi
  return "$exitCode"
}

ExecuteOrFail ()
{
  Execute "$@"
  exitCode=$?
  if [[ $exitCode -ne 0 ]]; then
    LogError "$*"
  fi
  return 0
}
