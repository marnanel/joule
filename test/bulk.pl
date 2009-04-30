use strict;
use warnings;
use Data::Dumper;
use DBI;
use LWP::UserAgent;
use JSON;
use Time::HiRes qw(time); # no, not clock, we're testing another process

my $settings = do '/etc/joule.conf';
die "Must be run on the staging server" if $settings->{'user'} ne 'stagingjoule';

my $dbh = DBI->connect($settings->{'database'},
		       $settings->{'user'},
		       $settings->{'password'});
die "no db connection" unless $dbh;

my $sth;

$sth = $dbh->prepare("DELETE FROM current WHERE userid=?");
$sth->execute('qd/dummy');
$sth = $dbh->prepare("DELETE FROM change WHERE userid=?");
$sth->execute('qd/dummy');
$sth = $dbh->prepare("DELETE FROM checking WHERE userid=?");
$sth->execute('qd/dummy');

sub db_state {
    my @result;

    $sth = $dbh->prepare("select fan from change where userid='qd/dummy' and added");
    $sth->execute();
    @result = (@result, map { '+'.$_->[0] } @{ $sth->fetchall_arrayref() } );

    $sth = $dbh->prepare("select fan from change where userid='qd/dummy' and not added");
    $sth->execute();
    @result = (@result, map { '-'.$_->[0] } @{ $sth->fetchall_arrayref() } );

    return join(' ', sort @result);
}

sub set_qd {
    open JSON, '>/tmp/joule.qd.json' or die "Can't open: $!";
    print JSON to_json(\@_);
    close JSON or die "Can't close!";
}

sub do_fetch {

    my $ua = LWP::UserAgent->new;

    my $req = HTTP::Request->new(GET => 'http://staging.joule.marnanel.org/chart/qd/dummy');
    my $res = $ua->request($req);

    die $res->status_line unless $res->is_success;
}

sub age_records {
    my $sth = $dbh->prepare('INSERT INTO checking (userid, datestamp) VALUES (?,?)');
    $sth->execute('qd/dummy', '1975-01-30');
    $sth = $dbh->prepare('UPDATE change SET datestamp=? WHERE userid=?');
    $sth->execute('1975-01-30', 'qd/dummy');
    $sth = $dbh->prepare('DELETE FROM checking WHERE userid=? AND datestamp!=?');
    $sth->execute('qd/dummy', '1975-01-30');    
}

die "Please give the number of records we're testing" unless scalar(@ARGV);
die "Must be at least 4" unless $ARGV[0]>3;

print "Preparing.\n";
my @testset;
for (my $i=2; $i<$ARGV[0]+2; $i++) { push @testset, $i; }

set_qd(@testset);

print "Fetching.\n";
my $clock;
$clock = time();
do_fetch();
die "Unexpected diffs" unless db_state() eq '';

my $firstpass = time()-$clock;
print "First pass took: $firstpass\n";

@testset = (0, 1, @testset[2..$#testset]);
set_qd(@testset);

age_records();

$clock = time();
do_fetch();
die "Unexpected diffs" unless db_state() eq '+0 +1 -2 -3';

my $secondpass = time()-$clock;
print "Second pass took: $secondpass\n";

print "Total time is: ",$firstpass+$secondpass,"\n";

$dbh->disconnect();

print "Everything was fine.  Speed is about ",int($ARGV[0]/$firstpass)," rows/sec.\n";
