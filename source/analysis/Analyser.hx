package analysis;

import errors.ErrorContainer;
import ast.Parser;
import ast.Node;
import ast.NodeType;
import errors.ErrorType;
import errors.Error;
import tokenizer.Token;
import data.ProjectData;

class Analyser {

    private var _errors: ErrorContainer;
    private var _parser: Parser;
    private var _solver: AnalyserSolver;
    private var _file: String;
    private var _mainScope: AnalyserScope;
    private var _project: ProjectData;
    private var _toRemapDecls: Array<AnalyserFunction> = [];
    private var _toRemapCalls: Array<{ node: Node, func: AnalyserFunction }> = [];

    private var _compareOps: Array<String> = ["||", "&&", "|", "^", "&", "==", "!=", "<", "<=", ">", ">=", "!", "~"];
    private var TCSizeT: AnalyserFixedType = AnalyserType.createFixedType("CSizeT");
    private var TInt32: AnalyserFixedType = AnalyserType.createFixedType("Int32");
    private var TInt64: AnalyserFixedType = AnalyserType.createFixedType("Int64");
    private var TFloat32: AnalyserFixedType = AnalyserType.createFixedType("Float32");
    private var TFloat64: AnalyserFixedType = AnalyserType.createFixedType("Float64");
    private var TBool: AnalyserFixedType = AnalyserType.createFixedType("Bool");
    private var TCString: AnalyserFixedType = AnalyserType.createFixedType("CString");
    private var TVoid: AnalyserFixedType = AnalyserType.createFixedType("Void");
    private var TUnknown: AnalyserFixedType = AnalyserType.createUnknownType().toFixed();

    public function new(parser: Parser, project: ProjectData, ?file: String) {
        _parser = parser;
        _errors = new ErrorContainer();
        _solver = new AnalyserSolver(this);
        _file = file ?? "Internal";
        _mainScope = new AnalyserScope(this);
        _project = project;
    }

    public function getFile(): String {
        return _file;
    }

    public function createNode(type: NodeType, parent: Node, ?tokenStart: Token, ?tokenEnd: Token, ?value: String): Node {
        if (tokenEnd == null) {
            tokenEnd = tokenStart;
        }

        return {
            type: type,
            value: value,
            line: tokenStart?.line ?? 0,
            column: tokenStart?.column ?? 0,
            endLine: tokenEnd?.line ?? 0,
            endColumn: tokenEnd?.column ?? 0,
            parent: parent,
            children: []
        }
    }

    public function emitError(node: Node, ?type: ErrorType, ?msg: String): Void {
        var err: Error = {
            message: msg ?? "Generic Error",
            type: type ?? ErrorType.GenericError,
            position: { line: node?.line ?? 0, column: node?.column ?? 0, file: _file },
            stack: []
        };

        _errors.addError(err);
    }

    public function findParentOfType(node: Node, type: NodeType): Null<Node> {
        var parent: Node = node.parent;
        while (parent != null) {
            if (parent.type == type) {
                return parent;
            }
            parent = parent.parent;
        }
        return null;
    }

    public function findChildOfType(node: Node, type: NodeType): Node {
        for (child in node.children) {
            if (child.type == type) {
                return child;
            }
        }
        return null;
    }

    public function findAllChildrenOfType(node: Node, type: NodeType): Array<Node> {
        var out = [];
        for (child in node.children) {
            if (child.type == type) {
                out.push(child);
            }
        }
        return out;
    }

    public function getUserSetType(node: Node): AnalyserType {
        switch(node.type) {
            case NodeType.VarDef:
                var typeNode: Node = findChildOfType(node, NodeType.VarType);
                return AnalyserType.createType(typeNode?.value);
            case NodeType.FunctionDecl:
                var typeNode: Node = findChildOfType(node, NodeType.FunctionDeclReturnType);
                return AnalyserType.createType(typeNode?.value);
            case NodeType.FunctionDeclParam:
                var typeNode: Node = findChildOfType(node, NodeType.FunctionDeclParamType);
                return AnalyserType.createType(typeNode?.value);
            default:
                return AnalyserType.createUnknownType();
        }
    }

