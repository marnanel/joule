package Joule::GraphFitter;

use strict;
use warnings;
use POSIX qw(mktime strftime ceil);
use Digest::MD5 qw(md5_hex);

my $throttle = 0;

sub _pick_a_line {
	my ($ranges, $first, $last) = @_;

	for my $candidate (keys %$ranges) {
		# $candidate is the user we're considering
		my @k = sort(keys(%{$ranges->{$candidate}}));
		# @k is the dates this user has been active

		if (
			(!$first || ($k[0] gt $first && $ranges->{$candidate}->{$k[0]}==0)) &&
			(!$last || ($k[-1] lt $last && $ranges->{$candidate}->{$k[-1]}==1))
		) {

			# looks like we have a line, folks, and at least this candidate goes on it
			my @result = ($candidate);

			$throttle++;
			return (undef) if $throttle == 10;

			# can we fit anything around it?
			@result = (_pick_a_line($ranges, $first, $k[0]), @result)
				if $ranges->{$candidate}->{$k[0]} == 0;
			@result = (@result, _pick_a_line($ranges, $k[-1], $last))
				if $ranges->{$candidate}->{$k[-1]} == 1;

			$throttle--;

			return @result;
		}
	}

	return (); # give up
}

sub _line_detail {
	# stub
	my ($whether, $place, $current, $fan) = @_;

	return if $place==$current; # zero-width makes no sense
	my %result = (width=>($place-$current));

	%result = (
		%result,
		name => $fan,
		colour => substr(md5_hex($fan), -6),
	) if $whether;

	return \%result;
}

sub _date_to_int {
	my ($date) = @_;

	my ($y, $m, $d) = $date =~ /^(....)-(..)-(..)$/;

	# note that this doesn't handle timezones correctly; it is always
	# expressed in local time and not UTC. but that is okay because
	# we need this value for arithmetic, not as an absolute value.
	# (oh, and in generating labels, but there we use localtime() anyway.)
	return POSIX::ceil(POSIX::mktime(0, 0, 0, $d, $m-1, $y-1900)/86400);
}

sub _draw_line {
	my ($ranges, $days, $candidates) = @_;

	my $current = _date_to_int($days->[-1]->{date});
	my @result;

	for my $friend (@$candidates) {
		for my $place (sort(keys(%{$ranges->{$friend}}))) {
			push @result, _line_detail($ranges->{$friend}->{$place},
						$place, $current, $friend);
			$current = $place;
		}
	}

	my $final = $candidates->[-1];
	push @result, _line_detail(!($ranges->{$final}->{$current}),
		_date_to_int($days->[0]->{date})+1, $current, $final);

	return @result;
}

sub fit {
	my ($vars) = @_;

	# Set up ranges:

	$throttle = 0;

	my %ranges;

	for my $day (@{$vars->{days}}) {
		for my $dir qw(friended unfriended) {
			for my $person (@{$day->{$dir}}) {
				$ranges{$person}->{_date_to_int($day->{date})} = ($dir eq 'unfriended');
			}
		}
	}

	# %ranges is now a mapping of USERNAME -> DATE -> 0 for friended, 1 for unfriended

	$vars->{graphdata} = [];
	while(1) {
		my @candidates = _pick_a_line(\%ranges, '', '');
		last unless @candidates;

		unless (defined $candidates[0]) {
			$vars->{grapherror} = 1;
			return;
		}

		push @{$vars->{graphdata}}, [ _draw_line(\%ranges, $vars->{days}, \@candidates) ];

		for (@candidates) { delete $ranges{$_}; }
	}

	# Set up header ranges
	$vars->{graphdays} = [];
	my $prevmonth = '';
	for (my $i=_date_to_int($vars->{days}->[-1]->{date}); $i<=_date_to_int($vars->{days}->[0]->{date}); $i++) {
		my @day = localtime($i*86400);
		my $date = strftime("%02d", @day);
		my $month = strftime("<br>%b<br>%y", @day);
		if ($month ne $prevmonth) {
			$date .= $month;
			$prevmonth = $month;
		}
		push @{$vars->{graphdays}}, $date;
	}

#	use Data::Dumper; $vars->{graphdump} = Dumper($vars->{graphdata});
}

1;

