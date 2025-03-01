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

    public function new(parser: Parser, ?file: String) {
        _parser = parser;
        _errors = new ErrorContainer();
        _file = file ?? "Internal";
    }

    public function getDefaultType(): AnalyserType {
        return "Unknown";
    }

    public function getBasicType(type: String): AnalyserType {
        return type;
    }

    public function getVaryingType(types: Array<AnalyserType>): AnalyserType {
        return 'Varying<${types.join(", ")}>';
    }

    public inline function inferFirstChildOf(node: Node, scope: AnalyserScope): Null<AnalyserType> {
        if (node.children.length != 0) return inferTypeOf(node.children[0], scope);
        else return getDefaultType();
    }

    /*
enum NodeType {
    VarDef;
    VarType;
    VarAssign;
    VarValue;
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
     */
    public function tryMatchUserType(node: Node, scope: AnalyserScope, expect: AnalyserType, got: AnalyserType, ?err: ErrorType = ErrorType.TypeMismatch): AnalyserType {
        if (expect != got) {
            emitError(node, err, 'expected ${expect} but got ${got}');
        }

        return got;
    }

    public function inferTypeOf(node: Node, scope: AnalyserScope): Null<AnalyserType> {
        if (node == null) return null;
        if (node.analysisType != null) return node.analysisType;
        if (node.analysisScope == null) node.analysisScope = scope;

        var resType: Null<AnalyserType> = "Unknown";

        switch(node.type) {
            case NodeType.StringLiteral:
                resType = "CString";
            case NodeType.IntLiteral:
                resType = "Int32";
            case NodeType.FloatLiteral:
                resType = "Float64";
            case NodeType.BooleanLiteral:
                resType = "Bool";
            case NodeType.Identifier:
                resType = scope.getVariable(node.value)?.type ?? getDefaultType();
            case NodeType.SubExpression | NodeType.OperationLeft | NodeType.OperationRight | NodeType.UnaryOp | NodeType.TernaryTrue | NodeType.TernaryFalse | NodeType.TernaryCond | NodeType.FunctionCallParam:
                resType = inferFirstChildOf(node, scope);
            case NodeType.FunctionDecl:
                var returnTypeNode: Node = findChildOfType(node, NodeType.FunctionDeclReturnType);
                var returnType: AnalyserType = returnTypeNode?.value ?? getDefaultType();

                setTypeOfNode(node, returnType, scope);
                scope.defineFunction(node.value, returnType, [], node);
            case NodeType.FunctionCall:
                var functionInfo: AnalyserFunction = scope.getFunction(node.value);
                if (functionInfo == null) {
                    emitError(node, ErrorType.FunctionNotDefined, 'Function ${node.value} is not defined');
                    resType = getDefaultType();
                } else {
                    resType = functionInfo.type;
                }
            case NodeType.FunctionDeclParam:
                resType = inferTypeOf(findChildOfType(node, NodeType.FunctionDeclParamType), scope);
                scope.defineVariable(node.value, resType, node);
            case NodeType.FunctionDeclParamType:
                resType = node.value ?? getDefaultType();
            case NodeType.FunctionDeclReturnType:
                resType = node.value ?? getDefaultType();
            case NodeType.Return:
                resType = inferFirstChildOf(node, scope);

                var functionNode: Node = scope.getCurrentFunctionNode();
                if (functionNode == null) {
                    emitError(node, ErrorType.ReturnOutsideFunction, "Return statement outside of function");
                } else {
                    var returnType: AnalyserType = getUserSetType(functionNode);
                    if (returnType != null && resType != returnType) {
                        resType = tryMatchUserType(node, scope, returnType, resType, ErrorType.ReturnTypeMismatch);
                    }

                    var returnTypeNode: Node = findChildOfType(functionNode, NodeType.FunctionDeclReturnType);
                    if (returnTypeNode == null) {
                        var returnTypeNode: Node = createNode(NodeType.FunctionDeclReturnType, functionNode, null, null, resType);
                        setTypeOfNode(returnTypeNode, resType, scope);
                        setTypeOfNode(functionNode, resType, scope);
                        scope.getFunction(functionNode.value).type = resType;
                        functionNode.children.unshift(returnTypeNode);
                    }
                }
            case NodeType.FunctionCall:
            case NodeType.Ternary:
                var trueCond: Node = findChildOfType(node, NodeType.TernaryTrue);
                var falseCond: Node = findChildOfType(node, NodeType.TernaryFalse);

                if (trueCond == null || falseCond == null) {
                    resType = getDefaultType();
                } else {
                    var trueCondType: AnalyserType = inferTypeOf(trueCond, scope);
                    var falseCondType: AnalyserType = inferTypeOf(falseCond, scope);
                    resType = trueCondType != falseCondType ? getVaryingType([trueCondType, falseCondType]) : trueCondType;
                }
            case NodeType.BinaryOp:
                var left: Node = findChildOfType(node, NodeType.OperationLeft);
                var right: Node = findChildOfType(node, NodeType.OperationRight);

                if (left == null || right == null) {
                    resType = getDefaultType();
                } else {
                    var leftType: AnalyserType = inferTypeOf(left, scope);
                    var rightType: AnalyserType = inferTypeOf(right, scope);

                    if (_compareOps.indexOf(node.value) != -1) {
                        resType = "Bool";
                    } else {
                        resType = scope.findOperatorResultType(leftType, rightType) ?? propagateTypeToChildren(node, scope, "Int32"); // default to Int32
                    }
                }
            default:
                resType = getDefaultType();
        }

        setTypeOfNode(node, resType, scope);
        return resType;
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

    public function propagateTypeToChildren(node: Node, scope: AnalyserScope, type: AnalyserType): AnalyserType {
        for (child in node.children) {
            if (inferTypeOf(child, scope) == getDefaultType()) {
                setTypeOfNode(child, type, scope);
                propagateTypeToChildren(child, scope, type);
            }
        }

        return type;
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

    public function getUserSetType(node: Node): Null<AnalyserType> {
        switch(node.type) {
            case NodeType.VarDef:
                var typeNode: Node = findChildOfType(node, NodeType.VarType);
                return typeNode?.value;
            case NodeType.FunctionDecl:
                var typeNode: Node = findChildOfType(node, NodeType.FunctionDeclReturnType);
                return typeNode?.value;
            case NodeType.FunctionDeclParam:
                var typeNode: Node = findChildOfType(node, NodeType.FunctionDeclParamType);
                return typeNode?.value;
            default:
                return node.analysisType; // default to inferred type
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

    public function runAtNode(node: Node, scope: AnalyserScope): Void {
        inferTypeOf(node, scope);

        var subScope: AnalyserScope = getNodeScope(node, scope);
        for (child in node.children) {
            runAtNode(child, subScope);
        }
    }

    public function getErrors(): ErrorContainer {
        return _errors;
    }

    public function run(): Void {
        var scope: AnalyserScope = new AnalyserScope(this);
        scope.addOperatorType("Float32", "Float32", "Float32", true);
        scope.addOperatorType("Float64", "Float64", "Float64", true);
        scope.addOperatorType("Float32", "Float64", "Float64", true);
        scope.addOperatorType("Int32", "Float32", "Float32", true);
        scope.addOperatorType("Int32", "Float64", "Float64", true);
        scope.addOperatorType("Int64", "Float32", "Float64", true);
        scope.addOperatorType("Int64", "Float64", "Float64", true);
        scope.addOperatorType("Int32", "Int32", "Int32", true);
        scope.addOperatorType("Int64", "Int64", "Int64", true);
        scope.addOperatorType("Int32", "Int64", "Int64", true);

        runAtNode(_parser.getRoot(), scope);
    }

}
