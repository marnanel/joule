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
    my ($self) = @_;

    my $hh = HTTP::Headers->new();
    $hh->authorization_basic ($_login->[0], $_login->[1]);

    my $ua = LWP::UserAgent->new();
    $ua->agent("Joule/3.0 (http://marnanel.org/joule; thomas\@thurman.org.uk)");

    my $page = 1;
    my $content = '';

    # note: this loop hasn't been ported to the identi.ca
    # code because I don't think we've run into the
    # paging problem there; it should go into the
    # superclass when it's written anyway.
    while (1) {

	my $req = HTTP::Request->new(GET=>'http://twitter.com/followers/ids.json?screen_name='.$$self."&page=$page",
				     $hh);
	$page++;
	my $res = $ua->request($req);
	die "Sorry, can't seem to find that user.\n" if $res->code == 401;

	# Hoping this isn't still a problem, but leaving
	# it in for now in case it is.
	die "The upstream server refused to send us names.  ".
	    "This is a <a href=\"https://bugs.launchpad.net/joule/+bug/368347\">known ".
	    "bug</a> and may be an error in Twitter.  It seems ".
	    "to happen for users with very large numbers of followers.\n" if $res->code == 502;
	die $res->status_line()."\n" unless $res->is_success();

	last if $res->content =~ /\[\]/;
	$content .= $res->content();
    }

    $content =~ s/\]\[/,/g;
    $content =~ s/^\[//;
    $content =~ s/\]\s*$//g;

    my %result = map {$_=>undef} split(',', $content);
    return join("\n", sort keys %result);
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

