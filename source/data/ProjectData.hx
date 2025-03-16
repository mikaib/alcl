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
import analysis.Analyser;
import analysis.AnalyserType;

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
    private var _analyserMap: Map<String, Analyser> = [];
    private var _defines: Map<String, String> = [];

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
     * Set the built file map
     */
    public function setBuiltFileMap(map: Map<String, Bool>): Void {
        _builtFileMap = map;
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
     * Get the analyser map
     */
    public function getAnalyserMap(): Map<String, Analyser> {
        return _analyserMap.copy();
    }

    /**
     * Set the analyser map
     */
    public function setAnalyserMap(map: Map<String, Analyser>): Void {
        _analyserMap = map;
    }

    /**
     * Add a define
     * @param name The name of the define
     */
    public function addDefine(name: String): Void {
        _defines[name.toLowerCase()] = '';
    }

    /**
     * Set a define
     * @param name The name of the define
     * @param value The value of the define
     */
    public function setDefine(name: String, value: String): Void {
        _defines[name.toLowerCase()] = value;
    }

    /**
     * Get the defines
     */
    public function getDefines(): Map<String, String> {
        return _defines.copy();
    }

    /**
     * Check if define is set
     */
    public function hasDefine(name: String): Bool {
        return _defines.exists(name.toLowerCase());
    }

    /**
     * Set the defines
     */
    public function setDefines(defines: Map<String, String>): Void {
        _defines = defines;
    }

    /**
     * Run a build on the project
     */
    public function build(isDependency: Bool = false): Bool {
        var start = Sys.time();
        _dumpAst = hasDefine('dump_ast');

        for (dependency in _dependencies) {
            if (_verbose) Logging.debug('Building dependency: ${dependency.getProjectName()}');
            dependency.setOutputDirectory(_outputDirectory);
            dependency.setImportMap(_importMap);
            dependency.setAstMap(_astMap);
            dependency.setDumpAst(_dumpAst);
            dependency.setParserMap(_parserMap);
            dependency.setBuiltFileMap(_builtFileMap);
            dependency.setVerbose(_verbose);
            dependency.setAnalyserMap(_analyserMap);
            dependency.setDefines(_defines);
            dependency.build(true);
        }

        if (getVerbose()) Logging.info('Start building: ${_projectName}');
        var errors = new ErrorContainer();

        // import map prepass
        for (file in _files) {
            var baseLoc = baseLocOf(file);
            addImport(baseLoc, file);

            if (_verbose) Logging.debug('Import map: ${baseLoc} -> ${file}');
        }

        // tokenize + gen ASTs
        var ownAnalysers: Array<Analyser> = [];
        for (file in _files) {
            if (getVerbose()) {
                Logging.info('- ${file} [parse]');
            }

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
            _parserMap[file] = parser;

            var analyser = new Analyser(parser, this, file);
            _analyserMap[baseLocOf(file)] = analyser;
            ownAnalysers.push(analyser);

            if (baseLocOf(file) != "alcl/global" && parser.doesWantGlobalLib()) { // making sure primitive types and runtime libs are there.
                parser.ensureRequirement("alcl/global");
            }
        }

        var visited:Map<String, Bool> = [];
        var sortedAnalysers:Array<Analyser> = [];

        function visit(dep:String):Void {
            if (visited.exists(dep)) return;
            visited[dep] = true;
            var analyser = _analyserMap[dep];
            if (analyser != null) {
                for (req in analyser.getParser().getLibRequirements()) {
                    visit(req);
                }
                sortedAnalysers.push(analyser);
            }
        }

        for (file in _files) {
            var base = baseLocOf(file);
            visit(base);
        }

        var hasErrors: Bool = false;

        for (analyser in sortedAnalysers) {
            if (!ownAnalysers.contains(analyser)) {
                continue;
            }

            var libAnalysers:Array<Analyser> = [];
            for (dep in analyser.getParser().getLibRequirements()) {
                var dependencyAnalyser = _analyserMap[dep];
                if (dependencyAnalyser == null) {
                    Logging.error('Could not resolve import ${dep}');
                    hasErrors = true;
                    continue;
                }

                var selfLoc = baseLocOf(analyser.getFile());
                function checkCircularDependency(analyser: Analyser, visited: Map<String, Bool>, chain: Array<String>): Void {
                    var selfLoc = baseLocOf(analyser.getFile());
                    if (visited.exists(selfLoc)) {
                        chain.push(selfLoc);
                        analyser.emitError(null, ErrorType.CircularDependency, 'Circular dependencies are not allowed: ${chain.join(" -> ")}');
                        return;
                    }
                    visited.set(selfLoc, true);
                    chain.push(selfLoc);
                    for (subDep in analyser.getParser().getLibRequirements()) {
                        var dependencyAnalyser = _analyserMap[subDep];
                        if (dependencyAnalyser != null) {
                            checkCircularDependency(dependencyAnalyser, visited, chain);
                        }
                    }
                    chain.pop();
                    visited.remove(selfLoc);
                }
                checkCircularDependency(analyser, [], []);

                analyser.getParser().getTypes().copyFrom(dependencyAnalyser.getParser().getTypes());
                libAnalysers.push(dependencyAnalyser);
            }
            analyser.run(libAnalysers);
            // analyser.getParser().print();
        }

        // log errors
        for (analyser in sortedAnalysers) {
            var errorContainer = analyser.getErrors();
            if (errorContainer.hasErrors()) {
                hasErrors = true;
                errorContainer.printErrors(false);
            }
        }

        if (hasErrors) {
            return false;
        }

        // print ASTs
        for (file in _files) {
            if (getVerbose()) {
                Logging.info('- ${file} [write]');
            }

            var parser = _parserMap[file];
            if (parser == null) {
                Logging.error('Missing parser for file "$file"');
                return false;
            }
            var ogLoc = removeTrailingOrLeadingSlashes(StringTools.replace(StringTools.replace(file.split('.alcl').join(''), _rootDirectory, ""), "\\", "/"));
            var parts = ogLoc.split('/');
            parts[parts.length - 1] = 'alcl_' + parts[parts.length - 1];
            var baseLoc = parts.join('/');

            var baseLocDir = Path.directory(baseLoc);
            var printer = new Printer(parser, this, baseLocDir);
            if (!_dumpAst) {
                var outputC = printer.print();
                var outputH = printer.printHeaderFile(baseLoc);
                var outputFilenameC = Path.join([_outputDirectory, 'src', baseLoc + '.c']);
                var outputFilenameH = Path.join([_outputDirectory, 'src', baseLoc + '.h']);

                createDirectoryRecursive(Path.directory(outputFilenameC));
                File.saveContent(outputFilenameC, outputC);
                File.saveContent(outputFilenameH, outputH);

                _builtFileMap[baseLoc] = true;
            } else {
                var node = parser.getRoot().deepCopy(false, false);
                _astMap[ogLoc] = node;
            }
        }

        // final code
        if (!isDependency) {
            if (_dumpAst) {
                function recurseNode(node: Node): Void {
                    for (child in node.children) {
                        recurseNode(child);
                    }

                    node.analysisScope = null;
                }

                for (key in _astMap.keys()) {
                    recurseNode(_astMap[key]);
                }

                var json = haxe.Json.stringify(_astMap, null, "\t");

                if (hasDefine("dump_ast_stdout")) {
                    Sys.println(json);
                } else {
                    var outputFilename = Path.join([_outputDirectory, "ast.json"]);
                    createDirectoryRecursive(Path.directory(outputFilename));
                    File.saveContent(outputFilename, json);

                    Logging.info('Dumped AST to ${outputFilename}');
                }
            }

            if (_verbose) {
                Logging.success('Generation Done! Took ${Sys.time() - start} seconds.');
            }
        }

        return true;
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