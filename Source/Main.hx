import util.CommandLine;
import data.ProjectData;
import haxe.io.Path;
import errors.ErrorContainer;
import errors.ErrorType;

class Main {

    public static function getFilesRecursive(directory: String, addTo: Array<String>) {
        var files = sys.FileSystem.readDirectory(directory);
        for (file in files) {
            var path = Path.join([directory, file]);
            if (sys.FileSystem.isDirectory(path)) {
                getFilesRecursive(path, addTo);
            } else {
                addTo.push(path);
            }
        }
        return addTo;
    }

    public static function main() {
        var project = new ProjectData();

        var cli = new CommandLine();
        cli.addOption("output", "Basics", "Set the output location", value -> project.setOutputDirectory(value));
        cli.addOption("cwd", "Basics", "Set the current working directory", value -> project.setWorkingDirectory(value));
        cli.addOption("verbose", "Basics", "Enable verbose logging", value -> project.setVerbose(true));
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

        var stdFiles: Array<String> = [];
        for (stdFile in getFilesRecursive(project.getStdLibDirectory(), stdFiles)) {
            stdLib.addFile(stdFile);
        }

        if (project.getVerbose()) {
            project.printOptions();
        }

        errors.printErrors(true);
        project.applyWorkingDirectory();
        project.build();
    }

}