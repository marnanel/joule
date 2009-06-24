#    Joule - track changes in an online list over time
#    Copyright (C) 2002-2009 Thomas Thurman
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

package Joule::History;

use strict;
use warnings;
use DBI;
use POSIX qw(strftime);
use Joule::Database;
use Joule;

sub new {
    my ($class, $username, $status) = @_;

    my $result = {
        status => $status,
        userid => $username,
    };

    bless $result, $class;
}

sub _build_raisin_from_current {
    my ($dbh, $name) = @_;
    my $result = '';

    my $sth = $dbh->prepare('SELECT fan FROM current WHERE userid=? ORDER BY fan');
    $sth->execute($name);
    while (my $f = $sth->fetchrow_array()) {
	if ($result) {
	    $result .= "\n$f";
	} else {
	    $result = $f;
	}
    }
    return $result;
}

sub content {
    my ($self, $opts) = @_;

    my $dbh = Joule::Database::handle();

    # Firstly, check whether we need to poll the site.

    my $sth;

    $sth = $dbh->prepare('SELECT COUNT(datestamp) FROM checking WHERE userid=? AND datestamp!=CURRENT_DATE LIMIT 1');
    $sth->execute($self->{userid});
    $opts->{virgin} = 1 if !$sth->fetchrow();

    $sth = $dbh->prepare("SELECT COUNT(datestamp) FROM checking WHERE userid=? AND datestamp=CURRENT_DATE LIMIT 1");
    $sth->execute($self->{userid});

    unless ($sth->fetchrow()) {

       # it hasn't been done today

       $sth = $dbh->prepare("SELECT current_date");
       $sth->execute();
       my ($today) = $sth->fetchrow_array();

       my @raisin_tmp;

       # FIXME: This is inefficient but rewriting it will
       # mean a change to every one of the status handlers;
       # do this later
       $self->{'status'}->names(sub {
	   push @raisin_tmp, shift;
				});

       my $raisin_is = join("\n", sort @raisin_tmp);
       undef @raisin_tmp;

       $opts->{lonely} = 1 unless $raisin_is;

       # FIXME: This is wrong: the status handler should
       # tell us whether something doesn't exist at all.
       # (This currently assumes that everything works like LJ.)
       return () if $opts->{lonely} and $opts->{virgin}; # because we don't know for sure it exists at all

       $sth = $dbh->prepare("SELECT 1, state FROM account WHERE userid=?");
       $sth->execute($self->{userid});
       my ($exists, $raisin_was) = $sth->fetchrow_array();
       if ($exists) {

	   if (!defined $raisin_was) {
	       # No raisin information; possibly we have to build it from current.
	       $raisin_was = _build_raisin_from_current($dbh, $self->{userid});
	   }

       } else {
	   # Doesn't exist yet; this is a new account, so create it
	   $sth = $dbh->prepare("INSERT INTO account VALUES (?, '')");
	   $sth->execute($self->{userid});
       }

       my $adder = $dbh->prepare("INSERT INTO checking(userid, datestamp) VALUES (?, ?)");
       $adder->execute($self->{userid}, $today);

       unless ($opts->{virgin}) {

	   # Deltas are not stored for virgin accounts
	   # (otherwise it shows a mass friending first)

	   $sth = $dbh->prepare(
	       "insert into change(userid,datestamp,fan,added) ".
	       "values (?, ?, ?, ?)"
	       );
	   Joule::raisin_compare(
	       $raisin_was,
	       $raisin_is,
	       sub {
		   my ($added, $name) = @_;
		   $sth->execute($self->{userid}, $today, $name, $added);
	       });

       }

       # Save it for next time.
       $sth = $dbh->prepare(
	   "update account set state=? where userid=?"
	   );
       $sth->execute($raisin_is, $self->{userid});

       # Aaaaand... commit.
       $dbh->commit();
    }

    # There's no more useful information to return on virgin accounts.
    return () if $opts->{virgin};

    my $query;
    if ($opts->{'noblanks'}) { # noblanks version is much simpler
	    my $where_limit = '';
	    $where_limit = ' AND datestamp >= DATE(CURRENT_DATE - 30)' if $opts->{'limit'};

	    $query = 'SELECT datestamp, fan, added FROM change'.
		    ' WHERE userid=?'.
		    $where_limit.
		    ' ORDER BY datestamp DESC';
    } else {
	    my $where_limit = '';
	    $where_limit = ' AND checking.datestamp >= DATE(CURRENT_DATE - 30)' if $opts->{'limit'};

	    $query = 'SELECT checking.datestamp, change.fan, change.added '.
		    'FROM checking LEFT JOIN change ON '.
		    '(checking.datestamp = change.datestamp and '.
				    'checking.userid = change.userid)'.
		    ' WHERE checking.userid=? '.
		    $where_limit.
		    ' ORDER BY checking.datestamp DESC';
    }

    $sth = $dbh->prepare($query);
    $sth->execute($self->{userid});

    my %results;

    for my $record (@{ $sth->fetchall_arrayref() }) {
	    if (defined $record->[1]) {
		    if ($record->[2]) {
			    push @{ $results{$record->[0]}->{'friended'} }, $record->[1];
		    } else {
			    push @{ $results{$record->[0]}->{'unfriended'} }, $record->[1];
		    }
	    } else { # not defined, which can only happen if not noblanks
		    $results{$record->[0]} = {friended=>undef, unfriended=>undef};
	    }
    }

    my @result;

    for (reverse sort keys %results) {
	    $results{$_}->{date} = $_;

	    # TODO: remove this in a month.  it's a temporary workaround for
	    # an infelicity of Template::Toolkit.
	    $results{$_}->{temp_rss_fix} = $_ gt '2009-06-04';

	    push @result, $results{$_};
    }

    return @result;
}

1;
