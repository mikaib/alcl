package ast;

import compiler.Tokenizer;
import compiler.TokenType;
import compiler.Token;
import util.Logging;
import errors.ErrorContainer;
import typer.Typer;

class ParserOld {

    private var _tokenizer: Tokenizer;
    private var _root: Node;
    private var _errors: ErrorContainer;
    private var _headers: Array<String>;
    private var _libRequirements: Array<String>;
    private var _types: Typer;

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
    }

    public function ensureHeader(header: String) {
        if (_headers.indexOf(header) == -1) {
            _headers.push(header);
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
        this.parseSlice(_tokenizer.iterator(), _root);
    }

    public function parseSlice(slice: Iterator<Token>, node: Node): Void {
        var iter = slice;
        var currentNode = node;
        var metaStack: Array<Token> = [];
        var lastWasMeta = true;

        while (iter.hasNext()) {
            var token = iter.next();

            if (!lastWasMeta && metaStack.length > 0) {
                metaStack.resize(0); // discard meta's
            }

            if (token.type == TokenType.Meta) {
                metaStack.push(token);
                lastWasMeta = true;
                continue;
            } else {
                lastWasMeta = false;
            }

            if (token.type == TokenType.Identifier && token.value == "while") {
                if (!iter.hasNext()) {
                    continue;
                }

                var next = iter.next();
                if (next.type != TokenType.LeftParen) continue;
                if (!iter.hasNext()) continue;

                var currentTokens: Array<Token> = [];
                while (iter.hasNext()) {
                    var conditionToken = iter.next();
                    if (conditionToken.type == TokenType.RightParen) {
                        break;
                    }
                    currentTokens.push(conditionToken);
                }

                var whileLoop: Node = {
                    type: NodeType.WhileLoop,
                    value: null,
                    line: token.line,
                    column: token.column,
                    endLine: token.line,
                    endColumn: token.column,
                    parent: currentNode,
                    children: []
                };

                var whileLoopCond: Node = {
                    type: NodeType.WhileLoopCond,
                    value: null,
                    line: currentTokens[0].line,
                    column: currentTokens[0].column,
                    endLine: currentTokens[currentTokens.length - 1].line,
                    endColumn: currentTokens[currentTokens.length - 1].column,
                    parent: whileLoop,
                    children: []
                };

                var whileLoopBody: Node = {
                    type: NodeType.WhileLoopBody,
                    value: null,
                    line: currentTokens[0].line,
                    column: currentTokens[0].column,
                    endLine: currentTokens[currentTokens.length - 1].line,
                    endColumn: currentTokens[currentTokens.length - 1].column,
                    parent: whileLoop,
                    children: []
                }

                this.parseSlice(currentTokens.iterator(), whileLoopCond);

                if (!iter.hasNext()) continue;
                var next = iter.next();
                if (next.type != TokenType.LeftBrace) continue;

                var depth = 1;
                var startIdx = next.index;
                var endIdx = -1;
                var bodyTokens: Array<Token> = [];

                while (iter.hasNext()) {
                    var bodyToken = iter.next();
                    if (bodyToken.type == TokenType.LeftBrace) {
                        depth++;
                    } else if (bodyToken.type == TokenType.RightBrace) {
                        depth--;
                        if (depth == 0) {
                            whileLoopBody.endLine = bodyToken.line;
                            whileLoopBody.endColumn = bodyToken.column;
                            endIdx = bodyToken.index;
                            break;
                        }
                    }

                    bodyTokens.push(bodyToken);
                }

                this.parseSlice(bodyTokens.iterator(), whileLoopBody);
                whileLoop.children.push(whileLoopCond);
                whileLoop.children.push(whileLoopBody);
                currentNode.children.push(whileLoop);
            } else if (token.type == TokenType.Identifier && token.value == "var") {
                if (!iter.hasNext()) {
                    continue;
                }

                var varName = iter.next();
                var varDef: Node = {
                    type: NodeType.VarDef,
                    value: varName.value,
                    line: token.line,
                    column: token.column,
                    endLine: token.line,
                    endColumn: token.column,
                    parent: currentNode,
                    children: []
                };

                if (!iter.hasNext()) {
                    continue;
                }
                var next = iter.next();

                if (next.type == TokenType.Colon) {
                    if (!iter.hasNext()) {
                        continue;
                    }

                    var typeToken = iter.next();
                    var typeNode: Node = {
                        type: NodeType.VarType,
                        value: typeToken.value,
                        line: typeToken.line,
                        column: typeToken.column,
                        endLine: typeToken.line,
                        endColumn: typeToken.column + typeToken.value.length,
                        parent: varDef,
                        children: []
                    };
                    varDef.children.push(typeNode);

                    if (!iter.hasNext()) {
                        continue;
                    }
                    next = iter.next();
                }

                if (next.type == TokenType.Assign) {
                    if (!iter.hasNext()) {
                        continue;
                    }

                    var valueTokens: Array<Token> = [];
                    while (iter.hasNext()) {
                        var valueToken = iter.next();
                        if (valueToken.type == TokenType.Semicolon) {
                            break;
                        }
                        valueTokens.push(valueToken);
                    }

                    var valueNode: Node = {
                        type: NodeType.VarValue,
                        value: null,
                        line: valueTokens[0].line,
                        column: valueTokens[0].column,
                        endLine: valueTokens[valueTokens.length - 1].line,
                        endColumn: valueTokens[valueTokens.length - 1].column,
                        parent: varDef,
                        children: []
                    };

                    this.parseSlice(valueTokens.iterator(), valueNode);
                    varDef.children.push(valueNode);

                }
                currentNode.children.push(varDef);
            } else if (token.type == TokenType.Identifier && token.value == "need") {
                if (!iter.hasNext()) {
                    continue;
                }

                var libName = iter.next().value;
                if (_libRequirements.indexOf(libName) == -1) {
                    _libRequirements.push(libName);
                }
            } else if (token.type == TokenType.Identifier && token.value == "func") {
                var funcName = iter.next();
                var funcNode: Node = {
                    type: NodeType.FunctionDecl,
                    value: funcName.value,
                    line: token.line,
                    column: token.column,
                    endLine: token.line,
                    endColumn: token.column,
                    parent: currentNode,
                    children: []
                };

                var isNativeFunction: Bool = false;
                for (meta in metaStack) {
                    var v = StringTools.trim(meta.value);
                    var parts = v.split(" ");

                    if (parts[0] == "native_function") {
                        isNativeFunction = true;
                    }

                    if (parts[0] == "native_header") {
                        this.ensureHeader(parts[1]);
                    }
                }

                var paramList: Array<Node> = [];
                if (iter.hasNext() && iter.next().type == TokenType.LeftParen) {
                    var currentTokens: Array<Token> = [];

                    function flushParam() {
                        var paramName = "";
                        var paramType = null;

                        for (paramToken in currentTokens) {
                            if (paramToken.type == TokenType.Colon) {
                                paramType = "";
                                continue;
                            }

                            if (paramType == null) {
                                paramName += paramToken.value;
                            } else {
                                paramType += paramToken.value;
                            }
                        }

                        var paramNode: Node = {
                            type: NodeType.FunctionDeclParam,
                            value: paramName,
                            line: currentTokens[0].line,
                            column: currentTokens[0].column,
                            endLine: currentTokens[currentTokens.length - 1].line,
                            endColumn: currentTokens[currentTokens.length - 1].column,
                            parent: funcNode,
                            children: []
                        };

                        if (paramType != null) {
                            var typeNode: Node = {
                                type: NodeType.FunctionDeclParamType,
                                value: paramType,
                                line: currentTokens[0].line,
                                column: currentTokens[0].column,
                                endLine: currentTokens[currentTokens.length - 1].line,
                                endColumn: currentTokens[currentTokens.length - 1].column,
                                parent: paramNode,
                                children: []
                            };
                            paramNode.children.push(typeNode);
                        }

                        paramList.push(paramNode);
                        currentTokens = [];
                    }

                    while (iter.hasNext()) {
                        var paramToken = iter.next();
                        if (paramToken.type == TokenType.RightParen) break;
                        if (paramToken.type == TokenType.Comma) {
                            flushParam();
                            continue;
                        }
                        currentTokens.push(paramToken);
                    }

                    if (currentTokens.length > 0) {
                        flushParam();
                    }
                }
                funcNode.children = paramList;

                if (!iter.hasNext()) {
                    currentNode.children.push(funcNode);
                    continue;
                }

                var next = iter.next();
                if (next.type == TokenType.Colon) {
                    if (iter.hasNext()) {
                        var returnTypeToken = iter.next();
                        var returnTypeNode: Node = {
                            type: NodeType.FunctionDeclReturnType,
                            value: returnTypeToken.value,
                            line: returnTypeToken.line,
                            column: returnTypeToken.column,
                            endLine: returnTypeToken.line,
                            endColumn: returnTypeToken.column + returnTypeToken.value.length,
                            parent: funcNode,
                            children: []
                        };
                        funcNode.children.push(returnTypeNode);
                    }

                    if (!iter.hasNext()) {
                        currentNode.children.push(funcNode);
                        continue;
                    }

                    next = iter.next();
                }

                var depth = 1;
                var startIdx = next.index;
                var endIdx = -1;
                if (next.type == TokenType.LeftBrace) {
                    var bodyNode: Node = {
                        type: NodeType.FunctionDeclBody,
                        value: null,
                        line: next.line,
                        column: next.column,
                        endLine: next.line,
                        endColumn: next.column,
                        parent: funcNode,
                        children: []
                    };

                    var bodyTokens: Array<Token> = [];

                    while (iter.hasNext()) {
                        var bodyToken = iter.next();
                        if (bodyToken.type == TokenType.LeftBrace) {
                            depth++;
                        } else if (bodyToken.type == TokenType.RightBrace) {
                            depth--;
                            if (depth == 0) {
                                bodyNode.endLine = bodyToken.line;
                                bodyNode.endColumn = bodyToken.column;
                                endIdx = bodyToken.index;
                                break;
                            }
                        }

                        bodyTokens.push(bodyToken);
                    }

                    if (isNativeFunction) {
                        var contentNode: Node = {
                            type: NodeType.FunctionDeclNativeBody,
                            value: _tokenizer.getChars(startIdx+1, endIdx),
                            line: bodyTokens[0].line,
                            column: bodyTokens[0].column,
                            endLine: bodyTokens[bodyTokens.length - 1].line,
                            endColumn: bodyTokens[bodyTokens.length - 1].column,
                            parent: funcNode,
                            children: []
                        };
                        funcNode.endLine = contentNode.line;
                        funcNode.endColumn = contentNode.column;
                        funcNode.children.push(contentNode);
                    } else {
                        this.parseSlice(bodyTokens.iterator(), bodyNode);
                        funcNode.children.push(bodyNode);
                    }
                }

                currentNode.children.push(funcNode);
                currentNode = funcNode.parent;
            } else if (token.type == TokenType.Number) {
                var numberNode: Node = {
                    type: NodeType.NumberLiteral,
                    value: token.value,
                    line: token.line,
                    column: token.column,
                    endLine: token.line,
                    endColumn: token.column + token.value.length,
                    parent: currentNode,
                    children: []
                };

                currentNode.children.push(numberNode);
            } else if (token.type == TokenType.Identifier) {
                var next: Token = null;
                if (iter.hasNext()) {
                    next = iter.next();
                }

                if (next != null && next.type == TokenType.Assign) {
                    var varAssign: Node = {
                        type: NodeType.VarAssign,
                        value: token.value,
                        line: token.line,
                        column: token.column,
                        endLine: token.line,
                        endColumn: token.column,
                        parent: currentNode,
                        children: []
                    };

                    if (iter.hasNext()) {
                        var valueTokens: Array<Token> = [];
                        while (iter.hasNext()) {
                            var valueToken = iter.next();
                            if (valueToken.type == TokenType.Semicolon) {
                                break;
                            }
                            valueTokens.push(valueToken);
                        }

                        var valueNode: Node = {
                            type: NodeType.VarValue,
                            value: null,
                            line: valueTokens[0].line,
                            column: valueTokens[0].column,
                            endLine: valueTokens[valueTokens.length - 1].line,
                            endColumn: valueTokens[valueTokens.length - 1].column,
                            parent: varAssign,
                            children: []
                        };

                        this.parseSlice(valueTokens.iterator(), valueNode);
                        varAssign.children.push(valueNode);
                    }

                    currentNode.children.push(varAssign);
                } else if (next != null && next.type == TokenType.LeftParen) {
                    var callNode:Node = {
                        type: NodeType.FunctionCall,
                        value: token.value,
                        line: token.line,
                        column: token.column,
                        endLine: token.line,
                        endColumn: token.column,
                        parent: currentNode,
                        children: []
                    };

                    var args:Array<Node> = [];
                    var currentTokens:Array<Token> = [];

                    function flush() {
                        var paramNode:Node = {
                            type: NodeType.FunctionCallParam,
                            value: null,
                            line: currentTokens[0].line,
                            column: currentTokens[0].column,
                            endLine: currentTokens[currentTokens.length - 1].line,
                            endColumn: currentTokens[currentTokens.length - 1].column,
                            parent: callNode,
                            children: []
                        };

                        this.parseSlice(currentTokens.iterator(), paramNode);
                        callNode.children.push(paramNode);
                        currentTokens = [];
                    }

                    while (iter.hasNext()) {
                        var paramToken = iter.next();
                        if (paramToken.type == TokenType.RightParen) break;
                        if (paramToken.type == TokenType.Comma) {
                            flush();
                            continue;
                        }

                        currentTokens.push(paramToken);
                    }

                    if (currentTokens.length > 0) {
                        flush();
                    }

                    currentNode.children.push(callNode);
                } else {
                    var idNode: Node = {
                        type: NodeType.Identifier,
                        value: token.value,
                        line: token.line,
                        column: token.column,
                        endLine: token.line,
                        endColumn: token.column + token.value.length,
                        parent: currentNode,
                        children: []
                    };

                    currentNode.children.push(idNode);
                }
            } else if (token.type == TokenType.StringLiteral) {
                var stringNode: Node = {
                    type: NodeType.StringLiteral,
                    value: token.value,
                    line: token.line,
                    column: token.column,
                    endLine: token.line,
                    endColumn: token.column + token.value.length,
                    parent: currentNode,
                    children: []
                };

                currentNode.children.push(stringNode);
            }
        }
    }

    /**
     * Print the AST
     */
    public function print(?node: Node, depth: Int = 0): Void {
        if (node == null) {
            node = _root;
        }

        var indent = "";
        for (i in 0...depth) {
            indent += "    ";
        }

        Logging.print('$indent ${node.type} ${node.value} (${node.line}:${node.column} to ${node.endLine}:${node.endColumn})');
        for (child in node.children) {
            print(child, depth + 1);
        }
    }
}