#!/bin/bash

gather_facts()
{
  FACTERBIN=$(which facter 2>/dev/null)
  if [ -z "$FACTERBIN" ] || [ -z "$(facter -p operatingsystemmajrelease 2>/dev/null)" ];
  then
    if [ -e "/etc/redhat-release" ];
    then
      FACT_OSFAMILY="RedHat"

      FACT_OPERATINGSYSTEM="RedHat"

      FACT_OPERATINGSYSTEMRELEASE=$(grep -Eo "[0-9]*\.[0-9]*" /etc/redhat-release)

      FACT_OPERATINGSYSTEMMAJRELEASE=$(grep -Eo "[0-9]*\.[0-9]*" /etc/redhat-release | cut -f1 -d.)

    elif [ -e "/etc/SuSE-release" ];
    then
      FACT_OSFAMILY="Suse"

      FACT_OPERATINGSYSTEM="SLES"

      FACT_OPERATINGSYSTEMRELEASE="$(grep VERSION /etc/SuSE-release | awk '{ print $NF }').$(grep PATCHLEVEL /etc/SuSE-release | awk '{ print $NF }')"

      FACT_OPERATINGSYSTEMMAJRELEASE="$(grep VERSION /etc/SuSE-release | awk '{ print $NF }')"
    elif [ -e "/etc/lsb-release" ];
    then

      FACT_OPERATINGSYSTEM=$(grep DISTRIB_ID /etc/lsb-release | cut -f2 -d=)

      if [ "${FACT_OPERATINGSYSTEM}" == "Ubuntu" ];
      then
        FACT_OSFAMILY="Debian"

        FACT_OPERATINGSYSTEMRELEASE="$(grep DISTRIB_RELEASE /etc/lsb-release | cut -f2 -d=)"

        FACT_OPERATINGSYSTEMMAJRELEASE="$(grep DISTRIB_RELEASE /etc/lsb-release | cut -f2 -d=)"

        FACT_LSBDISTCODENAME="$(grep DISTRIB_CODENAME /etc/lsb-release | cut -f2 -d=)"
      fi

    fi
  else
    FACT_OSFAMILY=$(facter -p osfamily)

    FACT_OPERATINGSYSTEM=$(facter -p operatingsystem)

    FACT_OPERATINGSYSTEMRELEASE=$(facter -p operatingsystemrelease)

    FACT_OPERATINGSYSTEMMAJRELEASE=$(facter -p operatingsystemmajrelease)

    FACT_LSBDISTCODENAME=$(facter -p lsbdistcodename)
  fi
}

prepostinstall_checks()
{
  if [ "${FACT_OSFAMILY}" == "RedHat" ];
  then
    PKG_INSTALL="yum install"
    PKG_INSTALL_UNATTENDED="-y"
    WHICH_PACKAGE="which"
  fi

  if [ "${FACT_OSFAMILY}" == "Debian" ];
  then
    PKG_INSTALL="apt-get install"
    PKG_INSTALL_UNATTENDED="-y"
    WHICH_PACKAGE="debianutils"
    export DEBIAN_FRONTEND=noninteractive

    $PKG_INSTALL update
  fi

  if [ "${FACT_OSFAMILY}" == "Suse" ];
  then
    PKG_INSTALL="zypper --non-interactive install"
    PKG_INSTALL_UNATTENDED=""
    WHICH_PACKAGE="which"
  fi

  $PKG_INSTALL $PKG_INSTALL_UNATTENDED $WHICH_PACKAGE

  GITBIN=$(which git 2>/dev/null)
  if [ -z "$GITBIN" ];
  then
    $PKG_INSTALL $PKG_INSTALL_UNATTENDED git

    GITBIN=$(which git 2>/dev/null)
    if [ -z "$GITBIN" ];
    then
      echo "please, install git"
      exit 1
    fi
  fi

  RUBYBIN=$(which ruby 2>/dev/null)
  if [ -z "$GITBIN" ];
  then
    $PKG_INSTALL $PKG_INSTALL_UNATTENDED git

    RUBYBIN=$(which ruby 2>/dev/null)
    if [ -z "$RUBYBIN" ];
    then
      echo "please, install ruby"
      exit 1
    fi
  fi

  echo "ruby: ${RUBYBIN}"
  echo "git: ${GITBIN}"

}

puppet_install()
{
  if [ "${FACT_OSFAMILY}" == "RedHat" ];
  then
    rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-${FACT_OPERATINGSYSTEMMAJRELEASE}.noarch.rpm
    $PKG_INSTALL $PKG_INSTALL_UNATTENDED puppet-agent
  elif [ "${FACT_OSFAMILY}" == "Debian" ];
  then
    if [ "${FACT_OPERATINGSYSTEMMAJRELEASE}" != "18.04" ];
    then
      wget https://apt.puppetlabs.com/puppet5-release-${FACT_LSBDISTCODENAME}.deb
      dpkg -i puppet5-release-${FACT_LSBDISTCODENAME}.deb
      apt-get update
    fi
    $PKG_INSTALL $PKG_INSTALL_UNATTENDED puppet-agent
  fi

  source /etc/profile.d/puppet-agent.sh

  puppet --version >/dev/null 2>&1

  if [ "$?" -ne 0 ];
  then
    echo "error installing puppet"
    exit 0
  fi

  echo "PUPPET VERSION: $(puppet --version)"

  /opt/puppetlabs/puppet/bin/gem install r10k

  # bug 930 - https://github.com/puppetlabs/r10k/issues/930
  /opt/puppetlabs/puppet/bin/gem  install cri --version 2.15.6
  /opt/puppetlabs/puppet/bin/gem  uninstall cri --version 2.15.7

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
    echo "unsupported version, please install at least 3.8"
    exit 1
  fi

  PUPPET_MINOR_VERSION=$(puppet --version | grep -Eo "\.[0-9]*\." | cut -f2 -d.)

  if [ "$PUPPET_MAJOR_VERSION" -eq "3" ] && [ "$PUPPET_MINOR_VERSION" -lt "8" ];
  then
    echo "unsupported version, please install at least 3.8"
    exit 1
  fi
}


gather_facts

prepostinstall_checks

puppet_install

puppet_check

mkdir -p /opt

if [ ! -d "/opt/puppet-masterless/.git" ];
then
  cd "/opt"
  rm -fr puppet-masterless
  git clone https://github.com/jordiprats/puppet-masterless
else
  cd "/opt/puppet-masterless"
  git pull origin master
fi

cd -

if [ ! -f "/etc/profile.d/puppet-masterless.sh" ];
then
  cat <<"EOF" > /etc/profile.d/puppet-masterless.sh
# masterless

if ! echo $PATH | grep -q /opt/puppet-masterless ; then
  export PATH=$PATH:/opt/puppet-masterless
fi
EOF
  . /etc/profile.d/puppet-masterless.sh
fi
