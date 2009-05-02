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

sub referrers { ('twitter.com'); }

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
    die "The upstream server refused to send us names.  ".
	"This is a <a href=\"https://bugs.launchpad.net/joule/+bug/368347\">known ".
	"bug</a> and may be an error in Twitter.  It seems ".
	"to happen for users with very large numbers of followers.\n" if $res->code == 502;
    die $res->status_line()."\n" unless $res->is_success();
    die "This user has several thousand followers and it would take many minutes ".
	"to download them all.  If you are this user, email us and ask for this ".
	"to be submitted as a background job every night.  We are working on ".
	"<a href=\"https://blueprints.launchpad.net/joule/+spec/snipsnap\">a ".
	"fix for this</a> which should be in the next release.\n" if length($res->content)>102400;

    for (@{ from_json($res->content()) }) {
	$callback->($_);
    }

}

sub _code { 'tw' }
sub _endpoint { 'http://twitter.com/' }

# warning: code is duplicated in From_ID
# this needs a superclass.
sub _lookup {
    my ($id) = @_;

    my $userid = _code() . '/' . $id;
    my $dbh = Joule::Database::handle;

    my $sth = $dbh->prepare('SELECT username, picture FROM microname WHERE userid=?');
    $sth->execute($userid);
    my @result = $sth->fetchrow_array();

    return {
	userid => $result[0],
	pic => $result[1],
    } if @result;

    # otherwise, look it up
    my $ua = LWP::UserAgent->new;
    $ua->agent('Joule/3.0 (http://joule.marnanel.org; thomas@thurman.org.uk)');
    my $req = HTTP::Request->new(GET => _endpoint . 'users/show.json?user_id='.$id);
    my $res = $ua->request($req);

    return undef unless $res->is_success;

    my $data = from_json($res->content);

    # and cache it
    $sth = $dbh->prepare('INSERT INTO microname (userid, username, picture) VALUES (?, ?, ?)');
    $sth->execute($userid, $data->{screen_name}, $data->{profile_image_url});

    $dbh->commit();

    return {
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

