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
  name           'Joule';

  abstract       'Records differences over time in the readership of a journal';
  author         'Thomas Thurman <tthurman@gnome.org>';
  version        '3.02';  
  license        'affero';

  requires 'Apache2::Connection';
  requires 'Apache2::Const';
  requires 'Apache2::Cookie';
  requires 'Apache2::Request';
  requires 'APR::Table';
  requires 'CGI::Cookie';
  requires 'CGI';
  requires 'Config';
  requires 'Cwd';
  requires 'Data::Dumper';
  requires 'DBI';
  requires 'Digest::MD5';
  requires 'File::Find';
  requires 'File::Path';
  requires 'File::ShareDir';
  requires 'File::Spec';
  requires 'FindBin';
  requires 'HTML::TreeBuilder';
  requires 'IP::Country::DNSBL';
  requires 'JSON';
  requires 'Locale::PO';
  requires 'LWP::UserAgent';
  requires 'Module::Install::Base';
  requires 'Perl6::Slurp';
  requires 'POSIX';
  requires 'Template';
  requires 'Time::HiRes';
  requires 'URI::Escape';

do "translate.pl";
  
  install_share unless $ENV{NOSHARE};

  WriteAll;
