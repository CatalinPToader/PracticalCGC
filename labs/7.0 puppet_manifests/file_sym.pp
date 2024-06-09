file { '/tmp/my_file':
  ensure  => present,
  path    => '/tmp/my_file',
  mode    => '0640',
  content => 'This is the content of my_file.',
}

file { '/tmp/my_symlink':
  ensure => 'link',
  target => '/tmp/my_file',
}

