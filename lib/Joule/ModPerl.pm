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

package Joule::ModPerl;

use strict;
use warnings;

use Apache2::Const -compile => qw(OK);

use Joule::Status::All;

use Joule::Language;
use Joule::GoogleMobile;
use Joule::Database;

our $VERSION = '3.4';

our @sections = qw(Redirect Static TakeDown Report Front);
for (@sections) { require "Joule/Section/$_.pm"; }

sub handler {

	my $r = shift;

	my %vars = (
			site => 'lj', # so chosen by default on first load
			nohiccup => 0,
			noblanks => 0,
		        hostname => $r->hostname,
			sites => Joule::Status::All->sites,
	                # FIXME take this from /etc/joule.conf
	                motd => 'Want to follow the development of Joule?  Follow us <a href="http://twitter.com/marnanel_joule">on Twitter</a>, or <a href="http://identi.ca/joule">on identi.ca</a>, or <a href="http://joule.dreamwidth.org/profile">on Dreamwidth</a>!',
                        version => $VERSION,
	                lang => Joule::Language::user_language($r),
                        Joule::GoogleMobile::mobile_details($r),
		  );

	eval { for (@sections) { last if "Joule::Section::$_"->handler($r, \%vars); } };

	if ($@) {
	    $vars{bug} = $@ || 'generic error';
	    warn $@;
	    Joule::Database::rollback();
	    Joule::Section::Front->handler($r, \%vars);
	}

	return Apache2::Const::OK;
}

1;
