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

1;
