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
    private var _classDefs: Array<String> = [];

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

        for (classDef in _classDefs) {
            code += classDef;
        }

        if (_classDefs.length > 0) code += "\n";

        for (funcDef in _funcDefs) {
            code += funcDef;
        }

        if (_funcDefs.length > 0) code += "\n";

        code += childrenStr;
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
            case NodeType.ClassDecl:
                out += printClassDecl(node, indent);
            case NodeType.CCode:
                out += node.value + (inlineNode ? "" : "\n");
            case NodeType.Cast:
                out += '(${_types.convertTypeAlclToC(node.value)})(${printChildren(node, true)})';
            case NodeType.FromPtr:
                out += '*(${printChildren(node, true)})';
            case NodeType.ToPtr:
                out += '&(${printChildren(node, true)})';
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

    public function printClassDecl(node: Node, indent: Int): String {
        var tdef: String = 'typedef struct __alcl_class_${node.value} __alcl_class_${node.value};\n';
        tdef += 'typedef struct __alcl_vtable_${node.value} __alcl_vtable_${node.value};\n';
        tdef += 'typedef struct __alcl_classptr_${node.value} __alcl_classptr_${node.value};\n';

        var ptr: String = 'typedef struct __alcl_classptr_${node.value} {\n';
        ptr += '    __alcl_class_${node.value} *this;\n';
        ptr += '    const __alcl_vtable_${node.value} *vtable;\n';
        ptr += '} __alcl_classptr_${node.value};\n';

        var vtable: String = 'struct __alcl_vtable_${node.value} {\n';
        var body = findChildOfType(node, NodeType.ClassBody);
        var funcs = findAllChildrenOfType(body, NodeType.FunctionDecl);
        var vars = findAllChildrenOfType(body, NodeType.VarDef);

        for (func in funcs) {
            vtable += '    ${_types.convertTypeAlclToC(func.analysisType.toString())} (*${func.value})(';
            var params = findAllChildrenOfType(func, NodeType.FunctionDeclParam);
            for (param in params) {
                vtable += '${_types.convertTypeAlclToC(param.analysisType.toString())} ${param.value}, ';
            }
            vtable = vtable.substr(0, vtable.length - 2);
            vtable += ');\n';
        }
        vtable += '};\n';

        var classDef: String = 'struct __alcl_class_${node.value} {\n';
        for (v in vars) {
            classDef += '    ${_types.convertTypeAlclToC(v.analysisType.toString())} ${v.value};\n';
        }
        classDef += '};\n';

        var classCode = "";
        for (func in funcs) {
            classCode += printFunctionDecl(func, indent);
        }

        var hasConstructor = false;
        for (func in funcs) {
            if (func.value == '__alcl_method_${node.value}_${node.value}') {
                hasConstructor = true;
                break;
            }
        }

        var constructorParams = "";
        var callParams = "";
        if (hasConstructor) {
            var constructor = findChildOfType(body, NodeType.FunctionDecl);
            var params = findAllChildrenOfType(constructor, NodeType.FunctionDeclParam);
            for (param in params) {
                if (param.value == 'this') {
                    continue;
                }

                constructorParams += '${_types.convertTypeAlclToC(param.analysisType.toString())} ${param.value}, ';
                callParams += '${param.value}, ';
            }
            constructorParams = constructorParams.substr(0, constructorParams.length - 2);
        }

        if (hasConstructor) {
            classCode += '__alcl_classptr_${node.value} *${node.value}_new(${constructorParams}) {\n';
        } else {
            classCode += '__alcl_classptr_${node.value} *${node.value}_new() {\n';
        }

        classCode += '    __alcl_class_${node.value} *obj = alcl_gc_alloc(sizeof(__alcl_class_${node.value}));\n';
        classCode += '    __alcl_classptr_${node.value} *ptr = alcl_gc_alloc(sizeof(__alcl_classptr_${node.value}));\n';
        classCode += '    ptr->this = obj;\n';

        if (vars.length > 0) {
            for (v in vars) {
                var varValue = findChildOfType(v, NodeType.VarValue);
                classCode += '    ptr->this->${v.value} = ${varValue != null ? printChildren(varValue, true) : "0"};\n';
            }
        }

        classCode += '    ptr->vtable = &__alcl_vtable_${node.value}_impl;\n';

        if (hasConstructor) {
            var paramStr = 'ptr->this, ${callParams}';
            classCode += '    __alcl_method_${node.value}_${node.value}(${paramStr.substr(0, paramStr.length - 2)});\n';
        }

        classCode += '    return ptr;\n';
        classCode += '}\n';

        _funcDefs.push('__alcl_classptr_${node.value} *${node.value}_new();\n');

        var vTableImpl = 'static const __alcl_vtable_${node.value} __alcl_vtable_${node.value}_impl = {\n';
        var hasFuncs = false;
        for (func in funcs) {
            hasFuncs = true;
            vTableImpl += '    .${func.value} = ${func.value},\n';
        }

        if (hasFuncs) {
            vTableImpl = vTableImpl.substr(0, vTableImpl.length - 2);
        }

        vTableImpl += '\n};\n';
        _classDefs.push(tdef);

        return ptr + '\n' + classDef + '\n' + vtable + '\n' + vTableImpl + '\n' + classCode + '\n';
    }
}
