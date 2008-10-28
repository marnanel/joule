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
