package Joule::ModPerl;

use strict;
use warnings;
#use CGI::Compress::Gzip qw/-oldstyle_urls/;
use Joule::History;
use Data::Dumper;
use Template;

my $rfc822 = '%a, %d %b %Y 00:00:00 GMT';

sub show_error {
  my ($vars, $err) = @_;
  warn $err;
  $vars->{errormessage} = $err;
}

sub handler {

  my $query = new CGI::Compress::Gzip();

  # === THE PARAMETERS ===

# URL checking: totally funted; come back to it
#  print "Content-Type: text/plain\n\n";

#  my $canonical = 0;
  #my ($rssmark, $site, $username) = CGI::Compress::Gzip::url(-absolute) =~ m{/joule3?0?(-as-rss)?(?:/(.*)/(.*))?/?$};
#  my ($rssmark, $site, $username) = CGI::Compress::Gzip::url(-absolute) =~ m{/joule3?0?(-as-rss)?(.*)?};

#  print "And we have:\n$rssmark\n$site\n$username\n\n".CGI::Compress::Gzip::url(-absolute)."\n";

  my %vars= (
    lang => 'en', # fix this properly soon
  );

  $vars{user} = lc(CGI::url_param('user')) || undef;
  $vars{site} = lc(CGI::url_param('site')) || 'lj';
  $vars{name} = "$vars{site}/$vars{user}" if $vars{user};
  $vars{nohiccup} = 1 if CGI::url_param('nohiccup');
  if ($query->url() =~ /-as-rss/ || (CGI::url_param('format') && CGI::url_param('format') eq 'rss')) {
    $vars{format} = 'rss';
    $vars{mimetype} = 'application/rss+xml';
    $vars{absolute} = 'http://marnanel.org';
  } elsif ($query->url() =~ /fbjoule/) {
    $vars{format} = 'fbml';
    $vars{mimetype} = 'application/vnd.fbml';
    $vars{absolute} = 'http://marnanel.org';
  } else {
    $vars{format} = 'html';
    $vars{mimetype} = 'text/html';
    $vars{absolute} = '';
  }
  $vars{limit}=50 unless $vars{format} eq 'html' and CGI::url_param('full');
  if (CGI::url_param('mode') && CGI::url_param('mode') eq 'graph') {
    $vars{graph} = 1;
  } else {
    $vars{graph} = 0;
  }
  $vars{noblanks}=1 if CGI::url_param('noblanks') && !$vars{graph};

  # === THE DATA ===

  if ($vars{user}) {
	  $vars{site} = 'wtf' if $vars{site} !~ /^[a-z]*$/;
	  my $failed = 0;
	  my $status_handler = "From_".uc($vars{site});
	  my $path = "Joule3/Status/$status_handler.pm";
	  my $modname = "Joule3::Status::$status_handler";
	  eval { require $path; };

          if ($@) {
		  warn "$path handler not found";
		  $failed=1;
	  }

	  unless ($failed || $modname->can('site')) {
		  warn "$modname refused to cooperate.";
		  $failed = 1;
	  }

	  if ($failed) {
		  show_error(\%vars, "There is no site with that identifier.");
	  } else {
		  my $status = "Joule3::Status::$status_handler"->new(\%vars);
		  $vars{sitename} = $status->site();

		  my $history = Joule3::History->new($vars{'name'}, $status);

		  $vars{'days'} = [ $history->content(\%vars) ];
	  }
  }

  if ($vars{graph}) {
          require 'Joule3/GraphFitter.pm';
          Joule3::GraphFitter::fit(\%vars);
  }

  if ($vars{format} eq 'html') {
    # Things which only appear in the HTML version:
    require Joule3::Status::All;
    $vars{sites} = { Joule3::Status::All->sites() };

    $vars{rssurl} = $query->self_url();
    $vars{rssurl} =~ s!/joule!/joule-as-rss!;

    require URI::QueryParam;

    my $full = URI->new($query->url(-relative=>1, -query=>1, -path=>1));
    my $graph = $full->clone();
    my $blank = $full->clone();

    if ($vars{limit}) {
	    $full->query_param(full=>1);
    } else {
	    $full->query_param_delete('full');
    }

    if ($vars{graph}) {
	    $graph->query_param_delete('mode');
    } else {
	    $graph->query_param(mode=>'graph');
    }

    if ($vars{noblanks}) {
	    $blank->query_param_delete('noblanks');
    } else {
	    $blank->query_param(noblanks=>1);
    }
    
    $vars{fullurl} = $full->as_string();
    $vars{graphurl} = $graph->as_string();
    $vars{blankurl} = $blank->as_string();
  }

  # === THE TEMPLATE ===

  my $template = Template->new({
      INCLUDE_PATH => '/home/tthurman/proj/web/lib/Marnanel/tmpl/',
      COMPILE_EXT => 'c',
      COMPILE_DIR => '/tmp/joule3',
    }) || die $Template::ERROR;

  die "No template: " unless $template;

  my $output = '';
  $template->process("$vars{format}_main.tmpl", \%vars, \$output) || die $template->error();

  my (undef, undef, undef, $d, $m, $y) = gmtime();
  print $query->header(
	'-Content-Type' => $vars{mimetype},
  	'-Cache-Control' => 'public',
  	'-Expires' => POSIX::strftime($rfc822, 0, 0, 0, $d+1, $m, $y),
  	'-Last-Modified' => POSIX::strftime($rfc822, 0, 0, 0, $d, $m, $y),
  	'-Content-Length' => length($output),
  );

  print $output;
}

1;
