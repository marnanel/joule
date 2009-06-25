use strict;
use warnings;
use Joule;

my $count = 7;
my %set;
my $running = 1;

my %acceptable = map {$_=>1} qw(00 11 22 23 32 33);

sub dumpset {
    for (sort keys %set) {
	print "$set{$_}-$_ ";
    }
    print "... ";
}

sub build_string {
    my (%allow) = map {$_=>1} @_;
    return join("\n", grep { $allow{$set{$_}} } sort keys %set);
}

sub runtest {
    my %result = map { $_ => 3 } keys(%set);
    Joule::raisin_compare(
	build_string(0, 2),
	build_string(1, 2),
	sub {
	    my ($dir, $name) = @_;
	    $result{$name} = $dir;
	});

    for (keys %result) {
	my $want = $set{$_};
	my $got = $result{$_};
	next if $acceptable{"$want$got"};
	die "FAIL\n";
    }
    print "pass.\n";
}

sub increment {
    my $carry = 1;
    for (sort keys %set) {
	$set{$_} += $carry;
	if ($set{$_}==4) {
	    $set{$_} = 0;
	    $carry = 1;
	} else {
	    $carry = 0;
	}
    }
    $running = 0 if $carry;
}

for (my $i=0; $i<$count; $i++) {
    $set{int(rand(10000000))} = 0;
}

while ($running) {
    dumpset();
    runtest();
    increment();
}
