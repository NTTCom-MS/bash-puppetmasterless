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
    w)  int_warn=$OPTARG;;
    c)  int_crit=$OPTARG;;
    h)  hlp="yes";;
    *)  hlp="yes";;
  esac
done

# usage
HELP="
    usage: $0 [ -w value -c value -p -h ]
    syntax:
            -d --> puppetmaster directory
            -h --> print this help screen
"

if [ "$hlp" = "yes" ]; then
  echo "$HELP"
  exit 0
fi

