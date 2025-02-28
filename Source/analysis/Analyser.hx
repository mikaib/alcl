package analysis;

import errors.ErrorContainer;
import ast.Parser;
import ast.Node;
import ast.NodeType;

class Analyser {

    private var _errors: ErrorContainer;
    private var _parser: Parser;

    public function new(parser: Parser) {
        _parser = parser;
        _errors = new ErrorContainer();
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

    public function getUserSetType(node: Node): Null<String> {
        switch(node.type) {
            case NodeType.VarDef:
                var typeNode: Node = findChildOfType(node, NodeType.VarType);
                return typeNode;
            case NodeType.FunctionDecl:
                var typeNode: Node = findChildOfType(node, NodeType.FunctionDeclReturnType);
                return typeNode;
            case NodeType.FunctionDeclParam:
                var typeNode: Node = findChildOfType(node, NodeType.FunctionDeclParamType);
                return typeNode;
            default:
                return null;
        }
    }

    public function setTypeOfNode(node: Node, type: String): Void {
        node.analysisType = type;
    }

    public function runAtNode(node: Node): Void {

    }

    public function run(): Void {
        runAtNode(_parser.getRoot());
    }

}
