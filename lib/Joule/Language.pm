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

package Joule::Language;

# This would be much easier if we used .tmpl files for translations.

use strict;
use warnings;

use File::ShareDir;
use Locale::PO;
use IP::Country::DNSBL;
use Apache2::Connection;

use Joule::Template;
use Joule::Cookie;

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

sub _dynamic_template {
    my ($field, $template, $vars) = @_;
    my $result;
    $template->process("lang_$field.tmpl", $vars, \$result);
    return $result;
}

my %languages_in_countries = (
			      DE => 'de', # German in Germany
			      AT => 'de', # German in Austria
			      RU => 'ru', # Russian in Russia
			      SU => 'ru', # Russian in very old computers in Russia
			      );

my $geolocation = IP::Country::DNSBL->new();

sub _user_language {

    my ($r) = @_;

    # If they have a cookie, that always wins.
    my $cookie = Joule::Cookie::lang($r);
    return $cookie if $cookie and is_language($cookie);

    # Else, check Accept-Language.

    # Else, guess via languages_in_countries

    my $country = $geolocation->inet_atocc($r->connection->remote_ip);
    return $languages_in_countries{$country} if $languages_in_countries{$country};

    # Else give up and use English.
    return 'en';
}

sub strings {
    my ($r, $vars) = @_;

    my $template = Joule::Template::template;
    my $language = _user_language($r);
    my %result;

    for (keys %{$translations{$language}}) {
	my $str = $translations{$language}->{$_};
	$str =~ s/\[([A-Z]+)\]/_dynamic_template($1, $template, $vars)/ge;
	$result{$_} = $str;
    }

    $result{'LANGS'} = [];
    for (sort keys %translations) {
	push @{$result{'LANGS'}}, {
	    name => $translations{$_}->{lang},
	    code => $_,
	    current => ($language eq $_),
	};
    }

    return \%result;
}

_setup;

1;

