#
# Top level documentation
#
class tests::test
{
    #
    # Service level documentation
    #
    service { 'puppet':
        ensure => running,
        enable => true,
    }
}
