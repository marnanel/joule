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
use Joule::Database;

sub new {
    my ($class, $vars) = @_;

    bless \($vars->{user}), $class;
}

sub site { "Twitter"; }

my $_login = (do '/etc/joule.conf')->{'twitter'};

sub names {
    my ($self, $callback) = @_;

    my $hh = HTTP::Headers->new();
    $hh->authorization_basic ($_login->[0], $_login->[1]);

    my $ua = LWP::UserAgent->new();
    $ua->agent("Joule/3.0 (http://marnanel.org/joule; thomas\@thurman.org.uk)");

    my $req = HTTP::Request->new(GET=>'http://twitter.com/followers/ids.json?screen_name='.$$self, $hh);

    my $res = $ua->request($req);

    die "Sorry, can't seem to find that user.\n" if $res->code == 401;
    die $res->status_line()."\n" unless $res->is_success();

    for (@{ from_json($res->content()) }) {
	$callback->($_);
    }
}

sub _lookup {
    my ($id) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent('Joule/3.0 (http://joule.marnanel.org; thomas@thurman.org.uk)');
    my $req = HTTP::Request->new(GET => 'http://twitter.com/users/show.json?user_id='.$id);
    my $res = $ua->request($req);

    return undef unless $res->is_success;

    my $data = from_json($res->content);

    return {
	name => $data->{name},
	userid => $data->{screen_name},
	pic => $data->{profile_image_url},
    };
}

sub username_filter {
    my ($name) = @_;

    my $details = _lookup($name);

    if ($details) {
	return "<span class=\"user\"><a href=\"http://twitter.com/$details->{userid}\">".
	    "<img class=\"userinfo\" src=\"$details->{pic}\" ".
	    "width=\"17\" height=\"17\" alt=\"~\" />$details->{userid}</a></span>";
    } else {
	return "(?? $name ??)";
    }

}

1;

