ssh_authorized_key { 'student@host':
  ensure => present,
  user   => 'student',
  type   => 'ed25519',
  key    => 'file(/home/student/id_ed25519.pub)',
}

