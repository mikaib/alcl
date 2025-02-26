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
        cmakeContent.add("project(ALCLOutput)\n");
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
        var cmds: Array<String> = [
            "cmake .",
            "cmake --build . --config Release"
        ];

        var problems: Bool = false;
        for (cmd in cmds) {
            var cmdArgs = cmd.split(" ");
            var cmdName = cmdArgs.shift();
            var process = new Process(cmdName, cmdArgs);
            var err = process.stderr.readAll().toString();

            if (process.exitCode(true) != 0) {
                Logging.print(process.stdout.readAll().toString());
                Logging.error(err);
                problems = true;
            }
        }

        if (problems) {
            Logging.error("Compilation failed (cmake)");
        }
    }
}
