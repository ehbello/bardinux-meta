/* Due Bardinux overlap of configurations we need to remove
all previous elements of the desktop. This script rebuilds
the plasma desktop completely.

Works perfectly in Plasma Desktop version 0.3

Enrique Hernández Bello, quique@osl.ull.es 2010-10-11
Copyright OSL-ULL, may be copied under the GNU GPL 2 or later
*/

desktop = activityById(activityIds[0]);
if (typeof desktop === "undefined") {
    print("E: Couldn't find first activity");
    exit();
}

// unlock so that widget.remove() works
// BUG: .remove doesnt work but add, does? => inconsistency in API
var was_locked = false;
if (locked) {
    was_locked = true
    locked = false
}

desktop.currentConfigGroup = Array("Wallpaper", "image");
desktop.writeConfig("wallpaper", "bardinux-sigaull-alert");

var username = userDataPath().split("/").pop()

folderview = desktop.addWidget("folderview");
folderview.geometry = QRectF(screenGeometry(0).width - 410, folderview.geometry.y + 30, 410, 180);
folderview.writeConfig("url", "/tmp/" + username + "-remote/");
folderview.writeConfig("iconsLocked", "true");
folderview.writeConfig("immutability", "2");
folderview.writeConfig("alignToGrid", "true");
folderview.writeConfig("customLabel", "Disco Duro Virtual");
folderview.writeConfig("customIconSize", "48");

// lock again, if it was locked before
if (was_locked) {
    locked = true
}
