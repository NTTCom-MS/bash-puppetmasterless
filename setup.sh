#!/bin/bash

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
  elif [ "${FACT_OSFAMILY}" == "Suse" ];
  then
    if [ "${FACT_OPERATINGSYSTEM}" == "SLES" ];
    then
      if [ "${FACT_OPERATINGSYSTEMRELEASE}" == "11.3" ];
      then
        # OLD STUFF
        zypper addrepo -f --no-gpgcheck http://demeter.uni-regensburg.de/SLES11SP3-x86/DVD1/ "SLES11SP3-x64 DVD1 Online"
        zypper addrepo -f --no-gpgcheck http://demeter.uni-regensburg.de/SLE11SP3-SDK-x86/DVD1/ "SUSE-Linux-Enterprise-Software-Development-Kit-11-SP3"
        zypper addrepo -f --no-gpgcheck http://download.opensuse.org/repositories/devel:languages:ruby/SLE_11_SP4/devel:languages:ruby.repo
        zypper --non-interactive refresh
        rpm -Uvh http://download.opensuse.org/repositories/devel:/languages:/misc/SLE_11_SP4/i586/libyaml-0-2-0.1.6-15.1.i586.rpm
        $PKG_INSTALL ruby2.1

        mkdir -p $TMPDIRBASE/usr/local/src
        cd $TMPDIRBASE/usr/local/src
        wget https://rubygems.org/rubygems/rubygems-2.6.4.tgz --no-check-certificate
        tar xzf rubygems-2.6.4.tgz
        cd rubygems-2.6.4/
        ruby.ruby2.1 setup.rb

        gem install json

        cd $TMPDIRBASE/usr/local/src/
        wget https://downloads.puppetlabs.com/puppet/puppet-3.8.3.tar.gz
        wget http://downloads.puppetlabs.com/facter/facter-2.4.1.tar.gz
        wget https://downloads.puppetlabs.com/hiera/hiera-1.3.4.tar.gz
        tar xzf puppet-3.8.3.tar.gz
        tar xzf facter-2.4.1.tar.gz
        tar xzf hiera-1.3.4.tar.gz
        cd facter-2.4.1
        ruby.ruby2.1 install.rb
        cd ../hiera-1.3.4
        ruby.ruby2.1 install.rb
        cd ../puppet-3.8.3
        ruby.ruby2.1 install.rb
      elif [[ "${FACT_OPERATINGSYSTEMRELEASE}" =~ ^12 ]];
      then
        wget https://yum.puppet.com/puppet5/puppet5-release-sles-12.noarch.rpm -O /tmp/puppet5-release-sles-12.noarch.rpm
        rpm -Uvh /tmp/puppet5-release-sles-12.noarch.rpm
        zypper --non-interactive install puppet-agent
      fi
    fi
  fi

  if [ -f /etc/profile.d/puppet-agent.sh ];
  then
    source /etc/profile.d/puppet-agent.sh
  fi

  puppet --version >/dev/null 2>&1

  if [ "$?" -ne 0 ];
  then
    echo "error installing puppet"
    exit 0
  fi

  echo "PUPPET VERSION: $(puppet --version)"

  gem list | grep deep_merge >/dev/null 2>&1

  if [ "$?" -ne 0 ];
  then
    gem install deep_merge
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
