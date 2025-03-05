# A minimal Puppet manifest that demonstrates good practices for Puppet Lint: 
file { '/etc/my_config':
  ensure  => present,
  mode    => '0644',
  owner   => 'root',
  group   => 'root',
  content => "This is a simple configuration file.\n",
}
