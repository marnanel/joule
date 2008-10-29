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

use Joule::Status::From_DE;
use Joule::Status::From_LJ;

# The old CGI Joule used to iterate over the directory so you could just
# drop in handlers, but I'm not sure how to do this given proper packaging
# and besides it's probably not for the best to have to scan the directory
# on every page load.
sub sites {
	return {
		'de' => Joule::Status::From_DE->site(),
		'lj' => Joule::Status::From_LJ->site(),
	};
}

1;
