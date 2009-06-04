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

package Joule::Status::All;

use strict;
use warnings;

my @sites = @{ (do '/etc/joule.conf')->{'sites'} };

for (@sites) { require "Joule/Status/From_\U$_\L.pm"; }

# Returns a hashref mapping site codes to site names.
sub sites {
    return { map { $_ => "Joule::Status::From_\U$_"->site() } @sites };
}

# Given a request object, guesses which site to highlight
# based on the referrer.  The section handlers can override
# this-- for example, if you come from LJ and go to a Twitter
# chart, Twitter will still be highlighted.
# (Note that we match anywhere in the string, not just the
# hostname.)
# (Note also that unlike the HTTP spec, we can spell "referrer".)
sub site_from_referrer {
    my ($r) = @_;
    my $src = $r->headers_in->get('Referer') || '';

    return $sites[0] if index($src, $r->hostname)!=-1;

    for (@sites) {
	my $handler = "Joule::Status::From_\U$_"->can('referrers');
	next unless $handler;

	for my $domain ($handler->()) {
	    return $_ if index($src, $domain)!=-1;
	    return $_ if $r->uri eq "/$_"; # allow custom landing pages
	}
    }

    return $sites[0]; # safe choice
}


1;
