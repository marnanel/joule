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

package Joule::Template;

use strict;
use warnings;

use Template;
use POSIX;
use File::ShareDir;

sub rfc822date {
	my ($y, $m, $d) = split(/-/, shift);

	return POSIX::strftime(
                '%a, %d %b %Y 00:00:00 GMT',
                0, 0, 0, $d*1, $m*1-1, $y*1-1900,
                );
}

sub template {

	my $template = Template->new({
			INCLUDE_PATH => File::ShareDir::dist_dir('Joule') . '/tmpl',
			COMPILE_EXT => 'c',
			COMPILE_DIR => '/tmp/joule3',
			ABSOLUTE => 1,
			FILTERS => { rfc822date => \&rfc822date, },
			}) || die $Template::ERROR;

	die "No template" unless $template;

	return $template;
}

1;