    public function getNodeScope(node: Node, scope: AnalyserScope): AnalyserScope {
        switch (node.type) {
            case NodeType.FunctionDecl:
                var s = new AnalyserScope(this);
                s.copyFromScope(scope, true);
                s.setCurrentFunctionNode(node);
                return s;
            case NodeType.IfStatement:
                var s = new AnalyserScope(this);
                s.copyFromScope(scope, true);
                return s;
            case NodeType.WhileLoop:
                var s = new AnalyserScope(this);
                s.copyFromScope(scope, true);
                return s;
            case NodeType.ForLoopBody:
                var s = new AnalyserScope(this);
                s.copyFromScope(scope, true);
                return s;
            default:
                return scope;
        }
    }

    public function createNodeConstraintsAndVerify(node: Node, scope: AnalyserScope): Void {
        switch (node.type) {
            case NodeType.ClassDecl:
                _parser.getTypes().addAlclToCTypeMapping(node.value, '__alcl_classptr_${node.value}*');
                mustHaveBetweenChildrenAmount(node, 1, 2);

            case NodeType.FunctionCall:
                var func = scope.getFunction(node.value);
                if (func == null) {
                    scope.markFunctionUsage(node, node.value);
                } else {
                    var params = findAllChildrenOfType(node, NodeType.FunctionCallParam);
                    if (params.length != func.params.length) {
                        emitError(node, ErrorType.ArgumentCountMismatch, 'function ${func.name} expected ${func.params.length} arguments, got ${params.length}');
                    } else {
                        for (i in 0...params.length) {
                            addTypeConstraint(params[i].children[0], func.params[i].type, params[i].analysisType, INFERENCE_USAGE);
                        }
                    }

                    if (func.isExtern) {
                        var headers = func.headers;
                        for (header in headers) {
                            _parser.ensureHeader(header);
                        }
                    }

                    if (func.remapTo != null) {
                        _toRemapCalls.push({
                            node: node,
                            func: func
                        });
                    }

                    addTypeConstraint(node, node.analysisType, func.type, INFERENCE);
                }

            case NodeType.FunctionDecl:
                if (node.parent.type == NodeType.ClassBody) {
                    var thisNode: Node = createNode(NodeType.FunctionDeclParam, node, null, null, 'this');
                    var thisTypeNode: Node = createNode(NodeType.FunctionDeclParamType, thisNode, null, null, node.parent.parent.value);
                    thisNode.children.push(thisTypeNode);
                    thisNode.analysisScope = node.analysisScope;
                    thisNode.analysisType = AnalyserType.createUnknownType();

                    thisTypeNode.analysisType = AnalyserType.createUnknownType();
                    thisTypeNode.analysisScope = node.analysisScope;

                    node.children.unshift(thisNode);
                }

                var returnType = findChildOfType(node, NodeType.FunctionDeclReturnType);
                var params = findAllChildrenOfType(node, NodeType.FunctionDeclParam);
                var fParams: Array<AnalyserFunctionParam> = [];

                for (param in params) {
                    var paramType = findChildOfType(param, NodeType.FunctionDeclParamType);
                    if (paramType != null) {
                        param.analysisType.setTypeStr(paramType.value);
                    }

                    fParams.push({
                        name: param.value,
                        type: param.analysisType,
                        origin: param
                    });

                    scope.defineVariable(param.value, param.analysisType, param, true);
                }

                if (returnType != null) {
                    node.analysisType.setTypeStr(returnType.value);
                }

                var existing = scope.getFunction(node.value);
                if (existing != null && existing.defined) {
                    emitError(node, ErrorType.FunctionAlreadyDefined, 'function ${node.value} already defined');
                }

                var funcName = node.value;
                var remapTo = node.value;
                var nativeBody = findChildOfType(node, NodeType.FunctionDeclNativeBody);
                var externBody = findChildOfType(node, NodeType.FunctionDeclExternBody);
                var noRemapTag = findChildOfType(node, NodeType.FunctionDeclNoRemap);
                var body = findChildOfType(node, NodeType.FunctionDeclBody);

                if (externBody == null && noRemapTag == null && !_project.hasDefine('no_remap')) {
                    remapTo = '__alcl_${funcName}';
                }

                if (node.parent.type == NodeType.ClassBody && !_project.hasDefine('no_remap')) {
                    remapTo = '__alcl_method_${node.parent.parent.value}_${funcName}';
                }

                node.parent.analysisScope.defineFunction(funcName, node.analysisType, fParams, node, node.value);
                addTypeHint(node, TVoid, node.analysisType);

                var mustHaveAllTypes = nativeBody != null || externBody != null;
                if (mustHaveAllTypes) {
                    if (node.analysisType.isUnknown()) {
                        emitError(node, ErrorType.NativeFunctionMissingTypes, 'native/extern function ${funcName} must have a return type');
                    }

                    for (param in fParams) {
                        if (param.type.isUnknown()) {
                            emitError(param.origin, ErrorType.NativeFunctionMissingTypes, 'native/extern function ${funcName} must have a type for parameter ${param.name}');
                        }
                    }
                }

                var func = node.parent.analysisScope.getFunction(funcName);

                if (externBody != null) {
                    func.isExtern = true;
                    func.remapTo = externBody.value;

                    var headers = findAllChildrenOfType(node, NodeType.FunctionDeclExternHeader);
                    for (header in headers) {
                        func.headers.push(header.value);
                    }
                } else {
                    func.remapTo = remapTo;
                }

                _toRemapDecls.push(func);

                if (body != null) { // body is deferred, so we have to run it here
                    runAtNode(body, scope);
                }

            case NodeType.Ternary:
                var ternaryTrue = findChildOfType(node, NodeType.TernaryTrue);
                var ternaryFalse = findChildOfType(node, NodeType.TernaryFalse);
                mustHaveExactChildrenAmount(node, 3);
                addTypeConstraint(ternaryTrue.children[0], node.analysisType, ternaryTrue?.analysisType, INFERENCE);
                addTypeConstraint(ternaryFalse.children[0], node.analysisType, ternaryFalse?.analysisType, INFERENCE);

            case NodeType.VarType | NodeType.FunctionDeclParamType | NodeType.FunctionDeclReturnType:
                mustHaveExactChildrenAmount(node, 0);
                node.analysisType.setTypeStr(node.value);

            case NodeType.VarDef:
                var varType = findChildOfType(node, NodeType.VarType);
                var varValue = findChildOfType(node, NodeType.VarValue);
                mustHaveBetweenChildrenAmount(node, 0, 2);

                if (varType != null) {
                    node.analysisType.setTypeStr(varType.value);
                }

                if (varValue != null) {
                    addTypeConstraint(varValue.children[0], node.analysisType, varValue.analysisType, INFERENCE);
                }

                if (scope.getVariable(node.value) != null) {
                    emitError(node, ErrorType.VariableAlreadyDefined, 'variable ${node.value} already defined');
                }

                scope.defineVariable(node.value, node.analysisType, node, varValue != null);

            case NodeType.VarAssign:
                mustHaveExactChildrenAmount(node, 1);
                var varValue = findChildOfType(node, NodeType.VarValue);
                var variable = scope.getVariable(node.value);

                addTypeConstraint(varValue.children[0], node.analysisType, varValue?.analysisType, INFERENCE);

                if (variable == null) {
                    emitError(node, ErrorType.UndefinedVariable, 'undefined variable ${node.value}');
                } else {
                    addTypeConstraint(varValue.children[0], variable.type, varValue?.analysisType, INFERENCE);
                    variable.isInitialized = true;
                }

            case NodeType.Identifier:
                mustHaveExactChildrenAmount(node, 0);
                var variable = scope.getVariable(node.value);

                if (variable == null) {
                    emitError(node, ErrorType.UndefinedVariable, 'undefined variable ${node.value}');
                } else {
                    if (!variable.isInitialized) {
                        emitError(node, ErrorType.UninitializedVariable, 'uninitialized variable ${node.value}');
                    }

                    addTypeConstraint(node, variable.type, node.analysisType, USER);
                }

            case NodeType.IfStatementElse:
                nodeBeforeMustBeOneOf(node, [NodeType.IfStatement, NodeType.IfStatementElseIf]);
                mustHaveExactChildrenAmount(node, 1);

            case NodeType.IfStatementElseIf:
                nodeBeforeMustBeOneOf(node, [NodeType.IfStatement, NodeType.IfStatementElseIf]);
                mustHaveExactChildrenAmount(node, 2);

            case NodeType.BinaryOp:
                var left = findChildOfType(node, NodeType.OperationLeft);
                var right = findChildOfType(node, NodeType.OperationRight);
                mustHaveExactChildrenAmount(node, 2);
                addTypeConstraint(right.children[0], left?.analysisType, right?.analysisType, INFERENCE); // Ensure we are comparing the same thing

                if (_compareOps.indexOf(node.value) != -1) {
                    addTypeConstraint(node, TBool, node.analysisType, INFERENCE);
                } else {
                    addNumericalTypeConstraint(node, node.analysisType, INFERENCE);
                    addTypeConstraint(left.children[0], node.analysisType, left?.analysisType, INFERENCE);
                }

                addTypeHint(node, TInt32, left?.analysisType);
                addTypeHint(node, TInt32, right?.analysisType);

            case NodeType.UnaryOp:
                mustHaveExactChildrenAmount(node, 1);
                copyTypeFromFirstChild(node);
                switch(node.value) {
                    case '-':
                        addNumericalTypeConstraint(node, node.analysisType, INFERENCE);
                        addTypeHint(node, TInt32, node.analysisType);
                    case '!':
                        addTypeConstraint(node.children[0], TBool, node.analysisType, INFERENCE);
                    default:
                        emitError(node, ErrorType.SyntaxError, 'unexpected unary operator ${node.value}');
                }

            case NodeType.Cast:
                mustHaveExactChildrenAmount(node, 1);
                node.analysisType.setTypeStr(node.value);

            case NodeType.StringLiteral:
                mustHaveExactChildrenAmount(node, 0);
                addTypeConstraint(node, TCString, node.analysisType, CONSTANT);

            case NodeType.BooleanLiteral:
                mustHaveExactChildrenAmount(node, 0);
                addTypeConstraint(node, TBool, node.analysisType, CONSTANT);

            case NodeType.FloatLiteral:
                mustHaveExactChildrenAmount(node, 0);
                addTypeConstraint(node, TFloat64, node.analysisType, CONSTANT);

            case NodeType.NullLiteral:
                mustHaveExactChildrenAmount(node, 0);

            case NodeType.IntLiteral:
                mustHaveExactChildrenAmount(node, 0);
                addTypeConstraint(node, TInt32, node.analysisType, CONSTANT);

            case NodeType.ForLoop:
                mustHaveExactChildrenAmount(node, 4);

            case NodeType.WhileLoop:
                mustHaveExactChildrenAmount(node, 2);

            case NodeType.OperationLeft | NodeType.OperationRight | NodeType.TernaryTrue | NodeType.TernaryFalse | NodeType.SubExpression | NodeType.ForLoopIter | NodeType.ForLoopInit | NodeType.FunctionCallParam | NodeType.VarValue:
                mustHaveExactChildrenAmount(node, 1);
                copyTypeFromFirstChild(node);

            case NodeType.Return:
                mustHaveExactChildrenAmount(node, 1);
                copyTypeFromFirstChild(node);
                errorIfNull(node, scope.getCurrentFunctionNode(), ErrorType.ReturnOutsideFunction, 'return statement outside function');
                addTypeConstraint(node.children[0], scope.getCurrentFunctionNode()?.analysisType, node.analysisType, INFERENCE);

            case NodeType.LoopContinue | NodeType.LoopBreak:
                mustHaveExactChildrenAmount(node, 0);
                if (findParentOfType(node, NodeType.WhileLoop) == null && findParentOfType(node, NodeType.ForLoop) == null) {
                    emitError(node, ErrorType.SyntaxError, '${node.type} statement outside loop');
                }

            case NodeType.TernaryCond | NodeType.IfStatementCond | NodeType.WhileLoopCond | NodeType.ForLoopCond:
                mustHaveExactChildrenAmount(node, 1);
                copyTypeFromFirstChild(node);
                addTypeConstraint(node.children[0], TBool, node.analysisType, INFERENCE);

            case NodeType.Root | NodeType.CCode | NodeType.ForLoopBody | NodeType.WhileLoopBody | NodeType.IfStatementBody | NodeType.FunctionDeclNativeBody | NodeType.FunctionDeclBody | NodeType.ClassBody:
                return;

            default:
                if (node.children.length == 1) {
                    addTypeConstraint(node.children[0], node.analysisType, node.children[0].analysisType, INFERENCE);
                }
        }
    }

