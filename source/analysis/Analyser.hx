package analysis;

import errors.ErrorContainer;
import ast.Parser;
import ast.Node;
import ast.NodeType;
import errors.ErrorType;
import errors.Error;
import tokenizer.Token;

class Analyser {

    private var _errors: ErrorContainer;
    private var _parser: Parser;
    private var _solver: AnalyserSolver;
    private var _file: String;

    private var _compareOps: Array<String> = ["||", "&&", "|", "^", "&", "==", "!=", "<", "<=", ">", ">=", "!", "~"];
    private var TInt32: AnalyserFixedType = AnalyserType.createFixedType("Int32");
    private var TInt64: AnalyserFixedType = AnalyserType.createFixedType("Int64");
    private var TFloat32: AnalyserFixedType = AnalyserType.createFixedType("Float32");
    private var TFloat64: AnalyserFixedType = AnalyserType.createFixedType("Float64");
    private var TBool: AnalyserFixedType = AnalyserType.createFixedType("Bool");
    private var TCString: AnalyserFixedType = AnalyserType.createFixedType("CString");
    private var TVoid: AnalyserFixedType = AnalyserType.createFixedType("Void");
    private var TUnknown: AnalyserFixedType = AnalyserType.createUnknownType().toFixed();

    public function new(parser: Parser, ?file: String) {
        _parser = parser;
        _errors = new ErrorContainer();
        _solver = new AnalyserSolver(this);
        _file = file ?? "Internal";
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
            position: { line: node.line, column: node.column, file: _file },
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
            case NodeType.FunctionCall:
                var func = scope.getFunction(node.value);
                if (func == null) {
                    scope.markFunctionUsage(node, node.value);
                } else {
                    var params = findAllChildrenOfType(node, NodeType.FunctionCallParam);
                    if (params.length != func.params.length) {
                        emitError(node, ErrorType.ArgumentCountMismatch, 'expected ${func.params.length} arguments, got ${params.length}');
                    } else {
                        for (i in 0...params.length) {
                            addTypeConstraint(node, func.params[i].type, params[i].analysisType, INFERENCE_USAGE);
                        }
                    }

                    addTypeConstraint(node, node.analysisType, func.type, INFERENCE);
                }

            case NodeType.FunctionDecl:
                var returnType = findChildOfType(node, NodeType.FunctionDeclReturnType);
                var params = findAllChildrenOfType(node, NodeType.FunctionDeclParam);

                var fParams: Array<AnalyserFunctionParam> = [];
                for (param in params) {
                    var paramType = findChildOfType(param, NodeType.FunctionDeclParamType);
                    if (paramType != null) {
                        addTypeConstraint(param, param.analysisType, paramType.analysisType, USER);
                    }

                    fParams.push({
                        name: param.value,
                        type: param.analysisType,
                        origin: param
                    });

                    scope.defineVariable(param.value, param.analysisType, param, true);
                }

                if (returnType != null) {
                    addTypeConstraint(node, node.analysisType, returnType.analysisType, USER);
                }

                node.parent.analysisScope.defineFunction(node.value, node.analysisType, fParams, node);
                addTypeHint(node, TVoid, node.analysisType);

                var body = findChildOfType(node, NodeType.FunctionDeclBody); // body is deferred, so we have to run it here
                if (body != null) {
                    runAtNode(body, scope);
                }

            case NodeType.Ternary:
                var ternaryTrue = findChildOfType(node, NodeType.TernaryTrue);
                var ternaryFalse = findChildOfType(node, NodeType.TernaryFalse);
                mustHaveExactChildrenAmount(node, 3);
                addTypeConstraint(node, node.analysisType, ternaryTrue?.analysisType, INFERENCE);
                addTypeConstraint(node, node.analysisType, ternaryFalse?.analysisType, INFERENCE);

            case NodeType.VarType | NodeType.FunctionDeclParamType | NodeType.FunctionDeclReturnType:
                mustHaveExactChildrenAmount(node, 0);
                node.analysisType.setTypeStr(node.value);

            case NodeType.VarDef:
                var varType = findChildOfType(node, NodeType.VarType);
                var varValue = findChildOfType(node, NodeType.VarValue);
                mustHaveBetweenChildrenAmount(node, 0, 2);

                if (varType != null) {
                    addTypeConstraint(node, node.analysisType, varType.analysisType, USER);
                }

                if (varValue != null) {
                    addTypeConstraint(node, node.analysisType, varValue.analysisType, INFERENCE);
                }

                scope.defineVariable(node.value, node.analysisType, node, varValue != null);

            case NodeType.VarAssign:
                mustHaveExactChildrenAmount(node, 1);
                var varValue = findChildOfType(node, NodeType.VarValue);
                var variable = scope.getVariable(node.value);

                addTypeConstraint(node, node.analysisType, varValue?.analysisType, INFERENCE);

                if (variable == null) {
                    emitError(node, ErrorType.UndefinedVariable, 'undefined variable ${node.value}');
                } else {
                    addTypeConstraint(node, variable.type, varValue?.analysisType, INFERENCE);
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

                    addTypeConstraint(node, node.analysisType, variable.type, USER);
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
                addTypeConstraint(node, left?.analysisType, right?.analysisType, INFERENCE); // Ensure we are comparing the same thing

                if (_compareOps.indexOf(node.value) != -1) {
                    addTypeConstraint(node, node.analysisType, TBool, INFERENCE);
                } else {
                    addNumericalTypeConstraint(node, node.analysisType, INFERENCE);
                    addTypeConstraint(node, node.analysisType, left?.analysisType, INFERENCE);
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
                        addTypeConstraint(node, TBool, node.analysisType, INFERENCE);
                    default:
                        emitError(node, ErrorType.SyntaxError, 'unexpected unary operator ${node.value}');
                }

            case NodeType.Cast:
                mustHaveExactChildrenAmount(node, 1);
                node.analysisType.setTypeStr(node.value);

            case NodeType.StringLiteral:
                mustHaveExactChildrenAmount(node, 0);
                addTypeConstraint(node, node.analysisType, TCString, CONSTANT);

            case NodeType.BooleanLiteral:
                mustHaveExactChildrenAmount(node, 0);
                addTypeConstraint(node, node.analysisType, TBool, CONSTANT);

            case NodeType.FloatLiteral:
                mustHaveExactChildrenAmount(node, 0);
                addTypeConstraint(node, node.analysisType, TFloat64, CONSTANT);

            case NodeType.NullLiteral:
                mustHaveExactChildrenAmount(node, 0);

            case NodeType.IntLiteral:
                mustHaveExactChildrenAmount(node, 0);
                addTypeConstraint(node, node.analysisType, TInt32, CONSTANT);

            case NodeType.ForLoop:
                mustHaveExactChildrenAmount(node, 4);

            case NodeType.WhileLoop:
                mustHaveExactChildrenAmount(node, 2);

            case NodeType.OperationLeft | NodeType.OperationRight | NodeType.TernaryTrue | NodeType.TernaryFalse | NodeType.SubExpression | NodeType.ForLoopIter | NodeType.ForLoopInit | NodeType.FunctionCallParam:
                mustHaveExactChildrenAmount(node, 1);
                copyTypeFromFirstChild(node);

            case NodeType.Return:
                mustHaveExactChildrenAmount(node, 1);
                copyTypeFromFirstChild(node);
                errorIfNull(node, scope.getCurrentFunctionNode(), ErrorType.ReturnOutsideFunction, 'return statement outside function');
                addTypeConstraint(node, scope.getCurrentFunctionNode()?.analysisType, node.analysisType, INFERENCE);

            case NodeType.LoopContinue | NodeType.LoopBreak:
                mustHaveExactChildrenAmount(node, 0);
                if (findParentOfType(node, NodeType.WhileLoop) == null && findParentOfType(node, NodeType.ForLoop) == null) {
                    emitError(node, ErrorType.SyntaxError, '${node.type} statement outside loop');
                }

            case NodeType.TernaryCond | NodeType.IfStatementCond | NodeType.WhileLoopCond | NodeType.ForLoopCond:
                mustHaveExactChildrenAmount(node, 1);
                copyTypeFromFirstChild(node);
                addTypeConstraint(node, TBool, node.analysisType, INFERENCE);

            case NodeType.Root | NodeType.CCode | NodeType.ForLoopBody | NodeType.WhileLoopBody | NodeType.IfStatementBody | NodeType.FunctionDeclNativeBody | NodeType.FunctionDeclBody:
                return;

            default:
                if (node.children.length == 1) {
                    addTypeConstraint(node, node.analysisType, node.children[0].analysisType, INFERENCE);
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
            addTypeConstraint(node, node.analysisType, node.children[0].analysisType, INFERENCE);
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

            for (c in scope.getCastMethods()) {
                if (c.getFrom().equals(currentType) && (isExplicit || c.isImplicit())) {
                    queue.push({
                        type: c.getTo(),
                        path: currentPath.concat([c])
                    });
                }
            }
        }

        return [];
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

    public function run(): Void {
        var scope: AnalyserScope = new AnalyserScope(this);

        // Pass 1: Create constraints and verify validity of nodes.
        runAtNode(_parser.getRoot(), scope);

        // Pass 2: Check undefined functions (needed for recursive functions)
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

        // Pass 3: Solve constraints
        _solver.solve();
    }

}
