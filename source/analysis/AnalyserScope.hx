package analysis;
import ast.Node;

class AnalyserScope {

    private static var _count: Int = 0;

    private var _analyser: Analyser;
    private var _variables: Array<AnalyserVariable>;
    private var _functions: Array<AnalyserFunction>;
    private var _castMethods: Array<AnalyserCastMethod>;
    private var _varLookup: Map<String, AnalyserVariable>;
    private var _funcLookup: Map<String, AnalyserFunction>;
    private var _id: Int;
    private var _currentFunctionNode: Node;

    public function new(analyser: Analyser) {
        _analyser = analyser;
        _varLookup = [];
        _funcLookup = [];
        _variables = [];
        _functions = [];
        _castMethods = [];
        _id = _count++;
    }

    public function isInFunction(): Bool {
        return _currentFunctionNode != null;
    }

    public function getCurrentFunctionNode(): Null<Node> {
        return _currentFunctionNode;
    }

    public function getVariables(): Array<AnalyserVariable> {
        return _variables;
    }

    public function getFunctions(): Array<AnalyserFunction> {
        return _functions;
    }

    public function getVariable(name: String): Null<AnalyserVariable> {
        return _varLookup.get(name);
    }

    public function getFunction(name: String): Null<AnalyserFunction> {
        return _funcLookup.get(name);
    }

    public function getCastMethods(): Array<AnalyserCastMethod> {
        return _castMethods;
    }

    public function addCastMethod(method: AnalyserCastMethod): Void {
        _castMethods.push(method);
    }

    public function setCurrentFunctionNode(node: Node): Void {
        _currentFunctionNode = node;
    }

    public function defineVariable(name: String, type: AnalyserType, node: Node, initialized: Bool = true): Void {
        var variable: AnalyserVariable = {
            name: name,
            type: type,
            origin: node,
            isInitialized: initialized
        };

        _variables.push(variable);
        _varLookup.set(name, variable);
    }

    public function defineFunction(name: String, type: AnalyserType, params: Array<AnalyserFunctionParam>, origin: Node): Void {
        var func: AnalyserFunction = {
            name: name,
            type: type,
            params: params,
            origin: origin
        };

        _functions.push(func);
        _funcLookup.set(name, func);
    }

    public function copyFromScope(scope: AnalyserScope, shallowCopy: Bool = true): Void {
        _variables = shallowCopy ? scope._variables.copy() : scope._variables;
        _functions = shallowCopy ? scope._functions.copy() : scope._functions;
        _varLookup = shallowCopy ? scope._varLookup.copy() : scope._varLookup;
        _funcLookup = shallowCopy ? scope._funcLookup.copy() : scope._funcLookup;
        _castMethods = shallowCopy ? scope._castMethods.copy() : scope._castMethods;
        _currentFunctionNode = scope._currentFunctionNode;
    }

    public function toDebugString(): String {
        return '#' + _id;
    }

}
