package cbuild;

import sys.io.File;
import sys.io.Process;
import util.Logging;
import haxe.io.Path;
using StringTools;

class CMakeInterface extends CBuild {
    override public function compile() {
        var files: Array<String> = _cFiles;
        var output: String = _outputFile;
        var platform: CBuildPlatform = _targetPlatform; // TODO: implement

        if (files.length == 0) {
            Logging.warn("No files to compile");
            return;
        }

        var cmakeContent = new StringBuf();
        cmakeContent.add("cmake_minimum_required(VERSION 3.10)\n");
        cmakeContent.add("project(CBuildProject)\n");
        cmakeContent.add("add_executable(" + output + " ");

        var uniqueDirs: Array<String> = [];
        for (file in files) {
            var dir = Path.directory(file);
            cmakeContent.add("../" + file + " ");

            if (uniqueDirs.indexOf(dir) == -1) {
                uniqueDirs.push(dir);
            }
        }

        cmakeContent.add(")\n");

        for (dir in uniqueDirs) {
            cmakeContent.add("include_directories(./" + dir + ")\n");
        }

        var buildDir = _project.getOutputDirectory() + "/build";
        if (!sys.FileSystem.exists(buildDir)) {
            sys.FileSystem.createDirectory(buildDir);
        }

        File.saveContent(buildDir + "/CMakeLists.txt", cmakeContent.toString());
        Sys.setCwd(buildDir);
        Sys.command("cmake .");
        Sys.command("cmake --build . --config Release");
    }
}
