#    Joule - track changes in an online list over time
#    Copyright (C) 2002-2009 Thomas Thurman
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

################################################################

# This program is called by the installation script and
# creates a file "translate.tmpl" in the templates directory.
# That file is generated code, and should never be checked in.

################################################################

use strict;
use warnings;
use Locale::PO;

print "Creating translations...";

open TRANSLATE, ">share/tmpl/translate.tmpl" or die "Can't open: $!";
print TRANSLATE "[\%# Generated code.  Do not edit.  Do not check in. \%]\n";

my %keynames = map { ($_->msgid or '') => [split(' ',$_->dequote($_->msgstr or ''))] }
@{ Locale::PO->load_file_asarray("po/keys.po") };

delete $keynames{'""'}; # remove the header
delete $keynames{''};

sub make_link {
    my ($target, $text) = @_;

    if ($target =~/^\*(.*)/) {
	return "[\% PROCESS \"lang_$1\" text=\"$text\" \%]";
    } else {
	return "<a href=\"$target\">$text<\/a>";
    }
}

# okay, for English, put in everything; this is the default
for my $v (keys %keynames) {
    my $value = Locale::PO->dequote($v);
    my $i=1;
    $value =~ s/\[(.*?)\]/[% PROCESS "lang_$1" %]/g;
    $value =~ s/{(.*?)}/make_link($keynames{$v}->[$i++] || '???', $1 || '???')/ge;
    print TRANSLATE "[\% t_$keynames{$v}->[0] = BLOCK \%]$value\[\% END \%]\n";
}

my $els = '';

for (sort glob('po/*.po')) {
    next if /keys.po$/;
    my ($iso639) = m!/(.*)\.po!;
    print " $iso639";

    print TRANSLATE "\n[\% ${els}IF lang==\"$iso639\" \%]\n";

    my $po = Locale::PO->load_file_ashash($_);
    delete $po->{'""'};
    delete $po->{''};
    
    for my $v (keys %keynames) {
	my $value = Locale::PO->dequote($po->{$v}->msgstr);

	die "Value has [% already in it" if $value =~ /\[%/;

	my $i=1;
	$value =~ s/\[(.*?)\]/[% PROCESS "lang_$1" %]/g;
	$value =~ s/{(.*?)}/make_link($keynames{$v}->[$i++] || '???', $1 || '???')/ge;
	print TRANSLATE "[\% t_$keynames{$v}->[0] = BLOCK \%]$value\[\% END \%]\n";
    }

    $els = 'ELS';
}

print TRANSLATE "[\% END \%]\n" if $els;

print TRANSLATE "[\%# eof translate.tmpl \%]\n";

close TRANSLATE or die "Can't close: $!";

print " done.\n";