    public function errorIfNull(node: Node, value: Dynamic, type: ErrorType, message: String): Void {
        if (value == null) emitError(node, type, message);
    }

    public function mustHaveExactChildrenAmount(node: Node, amount: Int): Bool {
        if (node.children.length != amount) {
            if (node.children.length > amount) emitError(node, ErrorType.SyntaxError, 'unexpected ${node.children[amount].type} (${node.children[amount].value})');
            else emitError(node, ErrorType.SyntaxError, 'missing ${amount - node.children.length} children');
            return false;
        }

        return true;
    }

    public function mustHaveBetweenChildrenAmount(node: Node, min: Int, max: Int): Bool {
        if (node.children.length < min || node.children.length > max) {
            if (node.children.length > max) emitError(node, ErrorType.SyntaxError, 'unexpected ${node.children[max].type} (${node.children[max].value})');
            else emitError(node, ErrorType.SyntaxError, 'missing ${min - node.children.length} children');
            return false;
        }

        return true;
    }

    public function nodeBeforeMustBeOneOf(node: Node, types: Array<NodeType>): Bool {
        if (node.parent.children.indexOf(node) == 0) {
            return false;
        }

        var prev = node.parent.children[node.parent.children.indexOf(node) - 1];
        if (types.indexOf(prev.type) == -1) {
            emitError(node, ErrorType.SyntaxError, 'unexpected ${node.type} (${node.value})');
            return false;
        }

        return true;
    }
    public function copyTypeFromFirstChild(node: Node): Void {
        if (node.children.length > 0) {
            addTypeConstraint(node.children[0], node.analysisType, node.children[0].analysisType, INFERENCE);
        }
    }

