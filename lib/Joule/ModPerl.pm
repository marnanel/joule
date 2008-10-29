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

use Apache2::RequestRec ();
use Apache2::RequestIO ();

use Apache2::Const -compile => qw(OK);

use File::ShareDir;
use Template;

use Joule::Section::Static;
use Joule::Section::Report;
use Joule::Section::Front;

use Joule::Status::All;

sub handler {

	my $r = shift;

	my %vars= (
			lang => 'en', # fix this properly soon
			nohiccup => 0,
			format => 'html', # Get rid of this
			mimetype => 'text/html',
			noblanks => 0,
			sites => Joule::Status::All->sites(),
		  );

	my $template = Template->new({
			INCLUDE_PATH => File::ShareDir::dist_dir('Joule') . '/tmpl',
			COMPILE_EXT => 'c',
			COMPILE_DIR => '/tmp/joule3',
			ABSOLUTE => 1,
			}) || die $Template::ERROR;

	die "No template" unless $template;

        for my $i qw(Static Report Front) {
           last if "Joule::Section::$i"->handler($r, \%vars, $template);
        }

	return Apache2::Const::OK;
}
1;
