package util;

class CommandLine {
    private var _raw: Array<String>;
    private var _parsed: Map<String, Array<Dynamic>>;
    private var _optionCallbacks: Map<String, Array<String->Void>>;
    private var _optionCategories: Map<String, Array<String>>;
    private var _optionDescriptions: Map<String, String>;
    private var _rest: Array<String>;
    private var _defines: Map<String, String> = [
        "DUMP_AST" => "Dump the AST after parsing, will not output any code",
        "DUMP_AST_STDOUT" => "If DUMP_AST is set, dump the AST to stdout instead of 'ast.json'",
        "NO_STDLIB" => "Do not include the standard library as a dependency",
    ];

    public function new() {
        _raw = Sys.args();
        _rest = [];
        _parsed = new Map();
        _optionCallbacks = new Map();
        _optionCategories = new Map();
        _optionDescriptions = new Map();
    }

    public function parse(): Void {
        var key: String = null;
        for (arg in _raw) {
            if (arg.charAt(0) == "-") {
                key = arg.substr(1);
                if (!_parsed.exists(key)) {
                    _parsed.set(key, []);
                }
                _parsed.get(key).push(true);
            } else {
                if (key != null) {
                    _parsed.get(key).pop();
                    _parsed.get(key).push(arg);
                    key = null;
                } else {
                    _rest.push(arg);
                }
            }
        }

        for (key in _parsed.keys()) {
            if (_optionCallbacks.exists(key)) {
                for (callback in _optionCallbacks.get(key)) {
                    for (value in _parsed.get(key)) {
                        callback(Std.string(value));
                    }
                }
            }
        }
    }

    public function printHelp(): Void {
        Logging.print("ALCL 0.0.1 - a toy language and compiler by mikaib");
        Logging.print("Usage: alcl [options] [files]");

        for (category in _optionCategories.keys()) {
            Logging.print("\n" + category + ":");
            for (option in _optionCategories.get(category)) {
                Logging.print("  -" + option + ": " + _optionDescriptions.get(option));
            }
        }

        Logging.print("\nDefines:");
        for (define in _defines.keys()) {
            Logging.print("  -D " + define + ": " + _defines.get(define));
        }
    }

    public function get(key: String): Array<Dynamic> {
        return _parsed.exists(key) ? _parsed.get(key) : [];
    }

    public function getFirstOrDefault(key: String, defaultValue: Dynamic): Dynamic {
        return _parsed.exists(key) && _parsed.get(key).length > 0 ? _parsed.get(key)[0] : defaultValue;
    }

    public function has(key: String): Bool {
        return _parsed.exists(key);
    }

    public function getRest(): Array<String> {
        return _rest;
    }

    public function addOption(name: String, category: String, description: String, callback: String->Void): Void {
        if (!_optionCallbacks.exists(name)) {
            _optionCallbacks.set(name, []);
        }
        _optionCallbacks.get(name).push(callback);
        _optionDescriptions.set(name, description);

        if (!_optionCategories.exists(category)) {
            _optionCategories.set(category, []);
        }
        _optionCategories.get(category).push(name);
    }
}
