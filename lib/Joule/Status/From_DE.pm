package Joule::Status::From_DE;

use strict;
use warnings;
use LWP::UserAgent;
use JSON;

sub new {
    my ($class, $vars) = @_;

    bless \($vars->{user}), $class;
}

sub site { "del.icio.us"; }

sub names {
    my ($self) = @_;
    my $ua = LWP::UserAgent->new();
    $ua->agent("Joule/3.0 (http://marnanel.org/joule; thomas\@thurman.org.uk)");

    my $req = HTTP::Request->new(GET=>'http://del.icio.us/feeds/json/fans/'.$$self);

    my $res = $ua->request($req);

    die __PACKAGE__ . ' error: ' . $res->status_line() unless $res->is_success();

    return @{ jsonToObj($res->content()) };
}

1;

