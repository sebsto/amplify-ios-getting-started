#!/bin/sh 
set -e 
set -o pipefail

. code/ci_actions/00_common.sh

# delete build secrets 
echo "Delete certificates directory"
rm -rf ~/certificates 

KEYCHAIN_NAME=dev.keychain
if [ -f $HOME/Library/Keychains/"${KEYCHAIN_NAME}"-db ]; then
    echo "Deleting old ${KEYCHAIN_NAME} keychain"
    security delete-keychain "${KEYCHAIN_NAME}"
fi

# no need to delete the system keychain
# it only contains the Apple WWDR public certificate
