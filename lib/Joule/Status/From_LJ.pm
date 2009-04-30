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

    my $req = HTTP::Request->new(GET=>'http://www.livejournal.com/misc/fdata.bml?user='.$$self.'&comm=1');

    my $res = $ua->request($req);

    die __PACKAGE__ . ' error: ' . $res->status_line() unless $res->is_success();
    
    for (split('\n', $res->content())) {
      $callback->($2) if $_ =~ /^(<|P>) (.*)$/;
    }
}

sub username_filter {
    my ($name) = @_;
    # FIXME: The image URL here should be with respect to $vars->{hostname},
    # but we don't have access to that from here and it needs to be an absolute
    # URL for when it appears in RSS.
    return "<span class=\"user\"><a href=\"http://$name.livejournal.com/profile\">".
	"<img class=\"userinfo\" src=\"http://joule.marnanel.org/userinfo\" ".
	"width=\"17\" height=\"17\" alt=\"~\" /></a>".
	"<a href=\"http://$name.livejournal.com\">$name</a></span>";
}

1;

