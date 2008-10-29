package Joule::Section::Front;

use strict;
use warnings;
use File::ShareDir;
use Template;

sub handler {

	my ($self, $r, $vars, $template) = @_;

	$r->content_type($vars->{mimetype});

	$template->process("$vars->{format}_main.tmpl", $vars) || die $template->error();

	return 1;
}

1;
