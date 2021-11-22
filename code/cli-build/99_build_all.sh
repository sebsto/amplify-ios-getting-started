#!/bin/sh

set -e 
set -o pipefail

# https://stackoverflow.com/questions/16908084/bash-script-to-calculate-time-elapsed
secs_to_human() {
    if [[ -z ${1} || ${1} -lt 60 ]] ;then
        min=0 ; secs="${1}"
    else
        time_mins=$(echo "scale=2; ${1}/60" | bc)
        min=$(echo ${time_mins} | cut -d'.' -f1)
        secs="0.$(echo ${time_mins} | cut -d'.' -f2)"
        secs=$(echo ${secs}*60|bc|awk '{print int($1+0.5)}')
    fi
    echo "Time Elapsed : ${min} minutes and ${secs} seconds."
}

STARTTIME=$(date +%s)
BUILD_NUMBER=`date +%Y%m%d%H%M%S`

LOGS=/Users/ec2-user/log/$BUILD_NUMBER.log

echo "Starting build ${BUILD_NUMBER} at $(date)"
echo "Logs are available in ${LOGS}"
echo "Starting build ${BUILD_NUMBER} at $(date)" > $LOGS

# TODO : send build log to CloudWatch

./cli-build/01_keychain_cli.sh >> $LOGS 2>&1
./cli-build/02_prepare_project.sh >> $LOGS 2>&1
./cli-build/03_build_cli.sh >> $LOGS 2>&1
./cli-build/04_unit_tests.sh >> $LOGS 2>&1
./cli-build/05_ui_tests.sh >> $LOGS 2>&1
./cli-build/06_archive_cli.sh >> $LOGS 2>&1

ENDTIME=$(date +%s)
echo "Ended at $(date)"

secs_to_human "$(($ENDTIME - $STARTTIME))"

echo $(date) >> $LOGS
echo $(secs_to_human "$(($ENDTIME - $STARTTIME))") >> $LOGS
echo "---- Build ended ----" >> $LOGS

