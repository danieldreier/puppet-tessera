class { '::tessera':
    ensure                      => 'present',
    build_assets                => true,
    init_db                     => true,
    app_root                    => '/opt/tessera',
    repo_url                    => 'git://github.com/urbanairship/tessera.git',
    version                     => 'v0.4.4',
    graphite_url                => 'https://graphite.example.net',
    gunicorn_sock_path          => 'unix:/var/run/tessera/tessera.sock',
    tessera_user                => 'www-data',
    tessera_group               => 'www-data',
    default_refresh_interval    => 60,
    default_theme               => 'snow',
    interactive_charts_default  => 'True',
    interactive_charts_renderer => 'nvd3',
    require                     => Package['git'],
}

package {'git':
  ensure => present
}
