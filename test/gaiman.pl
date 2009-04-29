#!/usr/bin/perl

# stress test Joule by looking up Neil Gaiman's twitter account

use strict;
use warnings;
use lib::Joule::Status::From_TW;
use lib::Joule::History;

my $author = 'neilhimself';

my $twitter = Joule::Status::From_TW->new({user=>$author});

my $history = Joule::History->new($author, $twitter);

print "Kicking off...\n";

$history->content();

print "DONE.\n";
