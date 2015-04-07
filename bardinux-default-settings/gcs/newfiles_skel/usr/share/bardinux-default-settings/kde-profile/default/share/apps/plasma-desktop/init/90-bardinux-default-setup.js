/* Due Bardinux overlap of configurations we need to remove
all previous elements of the desktop. This script rebuilds
the plasma desktop completely.

Works perfectly in Plasma Desktop version 0.3

Enrique Hernández Bello, quique@osl.ull.es 2010-10-11
Copyright OSL-ULL, may be copied under the GNU GPL 2 or later
*/

for (i in activityIds) {
	activityById(activityIds[i]).remove()
}

for (i in panelIds) {
	panelById(panelIds[i]).remove()
}

var panel = new Panel("panel");
panel.location = "bottom";
launcher = panel.addWidget("launcher");
launcher.globalShortcut = "Alt+F1"
panel.addWidget("quickaccess");
panel.addWidget("tasks");
panel.addWidget("pager");
panel.addWidget("showdesktop");

systray = panel.addWidget("systemtray");
i = 0;
if (hasBattery) {
    systray.currentConfigGroup = new Array("Applets", ++i);
    systray.writeConfig("plugin", "battery");
}
systray.currentConfigGroup = new Array("Applets", ++i);
systray.writeConfig("plugin", "message-indicator");
systray.currentConfigGroup = new Array("Applets", ++i);
systray.writeConfig("plugin", "notifier");

clock = panel.addWidget("digital-clock");
//clock.writeConfig("showDate", "true");

panel.addWidget("trash");

for (var i = 0; i < screenCount; ++i) {
    var desktop = new Activity("folderview")
    desktop.name = i18n("Desktop")
    desktop.screen = i
    desktop.wallpaperPlugin = 'image'
    desktop.wallpaperMode = 'SingleImage'

    //Create more panels for other screens
    if (i > 0) {
        var panel = new Panel
        panel.screen = i
        panel.location = 'bottom'
        panel.height = panels()[i].height = screenGeometry(0).height > 1024 ? 35 : 27
        var tasks = panel.addWidget("tasks")
        tasks.writeConfig("showOnlyCurrentScreen", true);
    }
}
locked = true
