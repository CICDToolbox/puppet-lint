#
# Base class to manage puppet
#

class tests::test
{
    service { 'puppet':
        ensure => running,
        enable => true,
    }
}
