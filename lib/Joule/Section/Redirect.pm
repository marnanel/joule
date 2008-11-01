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

package Joule::Section::Redirect;

use strict;
use warnings;
use CGI qw/:standard -compile/;
use File::ShareDir;
use Template;
use APR::Table ();

sub handler {

	my ($self, $r, $vars, $template) = @_;

	return 0 unless param();

	my $location = '/';

	if (param('user')) {
		my $site = param('site');
		my $mode = 'chart';

		$site = 'lj' unless $site;
		$mode = 'graph' unless param('graph');

		$location = "/$mode/$site/" . param('user');
	}

	$location = 'http://'.$r->get_server_name.':'.$r->get_server_port.$location;

	$r->headers_out->{'Location'} = $location;
	$r->status(301);

	return 1;
}

1;
