package Joule::Language;

use strict;
use warnings;

use File::ShareDir;
use Locale::PO;

my %translations;

# I have no idea why Locale::PO leaves in the quotes
sub _unquote {
	my ($str) = @_;
	$str =~ s/\\"/"/g;
	$str =~ s/^"//;
	$str =~ s/"$//;
	return $str;
}

sub _setup {
    my $podir = File::ShareDir::dist_dir('Joule') . '/po';
    my $keys = Locale::PO->load_file_ashash("$podir/keys.po");

    %translations = (en=>{});

    for my $i (keys %$keys) {
	next unless $i;
	my ($keyword, @params) = split(/\s+/,_unquote($keys->{$i}->msgstr));
	$translations{en}->{$keyword} = $i;
    }

    for my $i (glob("$podir/??.po")) {
	my $po = eval { Locale::PO->load_file_ashash($i) };
	my ($iso639) = $i =~ /\/(..)\.po$/;
	for my $j (keys(%{ $translations{en} })) {
	    next unless $j;
	    use Data::Dumper;
	    die "There is no translation for $j $translations{en}->{$j} in $iso639." unless $po->{$translations{en}->{$j}};
	    $translations{$iso639}->{_unquote($j)} = _unquote($po->{$translations{en}->{$j}}->msgstr);
	}
    }

    # we needed to have the English values quoted so they could be
    # found in the hash; it's safe to unquote them now

    for my $i (keys %{$translations{en}}) {
	next unless $i;
	$translations{en}->{$i} = _unquote($translations{en}->{$i});
    }
}

sub is_language {
    my ($code) = @_;

    return 0 unless $code =~ /^[a-z]+$/;

    return -e File::ShareDir::dist_dir('Joule') . "/po/$code.po";
}

sub strings {
    my ($r) = @_;

    return $translations{de};
}

_setup;

1;

