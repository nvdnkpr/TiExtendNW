(function () {
    'use strict';
    var win = Ti.UI.createWindow({
        backgroundColor: 'white',
        layout: 'vertical'
    });
    var btn = Ti.UI.createButton({
        width: Ti.UI.FILL,
        height: '44dp',
        top: '44dp',
        left: '11dp',
        right: '11dp',
        title: 'Request'
    });
    var ind = Ti.UI.createProgressBar({
        width: Ti.UI.FILL,
        top: '11dp',
        left: '11dp',
        right: '11dp',
        min: 0,
        max: 1,
        value: 0,
        style: Ti.UI.iPhone.ProgressBarStyle.PLAIN
    });

    btn.addEventListener('click', function () {
        ind.value = 0;

        var TiExtendNW = require('net.imthinker.ti.extendnw');
        Ti.API.info("module is => " + TiExtendNW);

        var http = TiExtendNW.createHTTPClient();
        http.open('GET', 'http://httpbin.org/get', {
            freezable: true,
            forceReload: false
        });

        http.onload = function (e) {
            Ti.API.debug('onload callback objects');
            Ti.API.debug(e);

            Ti.API.debug('allResponseHeaders');
            Ti.API.debug(http.allResponseHeaders);

            Ti.API.debug('status');
            Ti.API.debug(http.status);
            Ti.API.debug(http.statusText);

            Ti.API.debug('responseText');
            Ti.API.debug(http.responseText);

            Ti.API.debug('responseJSON');
            Ti.API.debug(http.responseJSON);

            Ti.API.debug('responseData');
            Ti.API.debug(http.responseData);
        };

        http.onerror = function (e) {
            Ti.API.error(e);
        };

        http.ondatastream = function (e) {
            ind.value = e.value;
        };

        http.onsendstream = function (e) {
            ind.value = e.value;
        };

        http.setRequestHeader('User-Agent', 'MKNetworkKit wrapper for Titanium (iOS) / Version 1.0');
        http.setRequestHeader('X-ApplicationVersion', Ti.App.version);
        http.send({
            foo: 'bar',
            hoge: 'huga'
        });
    });
    win.add(btn);
    win.add(ind);
    ind.show();
    win.open();
}());
