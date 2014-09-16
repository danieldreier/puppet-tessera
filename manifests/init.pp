# == Class: tessera
#
# This module deploys Tessera (an attractive front-end for Graphite) from it's git repo.
# It sets up the virtualenv, installs the project requirements, and sets up gunicorn to
# serve the application.
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
# [*version*]
#  Specify the version of the application. This is currently used to reference a git tag.
#
# === Examples
#
#  class { 'tessera':
#    app_root => '/opt/tessera',
#    repo_url => 'git://github.com/urbanairship/tessera.git'
#    version  => 'v0.4.4',
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
    cwd     => $app_root,
    require =>  Vcsrepo[$app_root],
  }

  python::requirements { "${app_root}/requirements.txt":
    ensure     => $ensure,
    virtualenv => $app_root,
    require =>  Vcsrepo[$app_root],
  }

  python::gunicorn { 'tessera':
    ensure     => $ensure,
    virtualenv => $app_root,
    require =>  Vcsrepo[$app_root],
  }
}
