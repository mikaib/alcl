package util;

class CommandLine {

    private var _raw: Array<String>;
    private var _parsed: Map<String, Dynamic>;
    private var _optionCallbacks: Map<String, String->Void>;
    private var _optionCategories: Map<String, Array<String>>;
    private var _optionDescriptions: Map<String, String>;
    private var _rest: Array<String>;

    public function new() {
        _raw = Sys.args();
        _rest = [];
        _parsed = [];
        _optionCallbacks = [];
        _optionCategories = [];
        _optionDescriptions = [];
    }

    public function parse(): Void {
        var key: String = null;
        for (arg in _raw) {
            if (arg.charAt(0) == "-") {
                key = arg.substr(1);
                _parsed.set(key, null);
            } else {
                if (key != null) {
                    _parsed.set(key, arg);
                    key = null;
                } else {
                    _rest.push(arg);
                }
            }
        }

        for (key in _parsed.keys()) {
            if (_optionCallbacks.exists(key)) {
                _optionCallbacks.get(key)(_parsed.get(key));
            }
        }
    }

    public function printHelp(): Void {
        Logging.print("ALCL 0.0.1 - a toy language and compiler by mikaib");
        Logging.print("Usage: alcl [options] [files]");

        for (category in _optionCategories.keys()) {
            Logging.print("");
            Logging.print(category + ":");
            for (option in _optionCategories.get(category)) {
                Logging.print("  -" + option + ": " + _optionDescriptions.get(option));
            }
        }
    }

    public function get(key: String): Dynamic {
        return _parsed.get(key);
    }

    public function getOrDefault(key: String, defaultValue: Dynamic): Dynamic {
        return _parsed.get(key) == null ? defaultValue : _parsed.get(key);
    }

    public function has(key: String): Bool {
        return _parsed.exists(key);
    }

    public function getRest(): Array<String> {
        return _rest;
    }

    public function addOption(name: String, category: String, description: String, callback: String->Void): Void {
        _optionCallbacks.set(name, callback);
        _optionDescriptions.set(name, description);

        if (!_optionCategories.exists(category)) {
            _optionCategories.set(category, []);
        }

        _optionCategories.get(category).push(name);
    }

}
