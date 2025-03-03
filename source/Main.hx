import util.CommandLine;
import data.ProjectData;
import haxe.io.Path;
import errors.ErrorContainer;
import errors.ErrorType;
import sys.FileSystem;
import cbuild.CMakeInterface;
import cbuild.CBuild;

class Main {

    public static function getFilesRecursive(directory: String, addTo: Array<String>) {
        var files = sys.FileSystem.readDirectory(directory);
        for (file in files) {
            var path = directory + '/' + file;
            if (sys.FileSystem.isDirectory(path)) {
                getFilesRecursive(path, addTo);
            } else {
                addTo.push(path);
            }
        }
        return addTo;
    }

    public static function main() {
        cli_main();
    }

    public static function cli_main() {
        var project = new ProjectData();

        var cli = new CommandLine();
        var compileUsing: String = "";
        cli.addOption("output", "Basics", "Set the output location", value -> project.setOutputDirectory(value));
        cli.addOption("cwd", "Basics", "Set the current working directory", value -> project.setWorkingDirectory(value));
        cli.addOption("verbose", "Basics", "Enable verbose logging", value -> project.setVerbose(true));
        cli.addOption("compile", "Basics", "Compile the project with the specified build tool", value -> compileUsing = value);
        cli.addOption("std", "Advanced", "Set the directory of the standard library", value -> project.setStdLibDirectory(value));
        cli.addOption("ast", "Advanced", "Output the AST of the entire project", value -> project.setDumpAst(true));
        cli.parse();

        var rest = cli.getRest();
        if (rest.length <= 0) {
            cli.printHelp();
            return;
        }

        var errors: ErrorContainer = new ErrorContainer();
        for (file in rest) {
            var ext = Path.extension(file);

            switch (ext) {
                case 'alcl':
                    project.addFile(file);
                default:
                    errors.addError({ message: file, type: ErrorType.UnsupportedFileType });
            }
        }


        var stdLib = new ProjectData();
        stdLib.setProjectName("StandardLibrary");
        stdLib.setRootDirectory(project.getStdLibDirectory());

        project.setProjectName("UserProject");
        project.addDependency(stdLib);
        project.applyWorkingDirectory();

        var stdFiles: Array<String> = [];
        if (!FileSystem.exists(project.getStdLibDirectory())) {
            errors.addError({ message: "Standard library directory does not exist", type: ErrorType.FileNotFound });
            errors.printErrors(true);
        }

        for (stdFile in getFilesRecursive(project.getStdLibDirectory(), stdFiles)) {
            stdLib.addFile(stdFile);
        }

        if (project.getVerbose()) {
            project.printOptions();
        }

        errors.printErrors(true);
        project.build();

        if (compileUsing == "") {
            return;
        }

        var compiler: CBuild = null;
        switch (compileUsing) {
            case "cmake":
                compiler = new CMakeInterface(project);
        }

        if (compiler != null) {
            for (file in project.getBuiltFileMap().keys()) {
                compiler.addFile('$file.c');
            }
            compiler.compile();
        }
    }

}