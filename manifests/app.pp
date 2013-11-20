# Install wordpress application and its dependencies
class wordpress::app inherits wordpress {

  $wordpress_archive = 'wordpress-3.5.1.zip'

  $apache = $::operatingsystem ? {
    Ubuntu   => apache2,
    CentOS   => httpd,
    Debian   => apache2,
    default  => httpd
  }

  $phpmysql = $::operatingsystem ? {
    Ubuntu   => php5-mysql,
    CentOS   => php-mysql,
    Debian   => php5-mysql,
    default  => php-mysql
  }

  $php = $::operatingsystem ? {
    Ubuntu   => libapache2-mod-php5,
    CentOS   => php,
    Debian   => libapache2-mod-php5,
    default  => php
  }

  package { ['unzip',$php,$phpmysql]:
    ensure => latest
  }

  $vhost_path = $apache ? {
    httpd    => '/etc/httpd/conf.d/wordpress.conf',
    apache2  => '/etc/apache2/sites-enabled/000-default',
    default  => '/etc/httpd/conf.d/wordpress.conf',
  }

  file { 'wordpress_application_dir':
    ensure  =>  directory,
    path    =>  '/opt/wordpress',
    before  =>  File['wordpress_setup_files_dir'],
  }

  file { 'wordpress_setup_files_dir':
    ensure  =>  directory,
    path    =>  '/opt/wordpress/setup_files',
    before  =>  File[
      'wordpress_php_configuration',
      'wordpress_themes',
      'wordpress_plugins',
      'wordpress_installer'
    ],
  }

  file { 'wordpress_installer':
    ensure  =>  file,
    path    =>  "/opt/wordpress/setup_files/${wordpress_archive}",
    notify  =>  Exec['wordpress_extract_installer'],
    source  =>  "puppet:///modules/wordpress/${wordpress_archive}",
  }

  file {'wordpress_php_configuration':
    ensure     =>  file,
    path       =>  '/opt/wordpress/wp-config.php',
    content    =>  template('wordpress/wp-config.erb'),
    subscribe  =>  Exec['wordpress_extract_installer'],
  }

  file { 'wordpress_themes':
    ensure     => directory,
    path       => '/opt/wordpress/setup_files/themes',
    source     => 'puppet:///modules/wordpress/themes/',
    recurse    => true,
    purge      => true,
    ignore     => '.svn',
    notify     => Exec['wordpress_extract_themes'],
    subscribe  => Exec['wordpress_extract_installer'],
  }

  file { 'wordpress_plugins':
    ensure     => directory,
    path       => '/opt/wordpress/setup_files/plugins',
    source     => 'puppet:///modules/wordpress/plugins/',
    recurse    => true,
    purge      => true,
    ignore     => '.svn',
    notify     => Exec['wordpress_extract_plugins'],
    subscribe  => Exec['wordpress_extract_installer'],
  }

  file { 'wordpress_vhost':
    ensure   => file,
    path     => $vhost_path,
    source   => 'puppet:///modules/wordpress/wordpress.conf',
    replace  => true,
    require  => Class['apache2'],
  }

  if $::wordpress::multisite == true {
    file { '/opt/wordpress/.htaccess':
      ensure  => file,
      content => template('wordpress/htaccess.erb'),
      require => File['wordpress_setup_files_dir'],
    }
  }

  exec {
  'wordpress_extract_installer':
    command      => "unzip -o\
                    /opt/wordpress/setup_files/${wordpress_archive}\
                    -d /opt/",
    refreshonly  => true,
    require      => Package['unzip'],
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'];
  'wordpress_extract_themes':
    command      => '/bin/sh -c \'for themeindex in `ls \
                    /opt/wordpress/setup_files/themes/*.zip`; \
                    do unzip -o \
                    $themeindex -d \
                    /opt/wordpress/wp-content/themes/; done\'',
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
    refreshonly  => true,
    require      => Package['unzip'],
    subscribe    => File['wordpress_themes'];
  'wordpress_extract_plugins':
    command      => '/bin/sh -c \'for pluginindex in `ls \
                    /opt/wordpress/setup_files/plugins/*.zip`; \
                    do unzip -o \
                    $pluginindex -d \
                    /opt/wordpress/wp-content/plugins/; done\'',
    path         => ['/bin','/usr/bin','/usr/sbin','/usr/local/bin'],
    refreshonly  => true,
    require      => Package['unzip'],
    subscribe    => File['wordpress_plugins'];
  }
}
