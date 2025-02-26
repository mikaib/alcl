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

            headers += '#include "${FsUtil.resolvePath(_baseLocDir, lib)}.h"\n';
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

            headers += '#include "${FsUtil.resolvePath(_baseLocDir, lib)}.h"\n';
        }

        var code = printChildren(_root);
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
                out += printVarAssign(node, indent);
            case NodeType.VarDef:
                out += printVarDef(node, indent);
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
            case NodeType.WhileLoopBreak:
                out += 'break;\n';
            case NodeType.WhileLoopContinue:
                out += 'continue;\n';
            case NodeType.BinaryOp:
                out += printBinaryOperation(node);
            case NodeType.UnaryOp:
                out += printUnaryOperation(node);
            case NodeType.Return:
                out += printReturn(node);
            case NodeType.BooleanLiteral:
                out += node.value == "true" ? "1" : "0";
            case NodeType.FunctionDeclNativeBody:
                out += node.value;
            case NodeType.StringLiteral:
                out += '"${node.value}"';
            case NodeType.OperationLeft:
                out += printChildren(node, true);
            case NodeType.OperationRight:
                out += printChildren(node, true);
            case NodeType.SubExpression:
                out += '(${printChildren(node, true)})';
            case NodeType.NumberLiteral:
                out += node.value;
            case NodeType.Identifier:
                out += node.value;
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

    public function printReturn(node: Node): String {
        return 'return ${printChildren(node, true)};\n';
    }

    public function printFunctionDecl(node: Node, indent: Int): String {
        var returnType = findChildOfType(node, NodeType.FunctionDeclReturnType)?.value ?? "Void";

        var paramStr = "";
        var params = findAllChildrenOfType(node, NodeType.FunctionDeclParam);
        for (param in params) {
            var paramType = findChildOfType(param, NodeType.FunctionDeclParamType)?.value ?? "void";
            paramStr += '${_types.convertTypeAlclToC(paramType)} ${param.value}, ';
        }
        paramStr = paramStr.substr(0, paramStr.length - 2);

        _funcDefs.push('${_types.convertTypeAlclToC(returnType)} ${node.value}(${paramStr});\n');

        var prefix = "";
        var body = findChildOfType(node, NodeType.FunctionDeclBody);
        if (body != null) {
            return '${prefix}${_types.convertTypeAlclToC(returnType)} ${node.value}(${paramStr}) {\n${replaceLast(printNode(body, indent + 1), "\n", "")}\n}\n\n';
        }

        var nativeBody = findChildOfType(node, NodeType.FunctionDeclNativeBody);
        if (nativeBody != null) {
            return '${prefix}${_types.convertTypeAlclToC(returnType)} ${node.value}(${paramStr}) {${nativeBody.value}}\n\n';
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

    public function printVarDef(node: Node, indent: Int): String {
        var type = findChildOfType(node, NodeType.VarType);
        if (type == null) {
            type = {
                type: NodeType.VarType,
                value: "void"
            }
        }

        var value = findChildOfType(node, NodeType.VarValue);
        if (value == null) {
            value = {
                type: NodeType.Identifier,
                value: "NULL"
            }
        }

        return '${_types.convertTypeAlclToC(type.value)} ${node.value} = ${printChildren(value, true)};\n';
    }

    public function printVarAssign(node: Node, indent: Int): String {
        var value = findChildOfType(node, NodeType.VarValue);
        if (value == null) {
            value = {
                type: NodeType.Identifier,
                value: "NULL"
            }
        }

        return '${node.value} = ${printChildren(value, true)};\n';
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
