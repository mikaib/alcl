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
        _file = file ?? "Internal";
    }

    public inline function inferFirstChildOf(node: Node, scope: AnalyserScope): Null<AnalyserType> {
        if (node.children.length != 0) {
            var child: Node = node.children[0];

            inferType(child, scope);
            return child.analysisType;
        } else {
            return AnalyserType.createUnknownType();
        }
    }

    public function tryMatchUserType(node: Node, scope: AnalyserScope, expect: AnalyserType, got: AnalyserType, ?err: ErrorType = ErrorType.TypeMismatch): AnalyserType {
        if (expect != got) {
            emitError(node, err, 'expected ${expect} but got ${got}');
        }

        return got;
    }

    /*
    FunctionDecl;
    FunctionDeclParam;
    FunctionDeclParamType;
    FunctionDeclReturnType;
    FunctionDeclBody;
    FunctionDeclNativeBody;
    FunctionCall;
    FunctionCallParam;
    VarDef;
    VarType;
    VarAssign;
    VarValue;
    StringLiteral;
    FloatLiteral;
    IntLiteral;
    BooleanLiteral;
    Identifier;
    ForLoop;
    ForLoopInit;
    ForLoopCond;
    ForLoopIter;
    ForLoopBody;
    WhileLoop;
    WhileLoopCond;
    WhileLoopBody;
    LoopBreak;
    LoopContinue;
    IfStatement;
    IfStatementElse;
    IfStatementElseIf;
    IfStatementCond;
    IfStatementBody;
    Ternary;
    TernaryCond;
    TernaryTrue;
    TernaryFalse;
    UnaryOp;
    BinaryOp;
    Return;
     */
    public function inferType(node: Node, scope: AnalyserScope): Void {
        if (node == null) return;
        if (node.analysisType == null) node.analysisType = AnalyserType.createUnknownType();
        if (node.analysisScope == null) node.analysisScope = scope;
        if (!node.analysisType.equals(TUnknown)) return;

        switch(node.type) {
            case NodeType.Root | NodeType.None | NodeType.CCode:
                return; // skip
            default:
                node.analysisType = inferFirstChildOf(node, scope);
        }
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

    public function setTypeOfNode(node: Node, type: AnalyserType, scope: AnalyserScope): Void {
        node.analysisType = type;
    }

    public function getNodeScope(node: Node, scope: AnalyserScope): AnalyserScope {
        switch (node.type) {
            case NodeType.FunctionDecl:
                var s = new AnalyserScope(this);
                s.copyFromScope(scope, true);
                s.setCurrentFunctionNode(node);
                return s;
            default:
                return scope;
        }
    }

    public function getTypeMismatchErr(node: Node): ErrorType {
        switch (node.type) {
            case NodeType.Return:
                return ErrorType.ReturnTypeMismatch;
            default:
                return ErrorType.TypeMismatch;
        }
    }

    public function runAtNode(node: Node, scope: AnalyserScope): Void {
        inferType(node, scope);

        var subScope: AnalyserScope = getNodeScope(node, scope);
        for (child in node.children) {
            runAtNode(child, subScope);
        }

        var userType: AnalyserType = getUserSetType(node);
        if (!node.analysisType.isUnknown() && !userType.isUnknown()) {
            tryMatchUserType(node, scope, userType, node.analysisType, getTypeMismatchErr(node));
        }
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

    public function run(): Void {
        var scope: AnalyserScope = new AnalyserScope(this);
        scope.addOperatorType(TInt32, TInt32, TInt32, true); // Int32 + Int32 = Int32
        scope.addOperatorType(TInt64, TInt64, TInt64, true); // Int64 + Int64 = Int64
        scope.addOperatorType(TFloat32, TFloat32, TFloat32, true); // Float32 + Float32 = Float32
        scope.addOperatorType(TFloat64, TFloat64, TFloat64, true); // Float64 + Float64 = Float64

        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt32, TInt64, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt32, TFloat32, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt32, TFloat64, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt64, TFloat64, true));

        runAtNode(_parser.getRoot(), scope);
    }

}
