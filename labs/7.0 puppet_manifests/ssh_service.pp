package { 'openssh-server':
  ensure => present,
}
->
file { '/etc/ssh/sshd_config':
  ensure => file,
  mode   => '0600',
  source => '/home/student/config-samples/sshd_config',
}
~>
service { 'sshd':
  ensure => running,
  enable => true,
}
