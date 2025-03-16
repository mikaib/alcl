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

        // TODO: temp fix for libmath on linux, should add a build system to ALCL
        if (platform == CBuildPlatform.Linux) {
            cmakeContent.add("target_link_libraries(ALCLOutput m)\n");
        }

        cmakeContent.add("add_executable(" + output + " ");

        var uniqueDirs: Array<String> = [];
        for (file in files) {
            var dir = Path.directory(file);
            cmakeContent.add("../src/" + file + " ");

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
            if (_project.getVerbose()) {
                Logging.print("running: " + cmd);
                Sys.command(cmd);
                continue;
            }

            if (problems) {
                continue;
            }

            var cmdArgs = cmd.split(" ");
            var cmdName = cmdArgs.shift();
            try {
                var process = new Process(cmdName, cmdArgs);
                var err = process.stderr.readAll().toString();

                if (process.exitCode(true) != 0) {
                    Logging.print(process.stdout.readAll().toString());
                    Logging.error(err);
                    problems = true;
                }
            } catch (e: Dynamic) {
                Logging.error("Failed to run CMake command!");
                problems = true;
            }
        }

        if (problems) {
            Logging.error("Compilation failed (cmake)");
        }
    }
}
