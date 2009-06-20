var joule_prefs = Components.classes["@mozilla.org/preferences-service;1"]
    .getService(Components.interfaces.nsIPrefService).getBranch("extensions.joule.");
var joule_timer = Components.classes["@mozilla.org/timer;1"]
    .createInstance(Components.interfaces.nsITimer);
var joule_notify = function() { };
var joule_previous_day = '';
var joule_previous_username = '';

function joule_doc() {
    if (document.getElementById('joule-text'))
	return document;
    if (window.opener &&
	window.opener.document.getElementById('joule-text'))
	return window.opener.document;
    if (window.opener.opener &&
	window.opener.opener.document.getElementById('joule-text'))
	return window.opener.opener.document;
    alert('cannot find document.');
}

function joule_set_busyness(how) {
    var busy = how? 'news':'calm';

    joule_doc().getElementById('joule-icon').setAttribute('mystate', busy);
    joule_doc().getElementById('joule-text').setAttribute('mystate', busy);
}

function joule_display(text) {
    joule_doc().getElementById('joule-text').setAttribute('label', text);
}

function joule_username() {
    return joule_prefs.getCharPref('site')+'/'+joule_prefs.getCharPref('name');
}

function joule_update_statusbar_cb() {
    if(this.readyState != 4) return;

    if (this.status == 200 && this.responseText.indexOf('<')==-1) {
	if (this.responseText==' +0,-0') {
	    joule_display('monitoring');
	} else {
	    var a = this.responseText.split(' ');
	    joule_display(a[1]);

	    if (joule_previous_day != a[0]) {
		joule_set_busyness(a[1] != '+0,-0');
		joule_previous_day = a[0];
	    }
	}
    } else {
	joule_display('error');
    }
}

function joule_update_statusbar() {
    var c = new XMLHttpRequest();
    var username = joule_username();
    c.onreadystatechange = joule_update_statusbar_cb;
    c.open('GET', "http://joule.marnanel.org/text/"+username);
    c.send('');
    joule_previous_username = username;
}

function go_to_joule() {
    var username = joule_username();

    if (joule_previous_username!=username) {

	joule_update_statusbar();
	alert('Your statusbar is updating to reflect the changed settings.  If you click the lightbulb again, you will be taken to Joule.');

    } else {
	var url = 'http://joule.marnanel.org/chart/'+username+'/t';
	getBrowser().selectedTab = getBrowser().addTab(url);
	joule_set_busyness(0);
    }

    joule_previous_username = username;
}

joule_notify.prototype = {
    notify: function(timer) {
	joule_update_statusbar();
    }
};

joule_update_statusbar();
joule_timer.initWithCallback(new joule_notify(),
			     6*60*60*1000,
			     Components.interfaces.nsITimer.TYPE_REPEATING_PRECISE);

/* eof joule.js */
