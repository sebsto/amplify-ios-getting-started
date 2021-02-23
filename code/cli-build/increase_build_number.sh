#!/bin/sh -x

# https://rderik.com/blog/automating-build-and-testflight-upload-for-simple-ios-apps/ 

USAGE="Usage:\n${0##*/} --path=PATH [--interactive|-i] [--build=SPECIFIC_BUILD] [--dry-run]"
arguments=""
echo $@
for i in "$@"
do
  case $i in
    --help)
      printf "${USAGE}\n"
      exit
      ;;
    -i|--interactive)
      INTERACTIVE=1
      shift # past argument with no value
      ;;
    --build=*)
      SPECIFIC_BUILD="${i#*=}"
      shift # past argument=value
      ;;
    --path=*)
      WORKDIR="${i#*=}"
      #WORKDIR=$(printf %q "${UWORKDIR}")
      shift # past argument=value
      ;;
    --debug)
      DEBUG=1
      shift # past argument with no value
      ;;
    --dry-run)
      DRY=1
      shift # past argument with no value
      ;;
    *)
      # unknown option
      ;;
  esac
done
if [ -z "${WORKDIR}" ] ; then
  printf "ERROR: Missing path.\n\n${USAGE}\n"
  exit 1
fi
if [ ! -z "${DEBUG}" ] ; then
  echo "INTERACTIVE = ${INTERACTIVE}"
  echo "SPECIFIC_BUILD = ${SPECIFIC_BUILD}"
fi

function _execute(){
if [ ! -z "${DRY}" ] ; then
  echo "DRY COMMAND: ${@}"
else
  eval "$@"
fi
}


find "$WORKDIR" -name "Info.plist" -print0 |
while IFS= read -r -d '' file; do

  value=`plutil -extract CFBundleVersion xml1 -o - "$file"`
  build=`echo ${value} | xmllint --xpath "//string/text()" -`

  re='^[0-9]+$'
  if [[ $build =~ $re ]] ; then
    if [ ! -z "${SPECIFIC_BUILD}" ] ; then
      new_build=$SPECIFIC_BUILD
    else
      new_build=$((build + 1))
    fi
    echo "> current: ${build} new: ${new_build}"
    if [ ! -z "${INTERACTIVE}" ] ; then
      while true; do
        read -p "Update File: ${file} - from build:${build} to: ${new_build}? [y|n|stop] " answer
        case ${answer:0:1} in
          Y|y ) _execute "plutil -replace CFBundleVersion -string \"${new_build}\" \"${file}\"" ; break;;
          N|n ) break;;
          S|s ) exit;;
          * ) echo "Please answer yes or no.";;
        esac
      done
    else
      _execute "plutil -replace CFBundleVersion -string \"${new_build}\" \"${file}\""
      echo "Updated File: ${file} - from build:${build} to: ${new_build}" 
    fi
  fi
done
