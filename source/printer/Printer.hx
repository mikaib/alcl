package printer;
import ast.Node;
import ast.NodeType;
import ast.Parser;
import haxe.crypto.Md5;
import typer.Typer;
import data.ProjectData;
import util.Logging;
import util.FsUtil;

class Printer {

    private var _root: Node;
    private var _parser: Parser;
    private var _types: Typer;
    private var _project: ProjectData;
    private var _baseLocDir: String;
    private var _funcDefs: Array<String> = [];

    public function new(parser: Parser, project: ProjectData, baseLocDir: String = "") {
        _root = parser.getRoot();
        _types = parser.getTypes();
        _project = project;
        _parser = parser;
        _baseLocDir = baseLocDir;
        _funcDefs = [];
    }

    public function printHeaderFile(baseLoc: String): String {
        var hash = Md5.encode(baseLoc);
        var headers = '#ifndef ALCL_${hash}\n#define ALCL_${hash}\n\n';

        for (lib in _parser.getLibRequirements()) {
            var resolved = _project.resolveImport(lib);
            if (resolved == null) {
                Logging.debug('Unresolved import: ${lib}');
                continue;
            }

            var path = FsUtil.resolvePath(_baseLocDir, lib);
            var parts = path.split('/');
            parts[parts.length - 1] = 'alcl_' + parts[parts.length - 1];

            headers += '#include "${parts.join('/')}.h"\n';
        }

        var code = "";
        for (funcDef in _funcDefs) {
            code += funcDef;
        }

        var res = headers + "\n" + code + '\n#endif // ALCL_${hash}\n';

        return res;
    }

    public function print(): String {
        _funcDefs.resize(0);

        var headers = '';
        for (header in _parser.getHeaders()) {
            headers += '#include "${header}"\n';
        }

        for (lib in _parser.getLibRequirements()) {
            var resolved = _project.resolveImport(lib);
            if (resolved == null) {
                Logging.debug('Unresolved import: ${lib}');
                continue;
            }

            var path = FsUtil.resolvePath(_baseLocDir, lib);
            var parts = path.split('/');
            parts[parts.length - 1] = 'alcl_' + parts[parts.length - 1];

            headers += '#include "${parts.join('/')}.h"\n';
        }

        var code = "";
        var childrenStr = printChildren(_root);

        for (funcDef in _funcDefs) {
            code += funcDef;
        }

        code += "\n" + childrenStr;
        var res = headers + "\n" + code;

        return res;
    }

