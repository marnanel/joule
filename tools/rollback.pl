use strict;
use warnings;
use Data::Dumper;
use DBI;
use LWP::UserAgent;
use JSON;
use Time::HiRes qw(time); # no, not clock, we're testing another process

my $usertype = 'lj/%';
my $date = '2009-05-03';

my $settings = do '/etc/joule.conf';

my $dbh = DBI->connect($settings->{'database'},
		       $settings->{'user'},
		       $settings->{'password'});
die "no db connection" unless $dbh;

my $sth;

$sth = $dbh->prepare("select * from checking where userid like ? and datestamp=?;");
$sth->execute($usertype, $date);
my $result = $sth->fetchall_arrayref;

my $count=0;

for (@$result) {

    print "$count / ",scalar(@$result),"\n" if ($count%100)==0;
    $count++;

    my $name = $_->[0];

    $sth = $dbh->prepare("select fan, added from change where userid=? and datestamp=?;");
    $sth->execute($name, $date);
    my $changes = $sth->fetchall_arrayref;

    for my $change (@$changes) {

	if ($change->[1]) {
	    $sth = $dbh->prepare("DELETE FROM current WHERE userid=? AND fan=?");
	    $sth->execute($name, $change->[0]);
	} else {
	    $sth = $dbh->prepare("INSERT INTO current (userid, fan) VALUES (?,?)");
	    $sth->execute($name, $change->[0]);
	}
    }

    $sth = $dbh->prepare("DELETE FROM change WHERE userid=? and datestamp=?");
    $sth->execute($name, $date);

}

$sth = $dbh->prepare("DELETE FROM checking WHERE userid like ? and datestamp=?");
$sth->execute($usertype, $date);

$dbh->commit();
