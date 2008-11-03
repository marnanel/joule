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

package Joule::Error;

use strict;
use warnings;

use Joule::Template;

sub http_error {

        my ($r, $status, $vars) = @_;

	$r->content_type('text/html');
	$r->status($status);
	# factor this out
	$vars->{'literalbody'} = '';
	my $template = Joule::Template::template;
	$template->process("$status.tmpl", $vars, \($vars->{'literalbody'})) || die $template->error();

        Joule::Template::go("html_main.tmpl", $vars);
}

1;
