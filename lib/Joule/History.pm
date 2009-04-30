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

sub new {
    my ($class, $username, $status) = @_;

    my $result = {
        status => $status,
        userid => $username,
    };

    bless $result, $class;
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

       $sth = $dbh->prepare("SELECT nextval('snapid'), current_date");
       $sth->execute();
       my ($snap, $today) = $sth->fetchrow_array();
       my $name_count = 0;

       $sth = $dbh->prepare('INSERT INTO snapshot (snap, name) VALUES (?,?)');

       # FIXME: Can this be more efficient?
       $self->{'status'}->names(sub {
	   $name_count++;
	   $sth->execute($snap, shift);
				});

       $opts->{lonely} = 1 unless $name_count;
       return () if $opts->{lonely} and $opts->{virgin}; # because we don't know for sure it exists at all

       $sth = $dbh->prepare("SELECT COUNT(*) FROM account WHERE userid=? LIMIT 1");
       $sth->execute($self->{userid});
       unless ($sth->fetchrow()) {
	   $sth = $dbh->prepare("INSERT INTO account VALUES (?)");
	   $sth->execute($self->{userid});
       }

       my $adder = $dbh->prepare("INSERT INTO checking(userid, datestamp) VALUES (?, ?)");
       $adder->execute($self->{userid}, $today);

       if ($opts->{virgin}) {

	   $opts->{virgin} = 1;

	   $sth = $dbh->prepare(
	       "insert into current (userid, fan) ".
	       "select ?, name from snapshot where snap=?");
	   $sth->execute($self->{userid}, $snap);

       } else {

	   # Deltas are not stored for virgin accounts
	   # (otherwise it shows a mass friending first)

	   $sth = $dbh->prepare(
	       "insert into change(userid,datestamp,fan,added) ".
	       "select ?, ?, name, true ".
	       "from snapshot where snap=? and name not in ".
	       "(select fan from current where userid=?)");
	   $sth->execute($self->{userid}, $today, $snap, $self->{userid});

	   $sth = $dbh->prepare(
	       "insert into change(userid,datestamp,fan,added) ".
	       "select ?, ?, fan, false ".
	       "from current where userid=? and fan not in ".
	       "(select name from snapshot where snap=?) and userid=?");
	   $sth->execute($self->{userid}, $today, $self->{userid}, $snap, $self->{userid});

	   $sth = $dbh->prepare(
	       "insert into current select userid, fan from change ".
	       "where userid=? and datestamp=? and added");
	   $sth->execute($self->{userid}, $today);

	   $sth = $dbh->prepare(
	       "delete from current where userid=? ".
	       "and fan in (select fan from change where ".
	       "userid=? and datestamp=? and not added)");
	   $sth->execute($self->{userid}, $self->{userid}, $today);
       }

       $sth = $dbh->prepare('delete from snapshot where snap=?');
       $sth->execute($snap);

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
            if ($opts->{format} && $opts->{format} eq 'rss') {
              # FIXME: would like to do this in the template with a filter
              my ($y, $m, $d) = $_ =~ /^(....)-(..)-(..)$/;
              $results{$_}->{rfc822date} = POSIX::strftime(
                '%a, %d %b %Y 00:00:00 GMT',
                0, 0, 0, $d, $m-1, $y-1900,
                );
            }
	    push @result, $results{$_};
    }

    return @result;
}

1;
