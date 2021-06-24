#!/bin/bash

source scripts/envVar.sh

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"

CHANNEL_NAME="zvoting"
CC_NAME="zvoting"
CC_SRC_PATH="$HOME/z-voting/chaincode/"
CC_SRC_LANGUAGE="typescript"
CC_SEQUENCE=1
CC_END_POLICY="AND('Org1MSP.peer','Org2MSP.peer','Org3MSP.peer')"

while [[ $# -ge 1 ]]; do
  key="$1"
  case $key in
  -c)
    CHANNEL_NAME="$2"
    shift
    ;;
  -ccl)
    CC_SRC_LANGUAGE="$2"
    shift
    ;;
  -ccn)
    CC_NAME="$2"
    shift
    ;;
  -ccp)
    CC_SRC_PATH="$2"
    shift
    ;;
  -ccs)
    CC_SEQUENCE="$2"
    shift
    ;;
  -ccep)
    CC_END_POLICY="$2"
    shift
    ;;
  *)
    errorln "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

getSequenceID() {

  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CC_NAME >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt

  CC_SEQUENCE=$(sed -n "/Sequence/{s/^.*Sequence: //; s/, Endorsement.*$//; p;}" log.txt)

  if [ -z "$CC_SEQUENCE" ]; then
    CC_SEQUENCE=1
  else
    CC_SEQUENCE=$(expr $CC_SEQUENCE + 1)
  fi

  CC_VERSION="v$CC_SEQUENCE"
}

pushd $DIR

getSequenceID 1

println "${C_GREEN}Sequence: ${C_YELLOW} $CC_SEQUENCE ${C_RESET}"


./network.sh deployCC -c $CHANNEL_NAME -ccn $CC_NAME -ccv $CC_VERSION -ccs $CC_SEQUENCE -ccp $CC_SRC_PATH -ccl $CC_SRC_LANGUAGE -ccep $CC_END_POLICY

popd
