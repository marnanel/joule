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

sub _name_of_site {
  my ($site) = @_;
  ($site) = $site =~ /(Joule3.*)$/;
  require $site;
  $site =~ s!/!::!g;
  $site =~ s/\.pm$//g;
  return $site->site();
}

sub sites {
  return map { lc (($_ =~ /From_(..)/)[0]) => _name_of_site($_) } glob($INC[0].'/Joule3/Status/From_*.pm');
}

1;
