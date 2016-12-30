#!/bin/bash

puppet_check()
{
  PUPPET_FULL_VERSION=$(puppet --version 2>/dev/null)

  if [ "$?" -ne 0 ];
  then
    echo "unexpected puppet error"
  fi

  PUPPET_MAJOR_VERSION=$(puppet --version | grep -Eo "^[0-9]")

  if [ "$PUPPET_MAJOR_VERSION" -lt "3" ];
  then
    echo "please install at least 3.8"
    exit 1
  fi

  PUPPET_MINOR_VERSION=$(puppet --version | grep -Eo "\.[0-9]*\." | cut -f2 -d.)

  if [ "$PUPPET_MINOR_VERSION" -lt "8" ];
  then
    echo "please install at least 3.8"
    exit 1
  fi
}


while getopts 'd:hp' OPT; do
  case $OPT in
    d)  DIR=$OPTARG;;
    h)  JELP="yes";;
    *)  JELP="yes";;
  esac
done

shift $(($OPTIND - 1))

# usage
HELP="
    usage: $0 -d <localpuppetmaster dir> <tar to install>
    syntax:
            -d --> puppetmaster directory
            -h --> print this help screen
"

if [ "$JELP" = "yes" ]; then
  echo "$HELP"
  exit 1
fi

puppet_check

if [ ! -e $1 ];
then
  echo "file not found"
  echo "$HELP"
  exit 1
fi
