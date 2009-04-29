#!/usr/bin/perl

# stress test Joule by looking up Neil Gaiman's twitter account

use strict;
use warnings;
use lib::Joule::Status::From_TW;

my $count = 0;

sub callback {
    $count++;
}

my $twitter = Joule::Status::From_TW->new({user=>'neilhimself'});

$twitter->names(\&callback);

print "Final count is $count.\n";
