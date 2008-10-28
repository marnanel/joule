package Joule::Status::From_LJ;

use strict;
use warnings;
use LWP::UserAgent;
use Data::Dumper;

sub new {
    my ($class, $vars) = @_;

    bless \($vars->{user}), $class;
}

sub site { "LiveJournal"; }

sub names {
    my ($self) = @_;
    my $ua = LWP::UserAgent->new();
    $ua->agent("Joule/3.0 (http://marnanel.org/joule; thomas\@thurman.org.uk)");

    my $req = HTTP::Request->new(GET=>'http://www.livejournal.com/misc/fdata.bml?user='.$$self);

    my $res = $ua->request($req);

    die __PACKAGE__ . ' error: ' . $res->status_line() unless $res->is_success();
    
    my @result;

    for (split('\n', $res->content())) {
      push @result, $1 if $_ =~ /^< (.*)$/;
    }

    return @result;
}

1;

