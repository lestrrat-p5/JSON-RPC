requires 'CGI';
requires 'Class::Accessor::Lite';
requires 'HTTP::Request';
requires 'HTTP::Response';
requires 'JSON::MaybeXS';
requires 'LWP::UserAgent';
requires 'Plack';
requires 'Router::Simple';
requires 'parent';
recommends 'Cpanel::JSON::XS';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'Plack::Request';
    requires 'Plack::Test';
    requires 'Test::More';
};
