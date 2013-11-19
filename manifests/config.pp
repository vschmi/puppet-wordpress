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
class wordpress::config inherits wordpress (
) {

  file { '/opt/wordpress/db_backup':
    ensure => directory,
  }

  file { '/opt/wordpress/initial_dump.sql'
    ensure  => file,
    content => template('wordpress/initial_dump.sql'),
  }
}
