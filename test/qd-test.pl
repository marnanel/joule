use strict;
use warnings;
use Test::More tests=>7;
use Data::Dumper;
use DBI;
use LWP::UserAgent;
use JSON;

my $settings = do '/etc/joule.conf';
die "Must be run on the staging server" if $settings->{'user'} ne 'stagingjoule';

my $dbh = DBI->connect($settings->{'database'},
		       $settings->{'user'},
		       $settings->{'password'});
ok($dbh, 'connected to the database');
die "no point continuing" unless $dbh;

my $sth;

$sth = $dbh->prepare("DELETE FROM current WHERE userid=?");
$sth->execute('qd/dummy');
$sth = $dbh->prepare("DELETE FROM change WHERE userid=?");
$sth->execute('qd/dummy');
$sth = $dbh->prepare("DELETE FROM checking WHERE userid=?");
$sth->execute('qd/dummy');

ok(1, "cleaned database");

sub db_state {
    my @result;

    my $sth = $dbh->prepare("select fan from current where userid='qd/dummy'");
    $sth->execute();
    @result = (@result, map { $_->[0] } @{ $sth->fetchall_arrayref() } );

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

    ok($res->is_success, 'Touched the webserver to make it fetch');
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

is(db_state(), '', 'initially empty');

set_qd(qw(alpha beta gamma delta));

do_fetch();

is(db_state(), 'alpha beta delta gamma', 'first check has no changes');

set_qd(qw(delta beta epsilon zeta));

age_records();

do_fetch();

is(db_state(), '+epsilon +zeta -alpha -gamma beta delta epsilon zeta', 'second check has changes');

$dbh->disconnect();
