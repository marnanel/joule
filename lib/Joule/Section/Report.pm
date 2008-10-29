package Joule::Section::Report;

use strict;
use warnings;

use Joule::GraphFitter;
use Joule::Error;
use Joule::History;

sub handler {
    my ($self, $r, $vars, $template) = @_;

    return 0 unless $r->uri =~ /^\/([a-z]+)\/([a-z][a-z])\/([A-Za-z0-9_-]+)/;

    $r->content_type('text/html');

    my %modes = (
		    chart => {mimetype => 'text/html', graph => 0, limit=>50},
		    chartnoblanks => {mimetype => 'text/html', graph => 0, limit=>50, noblanks=>1},
		    chartfull => {mimetype => 'text/html', graph => 0},
		    chartfullnoblanks => {mimetype => 'text/html', graph => 0, noblanks=>1},
		    graph => {mimetype => 'text/html', graph => 1, limit=>50},
		    graphfull => {mimetype => 'text/html', graph => 1},
		    rss => {mimetype => 'text/rss', limit=>50},
		);

    unless ($modes{$1}) {
	    warn "unknown mode";
	    http_error($r, 404, $vars, $template);
	    return 1;
    }

    $vars = {%$vars, %{$modes{$1}}, site=>$2, user=>$3 };

    my $status_handler = "From_".uc($vars->{site});
    my $path = "Joule/Status/$status_handler.pm";
    my $modname = "Joule::Status::$status_handler";
    eval { require $path; };

    if ($@) {
	    warn "$path handler not found";
	    Joule::Error::http_error($r, 404, $vars, $template);
    } elsif (!$modname->can('site')) {
	    warn "$modname refused to cooperate.";
	    Joule::Error::http_error($r, 404, $vars, $template); # FIXME: 500, really
    } else {

	    my $status = ("Joule::Status::From_".uc($vars->{site}))->new($vars);
	    $vars->{'sitename'} = $status->site();

	    my $history = Joule::History->new($vars->{'site'}.'/'.$vars->{'user'}, $status);
	    $vars->{'days'} = [ $history->content($vars) ];

	    Joule::GraphFitter::fit($vars) if ($vars->{'graph'});

	    $template->process("html_main.tmpl", $vars) || die $template->error();
    }

    return 1;
}

1;
