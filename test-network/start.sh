#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

CHANNEL_NAME="zvoting"
CC_NAME="zvoting"
CC_SRC_PATH="$HOME/z-voting/chaincode/"
CC_SRC_LANGUAGE="typescript"
CC_END_POLICY="AND('Org1MSP.peer','Org2MSP.peer','Org3MSP.peer')"

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ccl )
    CC_SRC_LANGUAGE="$2"
    shift
    ;;
  -ccn )
    CC_NAME="$2"
    shift
    ;;
  -ccp )
    CC_SRC_PATH="$2"
    shift
    ;;
  -ccep )
    CC_END_POLICY="$2"
    shift
    ;;
  * )
    errorln "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

pushd $DIR

pushd $DIR/addOrg3
./addOrg3.sh down
popd

./network.sh up createChannel -ca -s couchdb -c $CHANNEL_NAME

pushd $DIR/addOrg3
./addOrg3.sh up -ca -s couchdb -c $CHANNEL_NAME
popd

./network.sh deployCC -c $CHANNEL_NAME -ccn $CC_NAME -ccp $CC_SRC_PATH -ccl $CC_SRC_LANGUAGE -ccep $CC_END_POLICY

popd
