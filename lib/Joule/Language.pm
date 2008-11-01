package Joule::Language;

use strict;
use warnings;

use File::ShareDir;
use Locale::PO;

use Joule::Template;

my %translations;

# I have no idea why Locale::PO leaves in the quotes
sub _unquote {
    my ($str) = @_;
    $str =~ s/\\"/"/g;
    $str =~ s/^"//;
    $str =~ s/"$//;
    return $str;
}

sub _replacement {
    my ($str) = @_;

    return "... $str ...";
}

sub _setup {
    my $podir = File::ShareDir::dist_dir('Joule') . '/po';
    my $keys = Locale::PO->load_file_ashash("$podir/keys.po");

    %translations = (en=>{});
    my %params;

    for my $i (keys %$keys) {
	next unless $i;
	my ($keyword, @params) = split(/\s+/,_unquote($keys->{$i}->msgstr));
	$translations{en}->{$keyword} = $i;
	$params{$keyword} = \@params;
    }

    my $template = Joule::Template::template;

    for my $i (glob("$podir/??.po")) {
	my $po = eval { Locale::PO->load_file_ashash($i) };
	my ($iso639) = $i =~ /\/(..)\.po$/;
	for my $j (keys(%{ $translations{en} })) {
	    next unless $j;
	    use Data::Dumper;
	    die "There is no translation for $j $translations{en}->{$j} in $iso639." unless $po->{$translations{en}->{$j}};
	    my $msgstr = _unquote($po->{$translations{en}->{$j}}->msgstr);

	    for my $param (@{ $params{$j} }) {
		my $replacement;
		if ($param =~ /^\*(.*)$/) {
		    my $filename = "lang_$1.tmpl";
		    $msgstr =~ s/\{([^\}]+)\}/my $a; $template->process($filename, {text => $1}, \$a); $a;/e;
		} else {
		    $msgstr =~ s/\{([^\}]+)\}/<a href="$param">$1<\/a>/;
		}
	    }

	    $translations{$iso639}->{_unquote($j)} = $msgstr;
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

