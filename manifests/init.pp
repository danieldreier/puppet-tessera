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
# [*build_assets*]
#  A boolean to set whether or not this module will build the assets for the application
#  using grunt. Grunt needs to be installed for this to work.
#
# [*dashboard_appname*]
#  Set the default name of the application which will appear on the main page. Rename to whatever
#  you want.
#
# [*default_refresh_interval*]
#  The default interval at which the dashboard will refresh.
#
# [*debug*]
#  Turn on debug mode.
#
# [*default_theme*]
#  The default dashboard theme. See the Tessera docs for default themes.
#
# [*display_timezone*]
#  The default timezone displayed on graphs.
#
# [*ensure*]
#  Set to present or absent to install/remove the application.
#
# [*graphite_url*]
#  The full url to the default Graphite server.
#
# [*gunicorn_sock_path*]
#  The full path to the gunicorn socket.
#
# [*init_db*]
#  A boolean to indicate whether the module should initialize the sqlite database.
#
# [*interactive_charts_default*]
#  Set the default display type for charts. See the Tessera docs for details.
#
# [*interactive_charts_renderer*]
#  Set the rendering engine for charts. See the Tessera docs for details.
#
# [*pid_dir*]
#  Set the path of the pid directory. This is where the pid file will live.
#
# [*migration_dir*]
#  Directory to perform the db migration.
#
# [*repo_url*]
#  Optional url for the project repository.
#
# [*secret_key*]
#  Set to enable secure sessions.
#
# [*server_address*]
#  Set the bind address for the dev server. Only necessary if testing.
#
# [*server_port*]
#  Set the listen port for the dev server. Only necessary if testing.
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
  $default_refresh_interval = 60,
  $debug = 'False',
  $default_theme = 'light',
  $display_timezone = 'Etc/UTC',
  $ensure = undef,
  $graphite_url = undef,
  $gunicorn_sock_path = undef,
  $init_db = false,
  $interactive_charts_default = 'True',
  $interactive_charts_renderer = 'nvd3',
  $migration_dir = 'migrations',
  $pid_dir = '/var/run/tessera',
  $repo_url = undef,
  $secret_key = 'REPLACE ME',
  $server_address = '0.0.0.0',
  $server_port = 5000,
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
    ensure   => $ensure,
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
    owner   =>  $tessera_user,
    group   =>  $tessera_group,
    require => Vcsrepo[$app_root],
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
  }

  if $init_db {
    exec { 'init_db':
      command  => "${venv_tessera} inv initdb",
      provider => 'shell',
      creates  => "${app_root}/tessera/tessera.db",
      cwd      =>  $app_root,
      require =>  [
                    Python::Virtualenv[$app_root],
                    Python::Pip['invoke'],
                    Python::Pip['invocations'],
                ],
    }
  }

  if $build_assets {
    exec { 'build_assets':
      command  => 'npm install && grunt',
      provider => 'shell',
      creates  => "${app_root}/tessera/static/app.js",
      cwd      => $app_root,
      require =>  [
                    Python::Virtualenv[$app_root],
                ],
    }
  }
}
