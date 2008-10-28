  use inc::Module::Install;
  
  # Define metadata
  if ($ENV{STAGING}) {
	  name           'StagingJoule';
  } else {
	  name           'Joule';
  } 
  all_from       'lib/Joule/ModPerl.pm';
  abstract       'Records differences over time in the readership of a journal';
  author         'Thomas Thurman <tthurman@gnome.org>';
  version        '3.01';  
  license        'affero';

  requires 'Data::Dumper';
  requires 'Template';

  # Can we tell where files are going and look for a no-clobber.txt?
  
  install_share unless $ENV{NOSHARE};

  WriteAll;
