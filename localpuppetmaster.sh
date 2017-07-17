#!/bin/bash

forge_install()
{
  $PUPPETBIN module --modulepath=$DIR/modules uninstall $1
  $PUPPETBIN module --modulepath=$DIR/modules install $1
}

tarball_install()
{
  tar xzf $1 -C $DIR/pkg

  if [ $? -ne 0 ];
  then
    echo "error uncompressing modules"
    exit 1
  fi

  if [ -z "$2" ];
  then
    find $DIR/pkg -name \*tar\.gz -exec $PUPPETBIN module --modulepath=$DIR/modules install {} \;
  else
    if [ ! -z "$(find $DIR/pkg -name $2\*)" ];
    then
      $PUPPETBIN module --modulepath=$DIR/modules uninstall $2
      find $DIR/pkg -name $2\* -exec $PUPPETBIN module --modulepath=$DIR/modules install {} \;
    else
      echo "module not found - aborting"
      exit 1
    fi
  fi
}

puppet_check()
{
  PUPPETBIN=$(which puppet)

  if [ -z "$PUPPETBIN" ];
  then
    if [ -e "/opt/puppetlabs/bin/puppet" ];
    then
      PUPPETBIN='/opt/puppetlabs/bin/puppet'
    else
      echo "puppet not found"
      exit 1
    fi
  fi
}

puppet_version_check()
{
  PUPPET_FULL_VERSION=$($PUPPETBIN --version 2>/dev/null)

  if [ "$?" -ne 0 ];
  then
    echo "unexpected puppet error"
  fi

  PUPPET_MAJOR_VERSION=$($PUPPETBIN --version | grep -Eo "^[0-9]")

  if [ "$PUPPET_MAJOR_VERSION" -lt "3" ];
  then
    echo "please install at least 3.8"
    exit 1
  fi

  PUPPET_MINOR_VERSION=$($PUPPETBIN --version | grep -Eo "\.[0-9]*\." | cut -f2 -d.)

  if [ "$PUPPET_MINOR_VERSION" -lt "8" ];
  then
    echo "please install at least 3.8"
    exit 1
  fi
}

while getopts 's:d:y:hlp' OPT; do
  case $OPT in
    d)  DIR=$OPTARG;;
    s)  SITEPP=$OPTARG;;
    y)  HIERAYAML=$OPTARG;;
    l)  MODULELIST=1;;
    h)  JELP="yes";;
    *)  JELP="yes";;
  esac
done

if [ ! -z "$HIERAYAML" ];
then
	HIERAYAML_OPT="--hiera_config $HIERAYAML"
fi

shift $(($OPTIND - 1))

# usage
HELP="
    usage: $0 -d <localpuppetmaster dir> [-s site.pp] [-y hiera.yaml] [<tar to install> [module to install]|<module to install from puppetforge>]
    syntax:
            -d : puppetmaster directory
            -s : site.pp to apply
            -y : hiera.yaml
            -h : print this help screen
"

if [ "$JELP" = "yes" ]; then
  echo "$HELP"
  exit 1
fi

if [ -z "$1" ];
then
  APPLY_ONLY=1
else
  APPLY_ONLY=0
  if [ -f $1 ];
  then
    INSTALL_FROM_FORGE=0
  else
    echo $1 | grep -Eo '[a-zA-Z0-9]+-[a-zA-Z0-9]+'
    if [ "$?" -eq 0 ];
    then
      INSTALL_FROM_FORGE=1
    else
      echo "neither a valid puppet module nor a tarball not found"
      echo "$HELP"
      exit 1
    fi
  fi
fi

if [ -z "$DIR" ];
then
  echo "localpuppetmaster dir not defined"
  echo "$HELP"
  exit 1
fi

puppet_check

puppet_version_check

mkdir -p $DIR/pkg
mkdir -p $DIR/modules

if [ ! -z "$HIERAYAML" ];
then
  if [ ! -e $HIERAYAML ];
  then
    echo "$HIERAYAML does not exists"
    exit 1
  fi
  HIERA_PUPPET_OPT=" --hiera_config $HIERAYAML "
fi

if [ "$MODULELIST" == "1" ];
then
  $PUPPETBIN module --modulepath=$DIR/modules list
  exit $?
fi

if [ "$APPLY_ONLY" -eq 0 ];
then
  if [ "$INSTALL_FROM_FORGE" -eq 0 ];
  then
    tarball_install $@
  else
    forge_install $@
  fi
fi

if [ ! -z "$SITEPP" ];
then
  $PUPPETBIN apply --modulepath=$DIR/modules --pluginsync $SITEPP $HIERAYAML_OPT 2>&1
fi
