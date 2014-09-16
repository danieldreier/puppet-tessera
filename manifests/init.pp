# == Class: tessera
#
# Full description of class tessera here.
#
# === Parameters
#
# Document parameters here.
#
# [*app_root*]
#  The root directory of the Tessera application
#
# [*repo_url*]
#  Optional url for the project repository
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { tessera:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <eric.zounes@puppetlabs.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class tessera(
  $app_root = undef,
  $repo_url = undef,
  $version = undef,
  $tessera_user = undef,
  $tessera_group = undef,
){

  if $tessera_user == undef {
    fail("Must define \$tessera_user.")
  }
  if $tessera_group == undef {
    fail("Must define \$tessera_group.")
  }
  vcsrepo { $app_root:
    provider => git,
    source   => $repo_url,
    revision => $version,
    user     => $tessera_user,
    group    => $tessera_group,
  }


  python::virtualenv { 'tessera_env':
    cwd      => $app_root,
  }

  python::requirements { "${app_root}/requirements.txt":
    ensure     => $ensure,
    virtualenv => $app_root,
  }

  python::gunicorn { 'tessera':
    ensure     => $ensure,
    virtualenv => $app_root,
    virtualenv => $app_root,
  }
}
