package ast;

import tokenizer.Tokenizer;
import tokenizer.TokenType;
import tokenizer.Token;
import util.Logging;
import errors.ErrorContainer;
import errors.ErrorType;
import typer.Typer;

class Parser {

    private var _tokenizer: Tokenizer;
    private var _root: Node;
    private var _errors: ErrorContainer;
    private var _headers: Array<String>;
    private var _libRequirements: Array<String>;
    private var _types: Typer;
    private var _wantGlobalLib: Bool;
    private var _currentDir: String;

    public function new(tokenizer: Tokenizer) {
        _tokenizer = tokenizer;
        _errors = new ErrorContainer();
        _types = new Typer();
        _headers = [];
        _libRequirements = [];
        _root = {
            type: NodeType.Root,
            value: null,
        }
        _wantGlobalLib = true;
    }

    public function doesWantGlobalLib(): Bool {
        return _wantGlobalLib;
    }

    public function getTokenizer(): Tokenizer {
        return _tokenizer;
    }

    public function ensureHeader(header: String) {
        if (_headers.indexOf(header) == -1) {
            _headers.push(header);
        }
    }

    public function ensureRequirement(lib: String) {
        if (_libRequirements.indexOf(lib) == -1) {
            _libRequirements.push(lib);
        }
    }

    public function getHeaders(): Array<String> {
        return _headers;
    }

    public function getRoot(): Node {
        return _root;
    }

    public function getErrors(): ErrorContainer {
        return _errors;
    }

    public function getTypes(): Typer {
        return _types;
    }

    public function getLibRequirements(): Array<String> {
        return _libRequirements;
    }

    public function parse() {
        this.parseSlice(_tokenizer.tokens.copy(), _root);
    }

    public function parseSlice(slice: Array<Token>, node: Node): Void {
        var ctx = new ParserContext(slice, this, node);
        ctx.parse();
    }

    public function print(?node: Node, depth: Int = 0): Void {
        if (node == null) {
            node = _root;
        }

        var indent = "";
        for (i in 0...depth) {
            indent += "    ";
        }

        Logging.print('$indent ${node.type} ${node.value} (${node.line}:${node.column} to ${node.endLine}:${node.endColumn}) [t: ${node.analysisType.toDebugString()}, s: ${node.analysisScope.toDebugString()}]');
        for (child in node.children) {
            print(child, depth + 1);
        }
    }

    public function printDotFile(?node: Node): Void {
        if (node == null) {
            node = _root;
        }

        var output = new Array<String>();
        var nodeCount = 0;
        var nodeIds = new Map<Node, Int>();

        function getNodeId(node: Node): Int {
            return nodeIds.get(node);
        }

        function assignNodeId(node: Node): Int {
            if (!nodeIds.exists(node)) {
                nodeCount++;
                nodeIds.set(node, nodeCount);
            }
            return nodeIds.get(node);
        }

        function getColor(nodeType: NodeType): String {
            return switch (nodeType) {
                case NodeType.Root: "lightblue";
                case NodeType.FunctionDecl, NodeType.FunctionDeclParam, NodeType.FunctionDeclParamType, NodeType.FunctionDeclReturnType, NodeType.FunctionDeclBody, NodeType.FunctionDeclNativeBody: "lightgreen";
                case NodeType.FunctionCall, NodeType.FunctionCallParam: "lightcoral";
                case NodeType.VarDef, NodeType.VarType, NodeType.VarAssign, NodeType.VarValue: "lightyellow";
                case NodeType.StringLiteral, NodeType.IntLiteral, NodeType.FloatLiteral, NodeType.Identifier: "lightgray";
                case NodeType.WhileLoop, NodeType.WhileLoopCond, NodeType.WhileLoopBody: "lightpink";
                case NodeType.ForLoop, NodeType.ForLoopInit, NodeType.ForLoopCond, NodeType.ForLoopIter, NodeType.ForLoopBody: "lightseagreen";
                case NodeType.Ternary, NodeType.TernaryCond, NodeType.TernaryTrue, NodeType.TernaryFalse: "lightsteelblue";
                case NodeType.LoopContinue, NodeType.LoopBreak: "lightseagreen";
                case NodeType.IfStatement, NodeType.IfStatementCond, NodeType.IfStatementBody, NodeType.IfStatementElse, NodeType.IfStatementElseIf: "lightsteelblue";
                case NodeType.SubExpression: "lightgoldenrodyellow";
                case NodeType.Return: "lightseagreen";
                case NodeType.BinaryOp, NodeType.UnaryOp, NodeType.OperationLeft, NodeType.OperationRight: "lightcyan";
                default: "white";
            };
        }

        function formatNode(node: Node): String {
            var id = assignNodeId(node);
            var label = '${node.type}';
            if (node.value != null && node.value != "") {
                label += ' ${node.value}';
            }
            var color = getColor(node.type);
            return '${id} [label="${label}" style=filled fillcolor="${color}"]';
        }

        function isSubgraphNode(nodeType: NodeType): Bool {
            return switch (nodeType) {
                case NodeType.FunctionDeclBody, NodeType.FunctionDeclNativeBody, NodeType.VarValue, NodeType.SubExpression, NodeType.WhileLoopBody, NodeType.WhileLoopCond, ast.NodeType.FunctionCallParam: true;
                default: false;
            };
        }

        function traverse(node: Node) {
            var nodeId = assignNodeId(node);
            if (isSubgraphNode(node.type)) {
                output.push('subgraph cluster_${nodeId} {');
                output.push('label=\"${node.type}\"; color=gray;');
            }

            output.push(formatNode(node));

            for (child in node.children) {
                var childId = assignNodeId(child);
                output.push('${nodeId} -> ${childId}');
                traverse(child);
            }

            if (isSubgraphNode(node.type)) {
                output.push("}");
            }
        }

        output.push("digraph AST {");
        traverse(node);
        output.push("}");

        Logging.print(output.join("\n"));
    }

}