function update_statusbar_cb() {
    if(this.readyState != 4) return;

    if (this.status == 200) {
	alert(this.responseText);
    } else {
	alert('error');
    }
}

function update_statusbar() {
    var c = new XMLHttpRequest();
    c.onreadystatechange = update_statusbar_cb;
    c.open('GET', "http://joule.marnanel.org/json/tw/marnanel");
    c.send('');
}

function go_to_joule() {
    update_statusbar();
    //var url = 'http://joule.marnanel.org'; // fix this later
    //getBrowser().selectedTab = getBrowser().addTab(url);
}