    public function runAtNode(node: Node, scope: AnalyserScope): Void {
        var subScope: AnalyserScope = getNodeScope(node, scope);
        node.analysisType = AnalyserType.createUnknownType();
        node.analysisScope = subScope;

        for (child in node.children) {
            if (child.type == NodeType.FunctionDeclBody) continue; // defer function body
            runAtNode(child, subScope);
        }

        createNodeConstraintsAndVerify(node, subScope);
    }

    public function getErrors(): ErrorContainer {
        return _errors;
    }

    public function findCastPath(scope: AnalyserScope, from: AnalyserType, to: AnalyserType, isExplicit: Bool = false): Array<AnalyserCastMethod> {
        var queue: Array<{type: AnalyserType, path: Array<AnalyserCastMethod>}> = [{type: from, path: []}];
        var visited: Map<String, Bool> = new Map();

        while (queue.length > 0) {
            var current = queue.shift();
            var currentType = current.type;
            var currentPath = current.path;

            if (currentType.equals(to)) {
                return currentPath;
            }

            if (visited.exists(currentType.toString())) continue;
            visited.set(currentType.toString(), true);

            // Direct cast
            for (c in scope.getCastMethods()) {
                if (c.getFrom().equals(currentType) && (isExplicit || c.isImplicit())) {
                    queue.push({
                        type: c.getTo(),
                        path: currentPath.concat([c])
                    });
                }
            }

            // Pointer<T> -> T
            if (currentType.isComplexType() && currentType.getBaseTypeStr() == "Pointer" && currentType.getParamCount() > 0) {
                var innerType = currentType.getParam(0);
                var innerTypeKey = innerType.toString();

                if (!visited.exists(innerTypeKey)) {
                    var fromPtrCast = AnalyserCastMethod.usingFromPtr(currentType, innerType, true);
                    queue.push({
                        type: innerType,
                        path: currentPath.concat([fromPtrCast])
                    });
                }
            }

            // T -> Pointer<T>
            if (to.isComplexType() && to.getBaseTypeStr() == "Pointer" && to.getParamCount() > 0) {
                var targetInnerType = to.getParam(0);

                if (currentType.equals(targetInnerType)) { // TODO: don't care when explicitly casting? void pointers?
                    var pointerType = AnalyserType.createType("Pointer");
                    pointerType.addParam(currentType);
                    var pointerTypeKey = pointerType.toString();

                    if (!visited.exists(pointerTypeKey)) {
                        var toPtrCast = AnalyserCastMethod.usingToPtr(currentType, pointerType, true);
                        queue.push({
                            type: pointerType,
                            path: currentPath.concat([toPtrCast])
                        });
                    }
                }
            }
        }

        return [];
    }

