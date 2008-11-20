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

package Joule::Status::From_IJ;

use strict;
use warnings;
use Joule::Status::GoatScraper;
use Data::Dumper;

our @ISA=qw(Joule::Status::GoatScraper); # We are a goatscraper

# sub site { "InsaneJournal"; }
sub url { my ($self,$name)=@_; "http://$name.insanejournal.com/profile?mode=full"; }
sub tablenumber { 0; }
sub get_username {
        my ($self, $link) = @_;
        $link->[0] =~ /http:\/\/([a-z0-9_-]+)\.insanejournal/;
        return $1;
}


1;

