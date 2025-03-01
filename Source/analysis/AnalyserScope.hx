package analysis;
import ast.Node;

class AnalyserScope {

    private var _analyser: Analyser;
    private var _variables: Array<AnalyserVariable>;
    private var _functions: Array<AnalyserFunction>;
    private var _varLookup: Map<String, AnalyserVariable>;
    private var _funcLookup: Map<String, AnalyserFunction>;
    private var _operatorResultTypes: Map<String, Map<String, AnalyserType>>;
    private var _currentFunctionNode: Node;

    public function new(analyser: Analyser) {
        _analyser = analyser;
        _varLookup = [];
        _funcLookup = [];
        _variables = [];
        _functions = [];
        _operatorResultTypes = [];
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

    public function addOperatorType(aType: AnalyserType, bType: AnalyserType, resultType: AnalyserType, bidirectional: Bool = false): Void {
        if (bidirectional) {
            addOperatorType(bType, aType, resultType, false);
        }

        if (_operatorResultTypes.get(aType) == null) {
            _operatorResultTypes.set(aType, []);
        }

        _operatorResultTypes.get(aType).set(bType, resultType);
    }

    public function findOperatorResultType(aType: AnalyserType, bType: AnalyserType): AnalyserType {
        var aName = aType;
        var bName = bType;

        if (aName == "Unknown" && bType != "Unknown") {
            aName = bType;
        }

        if (bName == "Unknown" && aType != "Unknown") {
            bName = aType;
        }

        var result = _operatorResultTypes.get(aName);
        if (result == null) {
            return null;
        }
        return result.get(bName);
    }

    public function setCurrentFunctionNode(node: Node): Void {
        _currentFunctionNode = node;
    }

    public function defineVariable(name: String, type: AnalyserType, node: Node): Void {
        var variable: AnalyserVariable = {
            name: name,
            type: type,
            origin: node
        };

        _variables.push(variable);
        _varLookup.set(name, variable);
    }

    public function defineFunction(name: String, type: String, params: Array<AnalyserFunctionParam>, origin: Node): Void {
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
        _operatorResultTypes = shallowCopy ? scope._operatorResultTypes.copy() : scope._operatorResultTypes;
        _currentFunctionNode = scope._currentFunctionNode;
    }

}
