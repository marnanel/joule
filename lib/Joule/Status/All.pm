package Joule3::Status::All;

use strict;
use warnings;

sub _name_of_site {
  my ($site) = @_;
  ($site) = $site =~ /(Joule3.*)$/;
  require $site;
  $site =~ s!/!::!g;
  $site =~ s/\.pm$//g;
  return $site->site();
}

sub sites {
  return map { lc (($_ =~ /From_(..)/)[0]) => _name_of_site($_) } glob($INC[0].'/Joule3/Status/From_*.pm');
}

1;
