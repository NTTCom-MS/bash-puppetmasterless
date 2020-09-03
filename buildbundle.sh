#!/bin/bash

if [ -z "$1" ];
then
  echo "Usage:"
  echo "  $0 <TGZ>"
  exit 1
fi

if [ -z "$2" ];
then
  BUNDLEFILE="bundle.sh"
else
  BUNDLEFILE="$2"
fi


SEDBIN=$(which gsed 2>/dev/null)
if [ -z "$SEDBIN" ];
then
  if [[ "$(uname -s)" == "Darwin" ]];
  then
    echo "install gsed"
    exit 1
  fi

  SEDBIN=$(which sed 2>/dev/null)
  if [ -z "$SEDBIN" ];
  then
    echo "sed is required"
    exit 1
  fi
fi


#
# build package
#

base64 $1 > .bundle.tmp
cat localpuppetmaster.sh .bundle.tmp > $BUNDLEFILE
sed 's/^BUNDLE_MODE=0$/BUNDLE_MODE=1/' -i $BUNDLEFILE
chmod +x $BUNDLEFILE

if [ -f ".bundle.tmp" ] && [ -f "$BUNDLEFILE" ];
then
  exit 0
else
  echo "ERROR - check output files"
  exit 1
fi