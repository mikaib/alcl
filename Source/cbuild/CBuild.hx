package cbuild;
import data.ProjectData;

class CBuild {

    private var _cFiles: Array<String>;
    private var _outputFile: String;
    private var _targetPlatform: CBuildPlatform;
    private var _builderPlatform: CBuildPlatform;
    private var _project: ProjectData;

    public function new(project: ProjectData, outputFile: String = "") {
        switch (Sys.systemName()) {
            case "Windows":
                this._targetPlatform = CBuildPlatform.Windows;
                this._builderPlatform = CBuildPlatform.Windows;
            case "Linux":
                this._targetPlatform = CBuildPlatform.Linux;
                this._builderPlatform = CBuildPlatform.Linux;
            default:
                throw "Unsupported platform";
        }

        this._cFiles = [];
        this._outputFile = outputFile == "" ? getDefaultOutputFile() : outputFile;
        this._project = project;
    }

    private function getDefaultOutputFile(): String {
        return "output";
    }

    public function setPlatform(platform: CBuildPlatform) {
        this._targetPlatform = platform;
    }

    public function addFile(cFile: String) {
        this._cFiles.push(cFile);
    }

    public function compile() {}

}
