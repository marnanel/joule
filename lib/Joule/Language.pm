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
use IP::Country::DNSBL;
use Apache2::Connection;

use Joule::Template;
use Joule::Cookie;

# fixme: this should be a space-separated field in the po file itself
my %languages_in_countries = (
			      DE => 'de', # German in Germany
			      AT => 'de', # German in Austria
			      RU => 'ru', # Russian in Russia
			      SU => 'ru', # Russian in very old computers in Russia
			      IL => 'he', # Hebrew in Israel
                              NL => 'nl', # Dutch in the Netherlands
                              FR => 'fr', # French in France
			      );

my $geolocation = IP::Country::DNSBL->new();

sub user_language {

    my ($r) = @_;

    # If they have a cookie, that always wins.
    my $cookie = Joule::Cookie::lang($r);
    return $cookie if $cookie;

    # Else, check Accept-Language.

    # Else, guess via languages_in_countries

    my $country = $geolocation->inet_atocc($r->connection->remote_ip);
    return $languages_in_countries{$country} if $country && $languages_in_countries{$country};

    # Else give up and use English.
    return 'en';
}

1;

