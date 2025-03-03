package util;

class FsUtil {

    public static function resolvePath(currentDir: String, wantedFile: String): String {
        if (currentDir == "") {
            return wantedFile;
        }

        var currentParts = currentDir.split("/");
        var wantedParts = wantedFile.split("/");

        if (wantedParts.length >= currentParts.length && wantedParts.slice(0, currentParts.length).join("/") == currentDir) {
            return "./" + wantedParts.slice(currentParts.length).join("/");
        }

        var upLevels = currentParts.length;
        var upString = "";
        for (i in 0...upLevels) {
            upString += "../";
        }

        return upString + wantedFile;
    }

}
