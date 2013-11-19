# Definition: wordpress::config
#
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# include wordpress::config
#
class wordpress::config(
  $wordpress_admin = 'admin',
  $wordpress_admin_mail = 'localhost@localhost',
  $blogname = 'wordpress blog',
) {

  file { '/opt/wordpress/db_backup':
    ensure => directory,
  }

  file { '/opt/wordpress/initial_dump.sql'
    ensure  => file,
    content => template('wordpress/initial_dump.sql'),
  }
}
