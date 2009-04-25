#    Joule - track changes in an online list over time
#    Copyright (C) 2002-2008 Thomas Thurman
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
    my ($self, $callback) = @_;

    my $ua = LWP::UserAgent->new();
    $ua->agent("Joule/3.0 (http://marnanel.org/joule; thomas\@thurman.org.uk)");

    my $req = HTTP::Request->new(GET=>'http://www.livejournal.com/misc/fdata.bml?user='.$$self);

    my $res = $ua->request($req);

    die __PACKAGE__ . ' error: ' . $res->status_line() unless $res->is_success();
    
    for (split('\n', $res->content())) {
      $callback->($1) if $_ =~ /^< (.*)$/;
    }
}

1;