    public function castNode(node: Node, path: Array<AnalyserCastMethod>): Void {
        for (c in path) {
            var og = node.deepCopy();
            node.children = [];
            node.value = c.getTo().toString();
            node.analysisType = c.getTo();
            node.children.push(og);

            if (c.isUsingCast()) node.type = NodeType.Cast;
            else if (c.isUsingFromPtr()) node.type = NodeType.FromPtr;
            else if (c.isUsingToPtr()) node.type = NodeType.ToPtr;

            if (nodeIsConstant(og) && node.type == NodeType.ToPtr) {
                emitError(node, ErrorType.TypeCastError, 'cannot convert literal to pointer');
            }

            if ((node.type == NodeType.ToPtr || node.type == NodeType.FromPtr) && (og.type != NodeType.Identifier)) {
                emitError(node, ErrorType.TypeCastError, 'only variables can be cast to/from pointers');
            }

            og.parent = node;

            for (idx in 0..._toRemapCalls.length) {
                if (_toRemapCalls[idx].node == node) {
                    _toRemapCalls[idx].node = og;
                }
            }
        }

    }

    public function nodeIsConstant(node: Node): Bool {
        switch(node.type) {
            case NodeType.NullLiteral | NodeType.IntLiteral | NodeType.FloatLiteral | NodeType.StringLiteral | NodeType.BooleanLiteral:
                return true;
            default:
                return false;
        }
    }

