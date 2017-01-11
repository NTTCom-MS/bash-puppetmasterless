#!/bin/bash

forge_install()
{
  puppet module --modulepath=$DIR/modules uninstall $1
  puppet module --modulepath=$DIR/modules install $1
}

tarball_install()
{
  tar xzf $1 -C $DIR/pkg

  if [ $? -ne 0 ];
  then
    echo "error uncompressing modules"
    exit 1
  fi

  if [ -z "$3" ];
  then
    find $DIR/pkg -name \*tar\.gz -exec puppet module --modulepath=$DIR/modules install {} \;
  else
    if [ ! -z "$(find $DIR/pkg -name $3\*)" ];
    then
      puppet module --modulepath=$DIR/modules uninstall $3
      find $DIR/pkg -name $3\* -exec puppet module --modulepath=$DIR/modules install {} \;
    else
      echo "module not found - aborting"
      exit 1
    fi
  fi
}

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
    usage: $0 -d <localpuppetmaster dir> [<tar to install>|<module to install from puppetforge>] <site.pp> [module to install]
    syntax:
            -d --> puppetmaster directory
            -h --> print this help screen
"

if [ "$JELP" = "yes" ]; then
  echo "$HELP"
  exit 1
fi

if [ -z "$1" ];
then
  echo "nothing to install"
  echo "$HELP"
  exit 1
fi

if [ -z "$DIR" ];
then
  echo "localpuppetmaster dir not defined"
  echo "$HELP"
  exit 1
fi

if [ ! -e $1 ];
then
  echo $1 | grep -Eo '[a-zA-Z0-9]+-[a-zA-Z0-9]+'
  if [ "$?" -eq 0 ];
  then
    INSTALL_FROM_FORGE=1
  else
    echo "neither a valid puppet module nor a tarball not found"
    echo "$HELP"
    exit 1
  fi
else
  INSTALL_FROM_FORGE=0
fi

if [ ! -e $2 ];
then
  echo "site.pp not found"
  echo "$HELP"
  exit 1
fi

puppet_check

mkdir -p $DIR/pkg
mkdir -p $DIR/modules

if [ "$INSTALL_FROM_FORGE" -eq 0 ];
then
  tarball_install $@
else
  forge_install $@
fi

puppet apply --modulepath=$DIR/modules $2 2>&1
