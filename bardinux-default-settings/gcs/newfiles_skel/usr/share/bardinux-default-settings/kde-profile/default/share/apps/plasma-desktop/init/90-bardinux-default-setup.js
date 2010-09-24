for (var i = 0; i < panelIds.length; ++i) {
    var panel = panelById(panelIds[i]);
    panel.remove();
} // for panel

for (var i = 0; i < activityIds.length; ++i) {
    var activity = activityById(activityIds[i]);
    var widgetIds = activity.widgetIds;

    if (activity && (activity.type == "desktop")) {
        for (var j = 0; j < widgetIds.length; ++j) {
            var widget = activity.widgetById(widgetIds[j]);

            if (widget) {
                widget.remove();
            }
        }
    }
} // for activity

var activity = new Activity("folderview");
//activity.writeConfig("wallpaper", "/usr/share/wallpapers/bardinux/");

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
