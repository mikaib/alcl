package analysis;

class AnalyserScope {

    private var _analyser: Analyser;
    private var _variables: Array<AnalyserVariable>;
    private var _functions: Array<AnalyserFunction>;

    public function new(analyser: Analyser) {
        _analyser = analyser;
    }

    public function getVariables(): Array<AnalyserVariable> {
        return _variables;
    }

    public function getFunctions(): Array<AnalyserFunction> {
        return _functions;
    }

    public function copyFromScope(scope: Analyser, deep: Bool = true): Void {
        _variables = deep ? _variables.copy() : _variables;
        _functions = deep ? _functions.copy() : _functions;
    }

}
