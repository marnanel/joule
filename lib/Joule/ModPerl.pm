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
use Perl6::Slurp;

use Joule::GraphFitter;
use Joule::History;

sub http_error {

        my ($r, $status, $vars, $template) = @_;

	$r->content_type('text/html');
	$r->status($status);
	# factor this out
	$vars->{'literalbody'} = '';
	$template->process("$status.tmpl", $vars, \($vars->{'literalbody'})) || die $template->error();
	$template->process("html_main.tmpl", $vars) || die $template->error();
}

sub handler {

	my $r = shift;

	my %vars= (
			lang => 'en', # fix this properly soon
			user => undef,
			site => 'lj',
			nohiccup => 0,
			format => 'html', # Get rid of this
			mimetype => 'text/html',
			absolute => 'http://marnanel.org', # And this
			noblanks => 0,
		  );

	$vars{name} = "$vars{site}/$vars{user}" if $vars{user};

	my $template = Template->new({
			INCLUDE_PATH => File::ShareDir::dist_dir('Joule') . '/tmpl',
			COMPILE_EXT => 'c',
			COMPILE_DIR => '/tmp/joule3',
			ABSOLUTE => 1,
			}) || die $Template::ERROR;

	my $share = File::ShareDir::dist_dir('Joule');
	my $uri = $r->uri();

# Static handler.  Should be a separate module.

	if ($uri =~ /^\/[^\/]+$/ && $uri !~ /\.\./) {

# note: do not use glob in scalar context in mod_perl:
# it has state
		my @static = glob("$share/static$uri.*");

		if (@static) {

			my $static = @static[0];

			my ($extension) = $static =~ /\.([A-Za-z0-9]+)$/;

			if ($extension eq 'tmpl') {
				# FIXME: This should find a title too
				$r->content_type('text/html');
				$vars{'literalbody'} = '';
				$template->process($static, \%vars, \($vars{'literalbody'})) || die $template->error();
				$template->process("html_main.tmpl", \%vars) || die $template->error();
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
		} else {
                        warn "unknown static";
                        http_error($r, 404, \%vars, $template);
		}

        } elsif ($uri =~ /^\/([a-z]+)\/([a-z][a-z])\/([A-Za-z0-9_-]+)/) {
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

               if ($modes{$1}) {
                      %vars = (%vars, %{$modes{$1}});
                      $vars{'site'} = $2;
                      $vars{'user'} = $3;

                      my $status_handler = "From_".uc($vars{site});
                      my $path = "Joule/Status/$status_handler.pm";
	              my $modname = "Joule::Status::$status_handler";
	              eval { require $path; };

                      if ($@) {
		          warn "$path handler not found";
                          http_error($r, 404, \%vars, $template);
	              } elsif (!$modname->can('site')) {
		          warn "$modname refused to cooperate.";
                          http_error($r, 404, \%vars, $template); # FIXME: 500, really
                      } else {

                          my $status = ("Joule::Status::From_".uc($vars{site}))->new(\%vars);
	                  $vars{sitename} = $status->site();

		          my $history = Joule::History->new($vars{'site'}.'/'.$vars{'user'}, $status);
		          $vars{'days'} = [ $history->content(\%vars) ];

                          Joule::GraphFitter::fit(\%vars) if ($vars{graph});

	                  $template->process("html_main.tmpl", \%vars) || die $template->error();
                      }
               } else {
                      warn "unknown mode";
                      http_error($r, 404, \%vars, $template);
               }

	} else {

                # Front page.

		$r->content_type($vars{mimetype});

		my $template = Template->new({
				INCLUDE_PATH => File::ShareDir::dist_dir('Joule') . '/tmpl',
				COMPILE_EXT => 'c',
				COMPILE_DIR => '/tmp/joule3',
				}) || die $Template::ERROR;

		die "No template: " unless $template;

		$template->process("$vars{format}_main.tmpl", \%vars) || die $template->error();

	}

	return Apache2::Const::OK;
}
1;
