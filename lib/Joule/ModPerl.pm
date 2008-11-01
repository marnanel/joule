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

use Joule::Section::Redirect;
use Joule::Section::Static;
use Joule::Section::Report;
use Joule::Section::Front;

use Joule::Status::All;

use Joule::Language;

sub handler {

	my $r = shift;

	my %vars = (
			lang => 'en', # fix this properly soon
			site => 'lj', # so chosen by default on first load
			nohiccup => 0,
			noblanks => 0,
		        hostname => $r->hostname,
			sites => Joule::Status::All->sites,
		  );
	$vars{strings} = Joule::Language::strings($r, \%vars);

	my $template = Joule::Template::template();

        for my $i qw(Redirect Static Report Front) {
	    last if "Joule::Section::$i"->handler($r, \%vars, $template);
        }

	return Apache2::Const::OK;
}
1;
