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

# This is a general package which knows how to screen-scrape
# LiveJournal derivatives when no other source of data can be
# found.  It should not be put into general use without permission
# from the site admins.

package Joule::Status::GoatScraper;

use strict;
use warnings;
use LWP::UserAgent;
use HTML::TreeBuilder;
use Data::Dumper;

sub new {
    my ($class, $vars) = @_;

    bless \($vars->{user}), $class;
}

# Override sub site() if you want it to appear in the main menu list
sub url { die "You must override ::url() with the URL."; }

sub tablenumber { 2; }

sub get_username {
	my ($self, $link) = @_;
	$link->[0] =~ /users\/([a-z0-9_-]+)\/profile/;
	return $1;
}

sub names {
    my ($self) = @_;
    my $ua = LWP::UserAgent->new();
    $ua->agent("Joule/3.0 (http://marnanel.org/joule; thomas\@thurman.org.uk)");

    my $req = HTTP::Request->new(GET=>$self->url($$self));
    my $res = $ua->request($req);

    die __PACKAGE__ . ' error: ' . $res->status_line() unless $res->is_success();

    my $tree = HTML::TreeBuilder->new();
    $tree->parse($res->content());
    $tree->eof();

    my @result;
    my $body = $tree->find('body');
    my @tables = $body->find('table');
    for my $row ($tables[$self->tablenumber]->find('tr')) {
	    my $header = $row->find('td');
	    if ($header->as_HTML =~ /Friend of/i) {
		    @result = (map{ $self->get_username($_) } @{ $header->right->extract_links });
                    last;
	    }
    }
    $tree = $tree->delete;

    return \@result;
}

1;

