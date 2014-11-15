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
  $build_assets = false,
  $dashboard_appname = 'Tessera',
  $display_timezone = '-3h',
  $debug = false,
  $default_theme = 'light',
  $ensure = undef,
  $graphite_url = undef,
  $gunicorn_sock_path = undef,
  $init_db = false,
  $pid_dir = '/var/run/tessera',
  $repo_url = undef,
  $secret_key = undef,
  $sqlalchemy_db_uri = 'sqlite:///tessera.db',
  $tessera_user = undef,
  $tessera_group = undef,
  $version = undef,
){

  if $tessera_user == undef {
    fail("Must define \$tessera_user.")
  }
  if $tessera_group == undef {
    fail("Must define \$tessera_group.")
  }

  vcsrepo { $app_root:
    provider => 'git',
    source   => $repo_url,
    revision => $version,
    owner    => $tessera_user,
    group    => $tessera_group,
  }

  # Templating Python with erb is dumb.
  file { "${app_root}/tessera/config.py":
    ensure  => $ensure,
    content => template('tessera/config.py.erb'),
    mode    =>  0644,
    user    =>  $tessera_user,
    group   =>  $tessera_group,
    before  => Vcsrepo[$app_root],
  }

  python::virtualenv { $app_root:
    cwd          => $app_root,
    requirements => "${app_root}/requirements.txt",
    owner        =>  $tessera_user,
    group        =>  $tessera_group,
    require      =>  Vcsrepo[$app_root],
  }

  python::requirements { "${app_root}/requirements.txt":
    virtualenv => $app_root,
    require    =>  Vcsrepo[$app_root],
    owner      => $tessera_user,
    group      => $tessera_group,
  }

  python::pip { 'invoke':
    pkgname    => 'invoke',
    virtualenv => $app_root,
    owner      => $tessera_user,
  }

  python::pip { 'invocations':
    pkgname    => 'invocations',
    virtualenv => $app_root,
    owner      => $tessera_user,
  }

  python::pip { 'gunicorn':
    ensure     => '0.14.5',
    pkgname    =>  'gunicorn',
    virtualenv => $app_root,
    owner      => $tessera_user,
  }

 python::gunicorn { 'tessera':
    ensure     => $ensure,
    virtualenv => $app_root,
    appmodule  => 'tessera:app',
    dir        => "${app_root}/tessera",
    require    => [Vcsrepo[$app_root],
                    File["/var/run/tessera"],
                    Python::Virtualenv[$app_root],
                    Python::Pip['gunicorn'],],
    bind       => $gunicorn_sock_path,
    owner      => $tessera_user,
    group      => $tessera_group,
  }

  file { $pid_dir:
    ensure  => directory,
    owner   => $tessera_user,
    group   =>  $tessera_group,
    mode    => 0740,
  }

  file { "/etc/gunicorn.d":
    ensure  => directory,
    recurse => true,
    owner   => $tessera_user,
    group   =>  $tessera_group,
    mode    => 0740,
  }

  $venv_tessera = ". bin/activate &&"
  Exec {
    user    => $tessera_user,
    group   => $tessera_group,
    require =>  [
                  Python::Virtualenv[$app_root],
                  Python::Pip['invoke'],
                  Python::Pip['invocations'],
              ],
  }

  exec { 'init_db':
    command  => "${venv_tessera} inv initdb",
    provider => 'shell',
    creates  => "${app_root}/tessera/tessera.db",
    cwd      =>  $app_root,
  }

  exec { 'build_assets':
    command  => 'grunt',
    provider => 'shell',
    creates  => "${app_root}/tessera/static",
    cwd      => $app_root,
  }
}
