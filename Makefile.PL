use inc::Module::Install;

eval {
    local %INC;
    require JSON::RPC;

    # if you got here successfully, we were able to load a
    # pre-existing version.

    if ($JSON::RPC::VERSION < 1.00) {
        print STDERR <<EOM;

***** WARNING! *****

Whoa there! We found JSON::RPC ($JSON::RPC::VERSION) in your system.
If you have code that relies on this previous version, DO NOT UPGRADE.

JSON::RPC has been re-written and re-worked. It's a completely different
code base now, and because the old code pre dates PSGI/Plack, we figured
it was not worth making things API compatible. So if you have code
that uses this old code and upgrade, YOUR CODE WILL BREAK!

If you are sure you want to upgrade, be my guest.

EOM

        my $y_n = prompt("Really upgrade? (y/n)", "n");
        chomp $y_n;
        if ( $y_n !~ /^y(?:es)?$/i ) {
            print STDERR <<EOM;
Okay, bailing out. Come back soon!
EOM
            exit 1;
        }

        print STDERR <<EOM;
Okay, proceeding!
EOM

    }
};


name 'JSON-RPC';
all_from 'lib/JSON/RPC.pm';

requires 'parent';
requires 'CGI';
requires 'Class::Accessor::Lite';
requires 'HTTP::Request';
requires 'HTTP::Response';
requires 'JSON';
requires 'LWP::UserAgent';
requires 'Plack';
requires 'Router::Simple';

recommends 'JSON::XS';

tests 't/*.t t/*/*.t';

test_requires 'Test::More';
test_requires 'Plack::Test';
test_requires 'Plack::Request';

WriteAll;
