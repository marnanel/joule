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

package Joule::Section::Front;

use strict;
use warnings;
use File::ShareDir;
use Joule::Template;

sub handler {

	my ($self, $r, $vars, $template) = @_;

	$r->content_type('text/html');

	my $template = Joule::Template::template;
	$template->process("html_main.tmpl", $vars) || die $template->error();

	return 1;
}

1;
