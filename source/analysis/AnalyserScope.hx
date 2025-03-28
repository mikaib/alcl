package analysis;
import ast.Node;
import errors.ErrorType;

class AnalyserScope {

    private static var _count: Int = 0;

    private var _analyser: Analyser;
    private var _variables: Array<AnalyserVariable>;
    private var _functions: Array<AnalyserFunction>;
    private var _castMethods: Array<AnalyserCastMethod>;
    private var _varLookup: Map<String, AnalyserVariable>;
    private var _funcLookup: Map<String, AnalyserFunction>;
    private var _children: Array<AnalyserScope>;
    private var _id: Int;
    private var _currentFunctionNode: Node;

    public function new(analyser: Analyser) {
        _analyser = analyser;
        _varLookup = [];
        _funcLookup = [];
        _variables = [];
        _functions = [];
        _castMethods = [];
        _children = [];
        _id = _count++;
    }

    public function isInFunction(): Bool {
        return _currentFunctionNode != null;
    }

    public function markFunctionUsage(node: Node, name: String): Void {
        var func: Null<AnalyserFunction> = getFunction(name);
        if (func == null) {
            func = {
                name: name,
                type: AnalyserType.createUnknownType(),
                params: [],
                origin: null,
                usages: [],
                defined: false
            };

            _functions.push(func);
            _funcLookup.set(name, func);
        }

        func.usages.push(node);
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

    public function getChildren(): Array<AnalyserScope> {
        return _children;
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

        for (child in _children) {
            child.defineVariable(name, type, node, initialized);
        }
    }

    public function defineFunction(name: String, type: AnalyserType, params: Array<AnalyserFunctionParam>, origin: Node, remapTo: Null<String> = null): Void {
        if (_funcLookup.exists(name)) {
            var fn = _funcLookup.get(name);
            if (!fn.defined) {
                fn.params = params;
                fn.origin = origin;
                fn.defined = true;
                fn.remapTo = remapTo;
                _analyser.addTypeConstraint(origin, type, fn.type, AnalyserConstraintPriority.INFERENCE);

                for (child in _children) {
                    child.defineFunction(name, type, params, origin, remapTo);
                }

                for (usage in fn.usages) {
                    _analyser.createNodeConstraintsAndVerify(usage, usage.analysisScope);
                }

                fn.usages = [];
            }
        }

        var func: AnalyserFunction = {
            name: name,
            type: type,
            params: params,
            origin: origin,
            usages: [],
            defined: true,
            remapTo: remapTo
        };

        _functions.push(func);
        _funcLookup.set(name, func);

        for (child in _children) {
            child.defineFunction(name, type, params, origin, remapTo);
        }
    }

    public function copyFromScope(scope: AnalyserScope, shallowCopy: Bool = true): Void {
        _variables = shallowCopy ? scope._variables.copy() : scope._variables;
        _functions = shallowCopy ? scope._functions.copy() : scope._functions;
        _varLookup = shallowCopy ? scope._varLookup.copy() : scope._varLookup;
        _funcLookup = shallowCopy ? scope._funcLookup.copy() : scope._funcLookup;
        _castMethods = shallowCopy ? scope._castMethods.copy() : scope._castMethods;
        _currentFunctionNode = scope._currentFunctionNode;
        scope._children.push(this);
    }

    public function mergeScope(scope: AnalyserScope, mergeVars: Bool = false, mergeChildren: Bool = false): Void {
        if (mergeVars) {
            for (variable in scope._variables) {
                if (variable.fromMerger) {
                    continue;
                }

                if (!_varLookup.exists(variable.name)) {
                    var newVar = variable.copy();
                    newVar.fromMerger = true;
                    _variables.push(newVar);
                    _varLookup.set(variable.name, newVar);
                } else {
                    _analyser.emitError(null, ErrorType.VariableAlreadyDefined, 'variable ' + variable.name + ' is already defined');
                }
            }
        }

        for (func in scope._functions) {
            if (func.fromMerger) {
                continue;
            }

            if (!_funcLookup.exists(func.name)) {
                var newFunc = func.copy();
                newFunc.fromMerger = true;
                _functions.push(newFunc);
                _funcLookup.set(func.name, newFunc);
            } else {
                _analyser.emitError(null, ErrorType.FunctionAlreadyDefined, 'function ' + func.name + ' is already defined');
            }
        }

        for (castMethod in scope._castMethods) {
            _castMethods.push(castMethod);
        }

        if (mergeChildren) {
            for (child in scope._children) {
                _children.push(child);
            }
        }
    }

    public function toDebugString(): String {
        return '#' + _id;
    }

}
