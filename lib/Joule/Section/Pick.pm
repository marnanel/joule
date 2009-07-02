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

package Joule::Section::Pick;

use strict;
use warnings;
use Joule::Template;
use Joule::Status::All;

my $_sites = (do '/etc/joule.conf')->{'sites'};
my %_names = %{Joule::Status::All::sites()};

sub handler {

	my ($self, $r, $vars, $template) = @_;
	return 0 unless $r->uri =~ m!^/chart/pick/([A-Za-z0-9_-]+)!;

	my @sites;

	for (@$_sites) {
	    push @sites, {
		code => $_,
		name => $_names{$_},
	    };
	}

	$vars->{'username'} = $1;
	$vars->{'sites'} = \@sites;

	$r->content_type('text/html');

	$vars->{'literalbody'} = '';
	my $template = Joule::Template::template;
	$template->process('pick.tmpl', $vars, \($vars->{'literalbody'})) || die $template->error();

	Joule::Template::go('html_main.tmpl', $vars);

	return 1;
}

1;
