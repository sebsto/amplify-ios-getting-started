#!/bin/sh

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

echo "Starting at $(date)"
STARTTIME=$(date +%s)

./cli-build/01_keychain-cli.sh
./cli-build/02_prepare_project.sh
./cli-build/03_build-cli.sh
./cli-build/04_unit_tests.sh
./cli-build/04_ui_tests.sh
./cli-build/05_archive-cli.sh

ENDTIME=$(date +%s)
echo "Ended at $(date)"

secs_to_human "$(($ENDTIME - $STARTTIME))"

