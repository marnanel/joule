#    Joule - track changes in an online list over time
#    Copyright (C) 2002-2009 Thomas Thurman
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

package Joule::Status::From_TW;

use strict;
use warnings;
use LWP::UserAgent;
use JSON;

sub new {
    my ($class, $vars) = @_;

    bless \($vars->{user}), $class;
}

sub site { "Twitter"; }

sub names {
    my ($self, $callback) = @_;

    my $ua = LWP::UserAgent->new();
    $ua->agent("Joule/3.0 (http://marnanel.org/joule; thomas\@thurman.org.uk)");

    my $req = HTTP::Request->new(GET=>'http://twitter.com/followers/ids.json?screen_name='.$$self);

    my $res = $ua->request($req);

    die __PACKAGE__ . ' error: ' . $res->status_line() unless $res->is_success();

    for (@{ from_json($res->content()) }) {
	$callback->($_);
    }
}

1;

