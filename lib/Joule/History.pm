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

package Joule::History;

use strict;
use warnings;
use DBI;
use POSIX qw(strftime);

sub new {
    my ($class, $username, $status) = @_;

    my $settings = do '/etc/joule.conf';
    my $dbh = DBI->connect($settings->{'database'},
			   $settings->{'user'},
			   $settings->{'password'},
			   { RaiseError => 1, AutoCommit => 1, });

    my $result = {
        status => $status,
        dbh => $dbh,
        userid => $username,
    };

    bless $result, $class;
}

sub current {
    my ($self) = @_;

    my $sth = $self->{dbh}->prepare('SELECT fan FROM current WHERE userid=?');

    $sth->execute($self->{userid});

    return map { $_->[0] } @{ $sth->fetchall_arrayref() };
}

sub content {
    my ($self, $opts) = @_;

    # Firstly, check whether we need to poll the site.

    my $experienced = $self->{dbh}->prepare('SELECT COUNT(datestamp) FROM checking WHERE userid=? AND datestamp!=CURRENT_DATE LIMIT 1');
    $experienced->execute($self->{userid});
    $opts->{virgin} = 1 if !$experienced->fetchrow() && !$self->current();

    my $done_today = $self->{dbh}->prepare("SELECT COUNT(datestamp) FROM checking WHERE userid=? AND datestamp=CURRENT_DATE LIMIT 1");
    $done_today->execute($self->{userid});

    if ($done_today->fetchrow()) {

       if ($opts->{virgin}) {
         $opts->{current_names} = [ $self->{'status'}->names() ];
         return ();
       }

    } else {
       # it hasn't been done today

       $self->{dbh}->begin_work();

       my @newfetch = $self->{'status'}->names();

       $opts->{lonely} = 1 unless @newfetch;
       return () if $opts->{lonely} and $opts->{virgin}; # because we don't know for sure it exists at all

       my $sth = $self->{dbh}->prepare("SELECT COUNT(*) FROM account WHERE userid=?");
       $sth->execute($self->{userid});
       unless ($sth->fetchrow()) {
          $sth = $self->{dbh}->prepare("INSERT INTO account VALUES (?)");
          $sth->execute($self->{userid});
       }

       my $adder = $self->{dbh}->prepare("INSERT INTO checking(userid, datestamp) VALUES (?, CURRENT_DATE)");
       $adder->execute($self->{userid});

       my $current_add = $self->{dbh}->prepare("INSERT INTO current(userid, fan) VALUES (?,?)");
       if ($opts->{virgin}) {
	       $opts->{virgin} = 1;
	       $opts->{current_names} = \@newfetch;

               for (@newfetch) {
                  $current_add->execute($self->{userid}, $_);
               }

       } else {
	       my @latest = $self->current();

	       my $adder = $self->{dbh}->prepare("INSERT INTO change(userid, datestamp, fan, added) VALUES (?,CURRENT_DATE,?,?)");
	       my $current_del = $self->{dbh}->prepare("DELETE FROM current WHERE userid=? AND fan=?");

               # Deltas are not stored for virgin accounts (otherwise it shows a mass friending first)
	       for (_subtract( \@newfetch, \@latest )) {
		       $adder->execute($self->{userid}, $_, 1);
		       $current_add->execute($self->{userid}, $_);
	       }

	       for (_subtract( \@latest, \@newfetch )) {
		       $adder->execute($self->{userid}, $_, 0);
		       $current_del->execute($self->{userid}, $_);
	       }
       }

       # Aaaaand... commit.
       $self->{dbh}->commit();

       # There's no more useful information to return on virgin accounts.
       return () if $opts->{virgin};
    }

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

    my $sth = $self->{dbh}->prepare($query);

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

sub _subtract {
	my ($left, $right) = @_;

	my @left = @$left;
	my @right = @$right;

	my %right_index = map { $_ => 1 } @right;

	return grep { !$right_index{$_} } @$left;
}

sub DESTROY {
	my ($self) = @_;
	$self->{dbh}->disconnect();
}

1;
