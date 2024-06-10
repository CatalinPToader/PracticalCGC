# NGINX Installation and Configuration Manifest

# Ensure the nginx package is installed
package { 'nginx':
  ensure => present,
}

# Custom content for the index.html file
$index_content = '<html><body><h1>Welcome to NGINX on Puppet!</h1></body></html>'

# OS-specific variables
$root_html_dir = $facts['os']['family'] ? {
  'RedHat' => '/usr/share/nginx/html',
  'Debian' => '/var/www/html',
  default  => '/usr/share/nginx/html',  # Default for other OS families
}

$user = $facts['os']['family'] ? {
  'RedHat' => 'nginx',
  'Debian' => 'www-data',
  default  => 'nginx',  # Default for other OS families
}

# Ensure the custom index.html file is present with the correct permissions
file { "${root_html_dir}/index.html":
  ensure  => file,
  mode    => '0644',
  content => $index_content,
  owner   => $user,
  group   => $user,
  require => Package['nginx'],
}

# Ensure the nginx service is running and enabled
service { 'nginx':
  ensure    => running,
  enable    => true,
  subscribe => File["${root_html_dir}/index.html"],
}