    public function isNumericalType(type: AnalyserType): Bool {
        return type.equals(TInt32) || type.equals(TInt64) || type.equals(TFloat32) || type.equals(TFloat64);
    }

    public function addTypeConstraint(origin: Node, want: AnalyserType, with: AnalyserType, priority: AnalyserConstraintPriority): Void {
        if (want == null || with == null) return;

        _solver.addConstraint({
            a: want,
            b: with,
            priority: priority,
            optional: false,
            node: origin
        });
    }

    public function addEitherTypeConstraint(origin: Node, with: AnalyserType, want: Array<AnalyserType>, priority: AnalyserConstraintPriority): Void {
        if (with == null || want == null) return;

        var constraint: AnalyserConstraintEither = {
            type: with,
            allowedTypes: want,
            priority: priority,
            node: origin,
            optional: false
        };

        _solver.addConstraint(constraint);
    }

    inline public function addNumericalTypeConstraint(node: Node, with: AnalyserType, priority: AnalyserConstraintPriority): Void {
        if (with == null) return;
        addEitherTypeConstraint(node, with, [TInt32, TInt64, TFloat32, TFloat64], priority);
    }

    public function addTypeHint(origin: Node, a: AnalyserType, b: AnalyserType): Void {
        if (a == null || b == null) return;

        _solver.addConstraint({
            a: a,
            b: b,
            priority: AnalyserConstraintPriority.HINT,
            optional: true,
            node: origin
        });
    }

    public function getMainScope(): AnalyserScope {
        return _mainScope;
    }

    public function getParser(): Parser {
        return _parser;
    }

    public function clearMainScope(): Void {
        _mainScope = new AnalyserScope(this);
    }

    public function run(libraries: Array<Analyser>): Void {
        var scope: AnalyserScope = getMainScope();

        // Setup scope
        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt32, TCSizeT, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TCSizeT, TInt32, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TCSizeT, TInt64, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TCSizeT, TFloat32, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TCSizeT, TFloat64, true));

        // Pass 1: Merge library scopes into main scope
        for (lib in libraries) {
            scope.mergeScope(lib.getMainScope());
        }

        // Pass 2: Create constraints and verify validity of nodes.
        runAtNode(_parser.getRoot(), scope);

        // Pass 3: Check undefined functions (done in seperate pass to allow for functions calling each other)
        function checkUndefinedFunctions(scope: AnalyserScope): Void {
            for (func in scope.getFunctions()) {
                if (!func.defined) {
                    for (usage in func.usages) {
                        emitError(usage, ErrorType.UndefinedFunction, 'undefined function ${usage.value}');
                    }
                }
            }

            for (child in scope.getChildren()) {
                checkUndefinedFunctions(child);
            }
        }
        checkUndefinedFunctions(scope);

        // Pass 4: Solve constraints
        _solver.solve();

        // Pass 5: Remap
        for (decl in _toRemapDecls) {
            if (decl.origin.type != NodeType.FunctionDecl) continue;
            decl.origin.value = decl.remapTo;
        }

        for (call in _toRemapCalls) {
            call.node.value = call.func.origin.value;
        }

    }

}
