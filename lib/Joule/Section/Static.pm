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

package Joule::Section::Static;

use strict;
use warnings;

use Joule::Error;
use Joule::Template;

use Perl6::Slurp;
use File::ShareDir;

sub handler {
    my ($self, $r, $vars) = @_;

    return 0 unless $r->uri =~ /^\/[^\/]+$/ && $r->uri !~ /\.\./;

    my $template = Joule::Template::template;

    # note: do not use glob in scalar context in mod_perl:
    # it has state
    my @static = glob(File::ShareDir::dist_dir('Joule').'/static'.$r->uri.'.*');

    unless (@static) {
	warn "unknown static";
	Joule::Error::http_error($r, 404, $vars, $template);
	return 1;
    }

    my $static = @static[0];
    my ($extension) = $static =~ /\.([A-Za-z0-9]+)$/;

    if ($extension eq 'tmpl') {
            # FIXME: This should find a title too
	    $r->content_type('text/html');
	    $vars->{'literalbody'} = '';
	    $template->process($static, $vars, \($vars->{'literalbody'})) || die $template->error();
	    $template->process("html_main.tmpl", $vars) || die $template->error();
    } else {

	    my %mimemapping = (
			    css => 'text/css',
			    tmpl => 'text/html',
			    png => 'image/png',
			    jpg => 'image/jpg',
			    gif => 'image/gif',
			    );

	    if ($mimemapping{$extension}) {
		    $r->content_type($mimemapping{$extension});
	    } else {
		    $r->content_type('text/plain');
	    }

	    print slurp("<$static");
    }

    return 1;
}

1;
