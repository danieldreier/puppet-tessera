#tessera

###Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with the Tessera module](#setup)
    * [What the Tessera module affects](#what-tessera-affects)
    * [Beginning with Tessera](#beginning-with-tesera)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##Overview

Tessera is a Graphite front-end developed by Urban Airship. The project is found here:
 [https://github.com/urbanairship/tessera](https://github.com/urbanairship/tessera)

##Module Description

The Tessera module installs the Tessera app in a virtualenv, optionally initializes the sqlite db and assets, and sets up Gunicorn. In order to use this module you'll need to adhere to the requirements in the Modulefile. If you want to build Tessera's assets, you'll need to manage nodejs and grunt elsewhere in your Puppet code.

##Setup

###What the Tessera module affects

* Clones the Tessera repo.
* Creates a Python virtualenv in the Tessera repo.
* Installs all the requirements in addition to the dev-requirements.
* Configures Gunicorn in the virtualenv.
* Optionally initializes the sqlite database.
* Optionally installs js dependencies and builds assets.

###Beginning with the Tessera module

The following class declaration will deploy the Tessera, repo, initialize the sqlite db, and build the assets.

```puppet
class { '::tessera':
    ensure             => 'present',
    build_assets       => true,
    init_db            => true,
    app_root           => '/opt/tessera',
    repo_url           => 'git://github.com/urbanairship/tessera.git',
    version            => 'v0.4.4',
    graphite_url       => 'https://graphite.example.net',
    gunicorn_sock_path => 'unix:/var/run/tessera/tessera.sock',
    tessera_user       => 'www-data',
    tessera_group      => 'www-data',
    require            => Package['git'],
}
```

##Usage

There is only one class in the Tessera module. It has the ability to set up all the components in the correct order.

###I don't want to build assets or use sqlite.

Modify the following parameters.

```puppet
class { '::tessera':
    build_assets      => false,
    init_db           => false,
    sqlalchemy_db_uri => 'postgresql://username:password@tessera-db01-prod.example.net',
}

```

###Want prettier defaults?

Modify the following parameters.

```puppet
class { '::tessera':
    default_refresh_interval    => 60,
    default_theme               => 'snow',
    interactive_charts_default  => 'True',
    interactive_charts_renderer => 'nvd3',
}

```


##Limitations

This module has been built on and tested against Puppet 3.

The module has been tested on:

* Debian 6/7

##Development

Open PR's. Write tests. Go nuts!

###Contributors

The list of contributors can be found at: [https://github.com/Ziaunys/puppet-tessera/graphs/contributors](https://github.com/Ziaunys/puppet-tessera/graphs/contributors)

