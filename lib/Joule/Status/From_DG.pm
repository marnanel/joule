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

package Joule::Status::From_DG;

use strict;
use warnings;
use LWP::UserAgent;
use JSON;

sub new {
    my ($class, $vars) = @_;

    bless \($vars->{user}), $class;
}

sub site { "Digg"; }
sub referrers { ('digg.com'); }

my $_appkey = (do '/etc/joule.conf')->{'digg'};

sub names {
    my ($self) = @_;

    my $offset = 0;

    my $ua = LWP::UserAgent->new;
    $ua->agent("Joule/3.0 (http://marnanel.org/joule; thomas\@thurman.org.uk)");

    my @result;

    while (1) {
	my $req = HTTP::Request->new(GET => "http://services.digg.com/user/$$self/fans?type=json&count=100&offset=$offset&appkey=$_appkey");
	my $res = $ua->request($req);

	die $res->status_line unless $res->is_success;
	my $result = from_json($res->content);
	my @subtotal = map { $_->{'name'} } @{$result->{'users'}};

	@result = (@result, grep { $_ and $_ ne 'inactive' } @subtotal);

	last unless scalar(@subtotal)==100;
	$offset += 100;
    }

    return join("\n", sort @result);
}

sub username_filter {
    my ($name) = @_;

    return "<span class=\"user\"><a href=\"http://digg.com/users/$name/\">".
	"<img class=\"userinfo\" src=\"http://digg.com/users/$name/s.png\" ".
	"width=\"16\" height=\"16\" alt=\"~\" />$name</a></span>";
}

1;

