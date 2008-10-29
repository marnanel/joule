package Joule::Section::Static;

use strict;
use warnings;
use Joule::Error;
use Perl6::Slurp;

sub handler {
    my ($self, $r, $vars, $template) = @_;

    return 0 unless $r->uri =~ /^\/[^\/]+$/ && $r->uri !~ /\.\./;

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
