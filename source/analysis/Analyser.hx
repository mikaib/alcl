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
    private var TNull: AnalyserFixedType = AnalyserType.createFixedType("Null");
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

        }
    }

    public function runAtNode(node: Node, scope: AnalyserScope): Void {
        var subScope: AnalyserScope = getNodeScope(node, scope);
        node.analysisType = AnalyserType.createUnknownType();
        node.analysisScope = subScope;

        for (child in node.children) {
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

    public function castNodeTo(node: Node, scope: AnalyserScope, to: AnalyserType): Void {
        if (node.analysisType.equals(to)) return;

        var from: AnalyserType = node.analysisType;
        var path: Array<AnalyserCastMethod> = findCastPath(scope, from, to, true);

        if (path.length == 0) {
            emitError(node, ErrorType.TypeCastError, 'cannot cast ${from} to ${to}');
            return;
        }

        for (cst in path) {
            var tmpNode: Node = node.deepCopy(true, true);
            var tmpType: AnalyserType = cst.getTo().toMutableType();

            // if any parent holds a reference to the type of what we casted, we update it to reflect the casted type.
            // TODO: check for bugs.
            var parent: Node = node.parent;
            while (parent != null) {
                if (parent.analysisType == node.analysisType) {
                    parent.analysisType = tmpType;
                }

                if (parent.parent.analysisScope != parent.analysisScope) {
                    break;
                }

                parent = parent.parent;
            }

            // create cast
            node.type = NodeType.Cast;
            node.value = cst.getTo().toString();
            node.children = [tmpNode];
            node.analysisType = tmpType;
        }
    }

    public function isNumericalType(type: AnalyserType): Bool {
        return type.equals(TInt32) || type.equals(TInt64) || type.equals(TFloat32) || type.equals(TFloat64);
    }

    public function addTypeConstraint(origin: Node, a: AnalyserType, b: AnalyserType, priority: AnalyserConstraintPriority): Void {
        _solver.addConstraint({
            a: a,
            b: b,
            priority: priority,
            node: origin
        });
    }

    public function run(): Void {
        var scope: AnalyserScope = new AnalyserScope(this);

        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt32, TInt64, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt32, TFloat32, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt32, TFloat64, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt64, TFloat64, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TFloat32, TFloat64, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TFloat64, TFloat32, true)); // TODO: review if this should be allowed and/or add a warning to compiler for precision loss unless explicitly casted.

        // Pass 1: Create constraints and verify validity of nodes.
        runAtNode(_parser.getRoot(), scope);

        // Pass 2: Solve constraints
        _solver.solve();
    }

}
