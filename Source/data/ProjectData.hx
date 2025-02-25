package data;
import util.Logging;
import tokenizer.Tokenizer;
import sys.FileSystem;
import errors.ErrorContainer;
import errors.ErrorType;
import sys.io.File;
import haxe.io.Path;
import ast.Parser;
import printer.Printer;
import ast.Node;

class ProjectData {
    private var _importMap: Map<String, String> = [];
    private var _files: Array<String> = [];
    private var _projectName: String = "Project";
    private var _outputDirectory: String = "./Build";
    private var _workingDirectory: String = "./";
    private var _stdLibDirectory: String = "./";
    private var _rootDirectory: String = "";
    private var _dependencies: Array<ProjectData> = [];
    private var _verbose: Bool = false;
    private var _dumpAst: Bool = false;
    private var _astMap: Map<String, Node> = [];
    private var _builtFileMap: Map<String, Bool> = [];
    private var _parserMap: Map<String, Parser> = [];

    /**
     * Set the dump AST flag for the project
     */
    public function setDumpAst(dumpAst: Bool): Void {
        _dumpAst = dumpAst;
    }

    /**
     * Set the AST map for the project
     */
    public function setAstMap(map: Map<String, Node>): Void {
        _astMap = map;
    }

    /**
     * Add a file to the project
     */
    public function addFile(file: String): Void {
        _files.push(file);
    }

    /**
     * Set the verbose flag for the project
     */
    public function setVerbose(verbose: Bool): Void {
        _verbose = verbose;
    }

    /**
     * Get the verbose flag for the project
     */
    public function getVerbose(): Bool {
        return _verbose;
    }

    /**
     * Set the output directory for the project
     */
    public function setOutputDirectory(directory: String): Void {
        _outputDirectory = directory;
    }

    /**
     * Get the files in the project
     */
    public function getFiles(): Array<String> {
        return _files.copy();
    }

    /**
     * Get the output directory for the project
     */
    public function getOutputDirectory(): String {
        return _outputDirectory;
    }

    /**
     * Get the working directory for the project
     */
    public function getWorkingDirectory(): String {
        return _workingDirectory;
    }

    /**
     * Set the working directory for the project
     */
    public function setWorkingDirectory(directory: String): Void {
        _workingDirectory = directory;
    }

    /**
     * Apply the working directory.
     */
    public function applyWorkingDirectory(): Void {
        Sys.setCwd(_workingDirectory);
    }

    /**
     * Get the project name
     */
    public function getProjectName(): String {
        return _projectName;
    }

    /**
     * Set the project name
     */
    public function setProjectName(name: String): Void {
        _projectName = name;
    }

    /**
     * Add a dependency to the project
     */
    public function addDependency(project: ProjectData): Void {
        _dependencies.push(project);
    }

    /**
     * Get the dependencies of the project
     */
    public function getDependencies(): Array<ProjectData> {
        return _dependencies.copy();
    }

    /**
     * Get the built file map
     */
    public function getBuiltFileMap(): Map<String, Bool> {
        return _builtFileMap.copy();
    }

    /**
     * Get the parser map
     */
    public function getParserMap(): Map<String, Parser> {
        return _parserMap.copy();
    }

    /**
     * Set the parser map
     */
    public function setParserMap(map: Map<String, Parser>): Void {
        _parserMap = map;
    }

    /**
     * Print the project data
     */
    public function printOptions(): Void {
        var fields = Reflect.fields(this);
        for (field in fields) {
            Logging.debug('${field.split('_').join('')} = ${Reflect.field(this, field)}');
        }
    }

    /**
     * Find a file in the project
     * @param file The file to find
     * @return True if the file is in the project
     */
    public function hasFile(file: String): Bool {
        return _files.indexOf(file) != -1;
    }

    /**
     * Create a dir at a location recursively.
     */
    public function createDirectoryRecursive(directory: String): Void {
        var parts = directory.split('/');
        var current = '';
        for (part in parts) {
            current = Path.join([current, part]);
            if (!FileSystem.exists(current)) {
                FileSystem.createDirectory(current);
            }
        }
    }

    /**
     * Get the stdlib directory
     */
    public function getStdLibDirectory(): String {
        return _stdLibDirectory;
    }

    /**
     * Set the stdlib directory
     */
    public function setStdLibDirectory(directory: String): Void {
        _stdLibDirectory = directory;
    }

    /**
     * Get the root directory
     */
    public function getRootDirectory(): String {
        return _rootDirectory;
    }

    /**
     * Set the root directory
     */
    public function setRootDirectory(directory: String): Void {
        _rootDirectory = directory;
    }

