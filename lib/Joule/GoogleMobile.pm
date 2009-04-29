package Joule::GoogleMobile;

use LWP::UserAgent;
use Time::HiRes qw(gettimeofday);
use URI::Escape;

sub google_append_color {
    my @color_array = split(/,/, $_[0]);
    return $color_array[$_[1] % @color_array];
}

sub google_append_screen_res {
    my $screen_res = $ENV{"HTTP_UA_PIXELS"};
    my $delimiter = "x";
    if ($screen_res == "") {
	$screen_res = $ENV{"HTTP_X_UP_DEVCAP_SCREENPIXELS"};
	$delimiter = ",";
    }
    my @res_array = split($delimiter, $screen_res);
    if (@res_array == 2) {
	return "&u_w=" . $res_array[0] . "&u_h=" . $res_array[1];
    }
}

sub google_append_dcmguid {
    my $dcmguid = $ENV{"HTTP_X_DCMGUID"};
    if ($dcmguid) {
	return "&dcmguid=" . $dcmguid;
    }
}

sub mobile_ads {
    my $google_dt = sprintf("%.0f", 1000 * gettimeofday());
    my $google_scheme = ($ENV{"HTTPS"} eq "on") ? "https://" : "http://";
    my $google_host = uri_escape($google_scheme . $ENV{"HTTP_HOST"});

    my $google_ad_url = "http://pagead2.googlesyndication.com/pagead/ads?" .
	"ad_type=text_image" .
	"&channel=2261048737" .
	"&client=ca-mb-pub-3773406468555371" .
	"&dt=" . $google_dt .
	"&format=mobile_single" .
	"&host=" . $google_host .
	"&ip=" . uri_escape($ENV{"REMOTE_ADDR"}) .
	"&markup=xhtml" .
	"&oe=utf8" .
	"&output=xhtml" .
	"&ref=" . uri_escape($ENV{"HTTP_REFERER"}) .
	"&url=" . $google_host . uri_escape($ENV{"REQUEST_URI"}) .
	"&useragent=" . uri_escape($ENV{"HTTP_USER_AGENT"}) .
	google_append_screen_res() .
	google_append_dcmguid();
    
    my $google_ua = LWP::UserAgent->new;
    my $google_ad_output = $google_ua->get($google_ad_url);
    if ($google_ad_output->is_success) {
	return $google_ad_output->content;
    }
}

sub mobile_details {
    my ($r) = @_;

    return () unless $r->hostname =~ /^m\./;

    return (
	mobile => 1,
	mobileads => mobile_ads,
	);
}

1;
