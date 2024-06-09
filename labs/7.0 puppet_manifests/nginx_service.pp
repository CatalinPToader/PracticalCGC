package { 'nginx':
  ensure => present,
}
->
file { '/etc/nginx/nginx.conf':
  ensure => file,
  mode   => '0644',
  source => '/home/student/config-samples/nginx.conf',
}
->
file { '/usr/share/nginx/html/index.html':
  ensure  => file,
  mode    => '0644',
  content => '<html><body><h1>Welcome to NGINX!</h1></body></html>',
}
~>
service { 'nginx':
  ensure => running,
  enable => true,
}
