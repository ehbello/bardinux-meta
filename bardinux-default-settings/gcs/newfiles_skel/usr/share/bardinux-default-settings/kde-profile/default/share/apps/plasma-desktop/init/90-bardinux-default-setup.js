/* Due Bardinux overlap of configurations we need to remove
all previous elements of the desktop. This script rebuilds
the plasma desktop completely.

Works perfectly in Plasma Desktop version 0.3

Enrique Hernández Bello, quique@osl.ull.es 2010-10-11
Copyright OSL-ULL, may be copied under the GNU GPL 2 or later
*/

for (var i = 0; i < panelIds.length; ++i) {
    var panel = panelById(panelIds[i]);
    panel.remove();
} // for panel

for (var i = 0; i < activityIds.length; ++i) {
    var activity = activityById(activityIds[i]);

    if (activity) {
        activity.screen=1; // ugly workaround to avoid
                           // the segmentation fault
        activity.remove();
    }
} // for activity

var activity = new Activity("folderview");

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

locked = true