    /**
     * Get the import map
     */
    public function getImportMap(): Map<String, String> {
        return _importMap.copy();
    }

    /**
     * Set the import map
     */
    public function setImportMap(map: Map<String, String>): Void {
        _importMap = map;
    }

    /**
     * Add an import to the import map
     */
    public function addImport(name: String, path: String): Void {
        _importMap[name] = path;
    }

    /**
     * Resolve a file in the import map
     */
    public function resolveImport(name: String): String {
        return _importMap[name];
    }

    /**
     * Get the base loc
     */
    public function baseLocOf(file: String): String {
        return removeTrailingOrLeadingSlashes(StringTools.replace(StringTools.replace(file.split('.alcl').join(''), _rootDirectory, ""), "\\", "/"));
    }

    /**
     * Run a build on the project
     */
    public function build(isDependency: Bool = false): Void {
        var start = Sys.time();

        for (dependency in _dependencies) {
            dependency.setOutputDirectory(_outputDirectory);
            dependency.setImportMap(_importMap);
            dependency.setAstMap(_astMap);
            dependency.setDumpAst(_dumpAst);
            dependency.setParserMap(_parserMap);
            dependency.build(true);
        }

        // Logging.info('Start building: ${_projectName}');
        var errors = new ErrorContainer();

        // import map prepass
        for (file in _files) {
            var baseLoc = baseLocOf(file);
            addImport(baseLoc, file);
        }

        // tokenize + gen ASTs
        for (file in _files) {
            if (!FileSystem.exists(file)) {
                errors.addError({ type: ErrorType.FileNotFound, message: file });
                continue;
            }

            if (FileSystem.isDirectory(file)) {
                errors.addError({ type: ErrorType.FileIsDirectory, message: file });
                continue;
            }

            var content = File.getContent(file);
            var tokenizer = Tokenizer.fromString(content, false);
            var parser = new Parser(tokenizer);

            parser.parse();
            //parser.printDotFile();
            _parserMap[file] = parser;

            if (baseLocOf(file) != "alcl/global" && parser.doesWantGlobalLib()) { // making sure primitive types and runtime libs are there.
                parser.ensureRequirement("alcl/global");
            }
            // Logging.info('- ${Path.join([file])}');
            // parser.print();
            // TODO: verification of AST (errors or resolving unresolved types)
        }

        // typer + verifier
        for (file in _files) {
            var parser = _parserMap[file];
            if (parser == null) {
                Logging.warn('Missing parser for file "$file"');
                return;
            }
            var imports = parser.getLibRequirements();
            for (imp in imports) {
                var resolved = resolveImport(imp);
                var parserOfImport = _parserMap[resolved];

                if (parserOfImport == null) {
                    Logging.error('Could not resolve import ${imp} in ${file}');
                    return;
                }

                parser.getTypes().copyFrom(parserOfImport.getTypes());
            }
        }

        // print ASTs
        for (file in _files) {
            var parser = _parserMap[file];
            if (parser == null) {
                Logging.warn('Missing parser for file "$file"');
                return;
            }
            var printer = new Printer(parser, this);
            var baseLoc = removeTrailingOrLeadingSlashes(StringTools.replace(StringTools.replace(file.split('.alcl').join(''), _rootDirectory, ""), "\\", "/"));
            if (!_dumpAst) {
                var output = printer.print();
                var outputFilename = Path.join([_outputDirectory, baseLoc + '.c']);
                createDirectoryRecursive(Path.directory(outputFilename));
                File.saveContent(outputFilename, output);
            } else {
                _astMap[baseLoc] = parser.getRoot().deepCopy(false);
            }
        }

        // final code
        if (!isDependency) {
            if (_dumpAst) {
                var json = haxe.Json.stringify(_astMap, null, "\t");
                var outputFilename = Path.join([_outputDirectory, "ast.json"]);
                createDirectoryRecursive(Path.directory(outputFilename));
                File.saveContent(outputFilename, json);

                Logging.info('Dumped AST to ${outputFilename}');
            }
            Logging.success('Done! Took ${Sys.time() - start} seconds.');
        }
    }

    public function removeTrailingOrLeadingSlashes(path: String): String {
        if (path.charAt(0) == '/') {
            path = path.substr(1);
        }

        if (path.charAt(path.length - 1) == '/') {
            path = path.substr(0, path.length - 1);
        }

        return path;
    }

    public function new() {
        var execPath = Sys.programPath();
        _stdLibDirectory = Path.join([Path.directory(execPath), 'stdlib']);
    }
}