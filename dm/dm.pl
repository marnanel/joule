use strict;
use warnings;
use Net::Twitter;
use Data::Dumper;
use LWP::UserAgent;
use JSON;

my $conf = do '/etc/joule.conf';
my $site = 'tw';
my @auth = @{$conf->{direct}->{$site}};

my $nt = Net::Twitter->new(
    traits   => [qw/API::REST/],
    username => $auth[0],
    password => $auth[1],
    );

# stub for now
sub details_for {
    my ($person) = @_;

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => "http://staging.joule.marnanel.org/json/$site/$person");
    my $res = $ua->request($req);

    return undef unless $res->is_success;

    print $res->content;
    my $j = from_json ($res->content)->{changes}->[0];
    my @changes;

    return 'Welcome to Joule!  Tomorrow you\'ll see the changes from today here.' unless $j;

    for (sort @{$j->{gain}}) {
	push @changes, "+\@$_";
    }

    for (sort @{$j->{lose}}) {
	push @changes, "-\@$_";
    }

    return undef unless @changes;

    for (@changes) { s/\(\?\?.*$/\?/; }

    my $scoreboard = '+'.scalar(@{$j->{gain}}).'-'.scalar(@{$j->{lose}});
    my $url = "http://joule.marnanel.org/chart/$site/$person";
    my $remaining = 140 - (length($scoreboard)+length($url)+2);
    my $more = '';

    while(1) {
	my $length = scalar(@changes);
	for (@changes) { $length += length($_); }
        last if $length <= $remaining;
	shift @changes;

	$remaining -= 5 unless $more;
	$more = 'MORE ';
    }

    for (@changes) { $scoreboard .= " $_"; }

    return "$scoreboard $more$url";
}

sub handle_follower {
    my ($follower) = @_;
    my $message = details_for ($follower);
#    $nt->new_direct_message ($follower, $message);
    print ">> $message\n";
}

my $page = 1;
my $found = 1;
while ($found) {
    my @followers = @{$nt->followers({page=>$page})};
    $page++;
    $found = 0 unless @followers;
    for (@followers) {
	print $_->{screen_name},"\n";
	handle_follower($_->{screen_name});
	#sleep(1);
    }
}


