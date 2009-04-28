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

package Joule::Section::Report;

use strict;
use warnings;

use Joule::GraphFitter;
use Joule::Error;
use Joule::History;
use Joule::Template;

sub handler {
    my ($self, $r, $vars) = @_;

    return 0 unless $r->uri =~ /^\/([a-z]+)\/([a-z][a-z])\/([A-Za-z0-9_-]+)/;

    my %modes = (
		    chart => {mimetype => 'text/html', graph => 0, limit=>50},
		    chartnoblanks => {mimetype => 'text/html', graph => 0, limit=>50, noblanks=>1},
		    chartfull => {mimetype => 'text/html', graph => 0},
		    chartfullnoblanks => {mimetype => 'text/html', graph => 0, noblanks=>1},
		    graph => {mimetype => 'text/html', graph => 1, limit=>50},
		    graphfull => {mimetype => 'text/html', graph => 1},
		    rss => {mimetype => 'application/rss+xml', limit=>50},
		    rssnoblanks => {mimetype => 'application/rss+xml', limit=>50, noblanks=>1},
		);

    unless ($modes{$1}) {
	    warn "unknown mode";
	    Joule::Error::http_error($r, 404, $vars);
	    return 1;
    }

    $vars = {%$vars, %{$modes{$1}}, site=>$2, user=>$3 };

    my $status_handler = "From_".uc($vars->{site});
    my $path = "Joule/Status/$status_handler.pm";
    my $modname = "Joule::Status::$status_handler";
    eval { require $path; };

    if ($@) {
	warn "$path handler not found";
	Joule::Error::http_error($r, 404, $vars);
    } elsif (!$modname->can('site')) {
	warn "$modname refused to cooperate.";
	Joule::Error::http_error($r, 404, $vars); # FIXME: 500, really
    } else {

	my $status = ("Joule::Status::From_".uc($vars->{site}))->new($vars);
	$vars->{'sitename'} = $status->site();

	Joule::Template::add_filter('username',
				    $status->can('username_filter') ||
				    sub { return shift; } );

	my $history = Joule::History->new($vars->{'site'}.'/'.$vars->{'user'}, $status);
	$vars->{'days'} = [ $history->content($vars) ];

	Joule::GraphFitter::fit($vars) if ($vars->{'graph'});

	$r->content_type($vars->{'mimetype'});
	my @mime = split(/\//, $vars->{'mimetype'});
	    
	Joule::Template::go($mime[1]."_main.tmpl", $vars);
    }

    return 1;
}

1;
