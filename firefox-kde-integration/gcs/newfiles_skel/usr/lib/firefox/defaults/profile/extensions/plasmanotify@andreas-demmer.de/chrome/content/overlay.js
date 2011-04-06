/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2009 Andreas Demmer <mail@andreas-demmer.de>
 *
 * inspired by FirefoxNotify, originally written by Abhishek Mukherjee <abhishek.mukher.g@gmail.com>
 */

var download_complete_notify = {
  onLoad: function() {

    // initialization code
    this.initialized = true;
    this.strings = document.getElementById("download_complete_notify-strings");
    
    this.dlMgr = Components.classes["@mozilla.org/download-manager;1"]
                           .getService(Components.interfaces.nsIDownloadManager);
              
    this.dlMgr.addListener(download_complete_notify);

    // disable native firefox download notifications
    var prefs = Components.classes["@mozilla.org/preferences-service;1"]
                    .getService(Components.interfaces.nsIPrefService);
    prefs.setBoolPref("browser.download.manager.showAlertOnComplete",false);
  },
  
  notify: function(aDownload) {
    var shell = "/bin/sh";
    
    const MY_ID = 'plasmanotify@andreas-demmer.de';
    const DIR_SERVICE = Components.classes["@mozilla.org/extensions/manager;1"].getService(Components.interfaces.nsIExtensionManager);
    
    try {
	var scriptfile = DIR_SERVICE.getInstallLocation(MY_ID).getItemFile(MY_ID, "chrome/content/notify.sh");
	var file = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);

        var shellObj = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
        shellObj.initWithPath(shell);

	var process = Components.classes["@mozilla.org/process/util;1"].createInstance(Components.interfaces.nsIProcess);
	process.init(shellObj);

	var message = "\"" + aDownload.displayName + "\" " +  document.getElementById('plasmanotify-strings').getString('downloads.successfullyDownloaded');

	var args = [scriptfile.path,message];   
        process.run(false, args, args.length);

    } catch (e) {
	var string_failed = document.getElementById('plasmanotify-strings').getString('failed');
        alert(string_failed + ": " + e);
        return;
    }
  },
  
  onDownloadStateChange: function(aState, aDownload) {
    
    switch(aDownload.state) {
      case Components.interfaces.nsIDownloadManager.DOWNLOAD_DOWNLOADING:
      case Components.interfaces.nsIDownloadManager.DOWNLOAD_FAILED:
      case Components.interfaces.nsIDownloadManager.DOWNLOAD_CANCELED:
        break;
        
      case Components.interfaces.nsIDownloadManager.DOWNLOAD_FINISHED:
        this.notify(aDownload);
        break;
    }
  },

};

window.addEventListener("load", function(e) { download_complete_notify.onLoad(e); }, false);
