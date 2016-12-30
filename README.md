# localpuppetmaster

## usage

localpuppetmaster.sh -d <localpuppetmaster dir> <tar to install> <site.pp> [module to install]

* **localpuppetmaster dir**: base dir to install puppet modules
* **tar to install**: tar file containing all all the puppet packages:
  ```
  [jprats@croscat localpuppetmaster]$ tar tvf /home/jprats/upload/puppetmoduls.201612301524.tgz
  -rw-r--r-- root/root  21032377 2016-03-20 11:27 eyp-phantomjs-0.1.1.tar.gz
  -rw-r--r-- root/root     11043 2016-12-08 16:32 eyp-multipathd-0.1.5.tar.gz
  -rw-r--r-- root/root     51669 2016-11-25 18:47 eyp-apache-0.4.14.tar.gz
  -rw-r--r-- root/root      8108 2016-10-18 13:41 eyp-audit-0.1.7.tar.gz
  -rw-r--r-- root/root      4690 2016-10-18 13:47 eyp-iptables-0.1.12.tar.gz
  -rw-r--r-- root/root     14837 2016-03-20 11:28 eyp-openldap-0.4.11.tar.gz
  -rw-r--r-- root/root      7673 2016-05-24 17:40 eyp-named-0.2.4.tar.gz
  -rw-r--r-- root/root     13187 2016-03-20 11:28 eyp-mcollective-0.1.36.tar.gz
  -rw-r--r-- root/root     10446 2016-05-31 11:01 eyp-jenkins-0.1.0.tar.gz
  -rw-r--r-- root/root     11906 2016-07-06 10:13 eyp-proftpd-0.2.8.tar.gz
  -rw-r--r-- root/root      4220 2016-03-20 11:28 eyp-varnish-0.1.2.tar.gz
  -rw-r--r-- root/root     10279 2016-12-28 16:22 eyp-tarball-0.1.0.tar.gz
  -rw-r--r-- root/root     31752 2016-10-07 13:26 eyp-postgresql-0.1.36.tar.gz
  -rw-r--r-- root/root      4756 2016-03-20 11:29 eyp-hari-0.1.9.tar.gz
  -rw-r--r-- root/root      2908 2016-03-20 11:29 eyp-locale-0.1.0.tar.gz
  (...)
  ```
* **site.pp**: file to apply, for example:
  ```
  [jprats@croscat localpuppetmaster]$ cat ~/bash.pp
  class { 'bash':
  }
  ```
* **module to install**: optional, module to install instead of installing every single file in the tar file. If it is already installed, it will uninstall it first and reinstall it using the provided version (beaware of dependencies!)

## example

```
[jprats@croscat localpuppetmaster]$ sudo bash localpuppetmaster.sh -d /tmp/localpuppetmaster /home/jprats/upload/puppetmoduls.201612301524.tgz ~/bash.pp eyp-bash
Notice: Preparing to uninstall 'eyp-bash' ...
Removed 'eyp-bash' (v0.1.10) from /tmp/localpuppetmaster/modules
Notice: Preparing to install into /tmp/localpuppetmaster/modules ...
Notice: Downloading from https://forgeapi.puppetlabs.com ...
Notice: Installing -- do not interrupt ...
/tmp/localpuppetmaster/modules
└─┬ eyp-bash (v0.1.10)
  ├── puppetlabs-concat (v2.2.0)
  └── puppetlabs-stdlib (v4.14.0)
Notice: Compiled catalog for croscat.atlasit.local in environment env in 1.27 seconds
Notice: Finished catalog run in 0.55 seconds
[jprats@croscat localpuppetmaster]$

```