    public function printNode(node: Node, indent: Int, inlineNode: Bool = false): String {
        var out = "";

        switch (node.type) {
            case NodeType.FunctionDecl:
                out += printFunctionDecl(node, indent);
            case NodeType.FunctionCall:
                out += printFunctionCall(node, indent, inlineNode);
            case NodeType.FunctionDeclBody:
                out += printChildren(node);
            case NodeType.VarAssign:
                out += printVarAssign(node, indent, inlineNode);
            case NodeType.VarDef:
                out += printVarDef(node, indent, inlineNode);
            case NodeType.WhileLoop:
                out += printWhileLoop(node, indent);
            case NodeType.WhileLoopBody:
                out += printChildren(node);
            case NodeType.IfStatement:
                out += printIfStatement(node, indent);
            case NodeType.IfStatementElseIf:
                out += printElseIfStatement(node, indent);
            case NodeType.IfStatementElse:
                out += printElseStatement(node, indent);
            case NodeType.IfStatementBody:
                out += printChildren(node);
            case NodeType.LoopBreak:
                out += 'break${inlineNode ? "" : ";\n"}';
            case NodeType.LoopContinue:
                out += 'continue${inlineNode ? "" : ";\n"}';
            case NodeType.BinaryOp:
                out += printBinaryOperation(node);
            case NodeType.UnaryOp:
                out += printUnaryOperation(node);
            case NodeType.Return:
                out += printReturn(node, indent, inlineNode);
            case NodeType.BooleanLiteral:
                out += node.value == "true" ? "1" : "0";
            case NodeType.FunctionDeclNativeBody:
                out += node.value;
            case NodeType.StringLiteral:
                out += '"${node.value}"';
            case NodeType.NullLiteral:
                out += "0";
            case NodeType.OperationLeft:
                out += printChildren(node, true);
            case NodeType.OperationRight:
                out += printChildren(node, true);
            case NodeType.SubExpression:
                out += '(${printChildren(node, true)})';
            case NodeType.Ternary:
                out += printTernary(node, inlineNode);
            case NodeType.ForLoop:
                out += printForLoop(node, indent);
            case NodeType.IntLiteral:
                out += node.value;
            case NodeType.FloatLiteral:
                out += node.value;
            case NodeType.Identifier:
                out += node.value;
            case NodeType.ForLoopBody:
                out += printChildren(node);
            case NodeType.CCode:
                out += node.value + (inlineNode ? "" : "\n");
            case NodeType.Cast:
                out += '(${_types.convertTypeAlclToC(node.value)})(${printChildren(node, true)})';
            default:
        }

        return indentString(out, indent);
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

    public function indentString(str: String, indent: Int): String {
        var lines = str.split("\n");
        var indentStr = "";
        for (i in 0...indent) {
            indentStr += "    ";
        }
        for (i in 0...lines.length) {
            lines[i] = indentStr + lines[i];
        }
        return lines.join("\n");
    }

    public function printChildren(node: Node, inlineNode: Bool = false): String {
        var out = "";
        for (child in node.children) {
            out += printNode(child, 0, inlineNode);
        }
        return out;
    }

    public function printBinaryOperation(node: Node): String {
        var left = findChildOfType(node, NodeType.OperationLeft);
        var right = findChildOfType(node, NodeType.OperationRight);
        var op: String = node.value;

        return '${printNode(left, 0)} ${op} ${printNode(right, 0)}';
    }

    public function printUnaryOperation(node: Node): String {
        var op: String = node.value;
        return '${op}${printChildren(node, true)}';
    }

    public function printReturn(node: Node, indent: Int, inlineNode: Bool): String {
        // return 'return ${printChildren(node, true)};\n';
        return 'return ${printChildren(node, true)}${inlineNode ? "" : ";\n"}';
    }

    public function printTernary(node: Node, isInline: Bool): String {
        var condition = findChildOfType(node, NodeType.TernaryCond);
        var trueBranch = findChildOfType(node, NodeType.TernaryTrue);
        var falseBranch = findChildOfType(node, NodeType.TernaryFalse);

        return '${printChildren(condition, true)} ? ${printChildren(trueBranch, true)} : ${printChildren(falseBranch, true)}${isInline ? "" : ";\n"}';
    }

    public function printFunctionDecl(node: Node, indent: Int): String {
        var paramStr = "";
        var params = findAllChildrenOfType(node, NodeType.FunctionDeclParam);
        for (param in params) {
            paramStr += '${_types.convertTypeAlclToC(param.analysisType.toString())} ${param.value}, ';
        }
        paramStr = paramStr.substr(0, paramStr.length - 2);

        _funcDefs.push('${_types.convertTypeAlclToC(node.analysisType.toString())} ${node.value}(${paramStr});\n');

        var prefix = "";
        var body = findChildOfType(node, NodeType.FunctionDeclBody);
        if (body != null) {
            return '${prefix}${_types.convertTypeAlclToC(node.analysisType.toString())} ${node.value}(${paramStr}) {\n${replaceLast(printNode(body, indent + 1), "\n", "")}\n}\n\n';
        }

        var nativeBody = findChildOfType(node, NodeType.FunctionDeclNativeBody);
        if (nativeBody != null) {
            return '${prefix}${_types.convertTypeAlclToC(node.analysisType.toString())} ${node.value}(${paramStr}) {${nativeBody.value}}\n\n';
        }

        var externBody = findChildOfType(node, NodeType.FunctionDeclExternBody);
        if (externBody != null) {
            _funcDefs.pop();
            return '';
        }

        return "";
    }

    public function replaceLast(str: String, find: String, replace: String): String {
        var idx = str.lastIndexOf(find);
        if (idx == -1) {
            return str;
        }
        return str.substr(0, idx) + replace + str.substr(idx + find.length);
    }

    public function printFunctionCall(node: Node, indent: Int, inlineCall: Bool = false): String {
        var argStr = "";
        var args = findAllChildrenOfType(node, NodeType.FunctionCallParam);

        for (arg in args) {
            argStr += '${printChildren(arg, true)}, ';
        }

        return '${node.value}(${argStr.substr(0, argStr.length - 2)})${inlineCall ? "" : ";\n"}';
    }

    public function printForLoop(node: Node, indent: Int): String {
        var body: Node = findChildOfType(node, NodeType.ForLoopBody);
        if (body == null) {
            body = {
                type: NodeType.ForLoopBody,
                value: null
            };
        }

        var init = findChildOfType(node, NodeType.ForLoopInit);
        if (init == null) {
            init = {
                type: NodeType.ForLoopInit,
                value: null
            };
        }

        var cond = findChildOfType(node, NodeType.ForLoopCond);
        if (cond == null) {
            cond = {
                type: NodeType.ForLoopCond,
                value: null
            };
        }

        var iter = findChildOfType(node, NodeType.ForLoopIter);
        if (iter == null) {
            iter = {
                type: NodeType.ForLoopIter,
                value: null
            };
        }

        return 'for (${printChildren(init, true)}; ${printChildren(cond, true)}; ${printChildren(iter, true)}) {\n${replaceLast(printNode(body, indent + 1), "\n", "")}\n}\n';
    }

    public function printVarDef(node: Node, indent: Int, inlineNode: Bool): String {
        var value = findChildOfType(node, NodeType.VarValue);
        if (value == null) {
            if (inlineNode) {
                return '(${_types.convertTypeAlclToC(node.analysisType.toString())} ${node.value})';
            } else {
                return '${_types.convertTypeAlclToC(node.analysisType.toString())} ${node.value};\n';
            }
        }

        if (inlineNode) {
            return '(${_types.convertTypeAlclToC(node.analysisType.toString())} ${node.value} = ${printChildren(value, true)})';
        } else {
            return '${_types.convertTypeAlclToC(node.analysisType.toString())} ${node.value} = ${printChildren(value, true)};\n';
        }
    }

    public function printVarAssign(node: Node, indent: Int, inlineNode: Bool): String {
        var value = findChildOfType(node, NodeType.VarValue);
        if (value == null) {
            value = {
                type: NodeType.NullLiteral,
                value: "NULL"
            }
        }

        if (inlineNode) {
            return '(${node.value} = ${printChildren(value, true)})';
        } else {
            return '${node.value} = ${printChildren(value, true)};\n';
        }
    }

    public function printIfStatement(node: Node, indent: Int): String {
        var body: Node = findChildOfType(node, NodeType.IfStatementBody);
        if (body == null) {
            body = {
                type: NodeType.IfStatementBody,
                value: null
            };
        }

        var condition = findChildOfType(node, NodeType.IfStatementCond);
        if (condition == null) {
            condition = {
                type: NodeType.IfStatementCond,
                value: null
            };
        }

        return 'if (${printChildren(condition)}) {\n${replaceLast(printNode(body, indent + 1), "\n", "")}\n}\n';
    }

    public function printElseIfStatement(node: Node, indent: Int): String {
        var body: Node = findChildOfType(node, NodeType.IfStatementBody);
        if (body == null) {
            body = {
                type: NodeType.IfStatementBody,
                value: null
            };
        }

        var condition = findChildOfType(node, NodeType.IfStatementCond);
        if (condition == null) {
            condition = {
                type: NodeType.IfStatementCond,
                value: null
            };
        }

        return 'else if (${printChildren(condition)}) {\n${replaceLast(printNode(body, indent + 1), "\n", "")}\n}\n';
    }

    public function printElseStatement(node: Node, indent: Int): String {
        var body: Node = findChildOfType(node, NodeType.IfStatementBody);
        if (body == null) {
            body = {
                type: NodeType.IfStatementBody,
                value: null
            };
        }

        return 'else {\n${replaceLast(printNode(body, indent + 1), "\n", "")}\n}\n';
    }

    public function printWhileLoop(node: Node, indent: Int): String {
        var body: Node = findChildOfType(node, NodeType.WhileLoopBody);
        if (body == null) {
            body = {
                type: NodeType.WhileLoopBody,
                value: null
            };
        }

        var condition = findChildOfType(node, NodeType.WhileLoopCond);
        if (condition == null) {
            condition = {
                type: NodeType.WhileLoopCond,
                value: null
            };
        }

        return 'while (${printChildren(condition)}) {\n${replaceLast(printNode(body, indent + 1), "\n", "")}\n}\n';
    }

}
