package ast;

import tokenizer.Token;
import tokenizer.Tokenizer;
import tokenizer.TokenType;
import util.Logging;

class ParserContext {

    private var _tokens: Array<Token>;
    private var _idx: Int;
    private var _parser: Parser;
    private var _root: Node;
    private var _meta: Map<String, Array<Token>>;
    private var _metaEmpty: Bool;
    private var _lastLine: Int;
    private var _lastNode: Node;

    public function new(tokens: Array<Token>, parser: Parser, root: Node, idx: Int = -1) {
        _idx = idx;
        _tokens = tokens;
        _parser = parser;
        _root = root;
        _meta = [];
        _metaEmpty = true;
        _lastLine = -1;
    }

    public function next(skip: Int = 0): Token {
        _idx += skip + 1;
        return _tokens[_idx];
    }

    public function hasNext(skip: Int = 0): Bool {
        return _tokens[_idx + 1 + skip] != null;
    }

    public function hasNextOfType(type: TokenType, skip: Int = 0): Bool {
        return hasNext(skip) && peekNext(skip).type == type;
    }

    public function peekNext(skip: Int = 0): Token {
        return _tokens[_idx + 1 + skip];
    }

    public function prev(skip: Int = 0): Token {
        _idx -= 1 - skip;
        return _tokens[_idx];
    }

    public function hasPrev(skip: Int = 0): Bool {
        return _tokens[_idx - 1 - skip] != null;
    }

    public function peekPrev(skip: Int = 0): Token {
        return _tokens[_idx - 1 - skip];
    }

    public function hasPrevOfType(type: TokenType, skip: Int = 0): Bool {
        return hasPrev(skip) && peekPrev(skip).type == type;
    }

    public function getBoundaryTokensOfDelim(start: TokenType, end: TokenType): { start: Token, end: Token } {
        var depth = 1;
        var startToken = next();

        while(hasNext()) {
            var next = next();
            if (next.type == start) {
                depth++;
            }

            if (next.type == end) {
                depth--;
            }

            if (depth == 0) {
                return { start: startToken, end: next };
            }
        }

        return { start: startToken, end: startToken };
    }

    public function getTokenArrayDelim(start: TokenType, end: TokenType, startingDepth: Int = 0): Array<Token> {
        var depth = startingDepth;
        var tokens: Array<Token> = [];

        while (hasNext()) {
            var next = next();
            tokens.push(next);

            if (next.type == start) {
                depth++;
            }

            if (next.type == end) {
                depth--;
            }

            if (depth == 0) {
                break;
            }
        }

        return tokens.slice(1, -1);
    }

    public function tokenArrayGroupByEnsureLevel(tokenArr: Array<Token>, delim: TokenType, up: TokenType, down: TokenType): Array<Array<Token>> {
        var groups: Array<Array<Token>> = [];
        var groupIdx: Int = 0;
        var depth = 0;

        for (token in tokenArr) {
            if (token.type == up) {
                depth++;
            }

            if (token.type == down) {
                depth--;
            }

            if (token.type == delim && depth == 0) {
                groupIdx++;
                continue;
            }

            if (groups[groupIdx] == null) {
                groups[groupIdx] = [];
            }

            groups[groupIdx].push(token);
        }

        return groups;
    }

    public function tokenArrayGroupBy(tokenArr: Array<Token>, delim: TokenType): Array<Array<Token>> {
        var groups: Array<Array<Token>> = [];
        var groupIdx: Int = 0;

        for (token in tokenArr) {
            if (token.type == delim) {
                groupIdx++;
                continue;
            }

            if (groups[groupIdx] == null) {
                groups[groupIdx] = [];
            }

            groups[groupIdx].push(token);
        }

        return groups;
    }

    public function hasLastNode(): Bool {
        return _lastNode != null;
    }

    public function peekLastNode(): Node {
        return _lastNode;
    }

    public function popLastNode(): Node {
        var popped = _root.children.pop();
        var lastNode = _lastNode;
        _lastNode = null;

        if (popped != lastNode) {
            Logging.debug("Popped node from root is not the 'last' node, this shouldn't happen. Please report this along with the code.");
        }

        return lastNode;
    }

    public function createNode(type: NodeType, ?tokenStart: Token, ?tokenEnd: Token, ?parent: Node, ?value: String): Node {
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
            parent: parent ?? _root,
            children: []
        }
    }

    public function parseFunctionCall(token: Token) {
        // name
        var callNode: Node = createNode(NodeType.FunctionCall, token, null, null, token.value);

        // params
        var funcParamTokens: Array<Token> = getTokenArrayDelim(TokenType.LeftParen, TokenType.RightParen);
        var funcParamGroups: Array<Array<Token>> = tokenArrayGroupByEnsureLevel(funcParamTokens, TokenType.Comma, TokenType.LeftParen, TokenType.RightParen);
        for (paramGroup in funcParamGroups) {
            var paramNode = createNode(
                NodeType.FunctionCallParam,
                funcParamTokens[0],
                funcParamTokens[funcParamTokens.length - 1],
                callNode
            );
            var paramCtx: ParserContext = new ParserContext(paramGroup, _parser, paramNode);
            paramCtx.parse();

            callNode.children.push(paramNode);
            extractPosFromChildren(paramNode);
        }

        // end
        extractPosFromChildren(callNode);
        addNode(callNode);
    }

    public function parseFunction(token: Token): Void {
        // name
        if (!hasNextOfType(TokenType.Identifier)) return;
        var funcName: Token = next();

        // func
        var funcNode = createNode(NodeType.FunctionDecl, token, null, null, funcName.value);

        // params
        var funcParamTokens: Array<Token> = getTokenArrayDelim(TokenType.LeftParen, TokenType.RightParen);
        var funcParamGroups: Array<Array<Token>> = tokenArrayGroupBy(funcParamTokens, TokenType.Comma);
        for (paramGroup in funcParamGroups) {
            var groupCtx: ParserContext = new ParserContext(paramGroup, _parser, funcNode);

            // name
            if (!groupCtx.hasNextOfType(TokenType.Identifier)) continue;
            var name: Token = groupCtx.next();
            var paramNode = createNode(
                NodeType.FunctionDeclParam,
                paramGroup[0],
                paramGroup[paramGroup.length - 1],
                funcNode,
                name.value
            );
            groupCtx.addNode(paramNode);

            // type
            if (!groupCtx.hasNextOfType(TokenType.Colon)) continue;
            if (!groupCtx.hasNextOfType(TokenType.Identifier, 1)) continue;
            var type: Token = groupCtx.next(1);
            var typeNode = createNode(
                NodeType.FunctionDeclParamType,
                paramGroup[0],
                paramGroup[paramGroup.length - 1],
                paramNode,
                type.value
            );

            paramNode.children.push(typeNode);
        }

        // return type
        if (hasNextOfType(TokenType.Colon)) {
            var returnTypeToken: Token = next(1);
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

        // body
        if (_meta.exists("native_function")) {
            var funcBodyPos = getBoundaryTokensOfDelim(TokenType.LeftBrace, TokenType.RightBrace);
            var nativeFuncBodyNode = createNode(
                NodeType.FunctionDeclNativeBody,
                funcBodyPos.start,
                funcBodyPos.end,
                funcNode,
                _parser.getTokenizer().getChars(funcBodyPos.start.index+1, funcBodyPos.end.index)
            );

            funcNode.children.push(nativeFuncBodyNode);
        } else {
            var funcBodyTokens: Array<Token> = getTokenArrayDelim(TokenType.LeftBrace, TokenType.RightBrace);
            var funcBodyNode = createNode(
                NodeType.FunctionDeclBody,
                funcBodyTokens[0],
                funcBodyTokens[funcBodyTokens.length - 1],
                funcNode
            );

            funcNode.children.push(funcBodyNode);

            var funcBodyCtx: ParserContext = new ParserContext(funcBodyTokens, _parser, funcBodyNode);
            funcBodyCtx.parse();
        }

        // end
        extractPosFromChildren(funcNode);
        addNode(funcNode);
    }

    public function extractPosFromChildren(node: Node) {
        var minLine: Float = node.line;
        var minCol: Float = node.column;
        var maxLine: Float = node.endLine;
        var maxCol: Float = node.endColumn;

        for (child in node.children) {
            // line
            minLine = Math.min(minLine, child.line);
            maxLine = Math.max(maxLine, child.endLine);

            // col
            minCol = Math.min(minCol, child.column);
            maxCol = Math.max(maxCol, child.endColumn);
        }

        node.line = Std.int(minLine);
        node.endLine = Std.int(maxLine);
        node.column = Std.int(minCol);
        node.endColumn = Std.int(maxCol);
    }

    public function parseImport(token: Token, requiredImport: Bool): Void {
        if (!hasNext()) return;
        _parser.ensureRequirement(next().value); // TODO: implement required/optional import behaviour
    }

    public function parseVarDef(token: Token): Void {
        if (!hasNextOfType(TokenType.Identifier)) return;
        var varName: Token = next();

        var varNode = createNode(NodeType.VarDef, token, null, null, varName.value);

        if (hasNextOfType(TokenType.Colon)) {
            if (!hasNextOfType(TokenType.Identifier, 1)) return;
            var typeToken: Token = next(1);
            var typeNode: Node = {
                type: NodeType.VarType,
                value: typeToken.value,
                line: typeToken.line,
                column: typeToken.column,
                endLine: typeToken.line,
                endColumn: typeToken.column + typeToken.value.length,
                parent: varNode,
                children: []
            }

            varNode.children.push(typeNode);
        }

        if (hasNextOfType(TokenType.Assign)) {
            var assignToken: Token = peekNext();
            var assignNode = createNode(
                NodeType.VarValue,
                token,
                assignToken,
                varNode
            );

            varNode.children.push(assignNode);

            var assignCtx: ParserContext = new ParserContext(getTokenArrayDelim(TokenType.Assign, TokenType.Semicolon), _parser, assignNode);
            assignCtx.parse();
        }

        addNode(varNode);
    }

    public function parseVarAssign(token: Token): Void {
        var varName: Token = token;
        var varNode = createNode(NodeType.VarAssign, token, null, null, varName.value);

        if (hasNextOfType(TokenType.Colon)) {
            next(2); // We skip any type info
        }

        if (hasNextOfType(TokenType.Assign)) {
            var assignToken: Token = peekNext();
            var assignNode = createNode(
                NodeType.VarValue,
                token,
                assignToken,
                varNode
            );

            varNode.children.push(assignNode);

            var assignCtx: ParserContext = new ParserContext(getTokenArrayDelim(TokenType.Assign, TokenType.Semicolon), _parser, assignNode);
            assignCtx.parse();
        }

        addNode(varNode);
    }

    public function parseOperator(op: Token): Void {
        var precedence: Int = getPrecedence(op.type);
        var left: Node = popLastNode();

        // TODO: The "Not" and "BitwiseNot" must always be unary.
        if (left == null) {
            var unaryNode = createNode(NodeType.UnaryOp, null, null, null, op.value);

            var rightTokens: Array<Token> = [];
            var currentIndex = _idx + 1;
            var depth = 0;
            while (currentIndex < _tokens.length) {
                if (_tokens[currentIndex].type == TokenType.LeftParen) {
                    depth++;
                }

                if (isOperator(_tokens[currentIndex]) && getPrecedence(_tokens[currentIndex].type) < (precedence + 1) && depth == 0) {
                    break;
                }
                if (_tokens[currentIndex].type == TokenType.RightParen) {
                    depth--;
                }
                rightTokens.push(_tokens[currentIndex]);
                currentIndex++;
            }

            var rightCtx = new ParserContext(rightTokens, _parser, createNode(NodeType.None)).parse();
            var right: Node = null;
            while (right == null) {
                right = rightCtx.peekLastNode();
                if (!rightCtx.iter()) break;
            }

            if (right == null) {
                right = createNode(NodeType.NumberLiteral, null, null, null, "0");
            }
            @:privateAccess _idx = currentIndex - 1;

            unaryNode.children.push(right);
            addNode(unaryNode);
        } else {
            var binaryNode = createNode(NodeType.BinaryOp, null, null, null, op.value);

            var rightTokens: Array<Token> = [];
            var currentIndex = _idx + 1;
            var depth = 0;
            while (currentIndex < _tokens.length) {
                if (_tokens[currentIndex].type == TokenType.LeftParen) {
                    depth++;
                }
                if (isOperator(_tokens[currentIndex]) && getPrecedence(_tokens[currentIndex].type) < (precedence + 1) && depth == 0) {
                    break;
                }
                if (_tokens[currentIndex].type == TokenType.RightParen) {
                    depth--;
                }
                rightTokens.push(_tokens[currentIndex]);
                currentIndex++;
            }

            var rightCtx = new ParserContext(rightTokens, _parser, createNode(NodeType.None)).parse();
            var right: Node = null;
            while (right == null) {
                right = rightCtx.peekLastNode();
                if (!rightCtx.iter()) break;
            }

            if (right == null) {
                right = createNode(NodeType.None, null, null, null, "0");
            }

            @:privateAccess _idx = currentIndex - 1;

            var leftNode = createNode(NodeType.OperationLeft);
            leftNode.children.push(left);
            left.parent = leftNode;

            var rightNode = createNode(NodeType.OperationRight);
            rightNode.children.push(right);
            right.parent = rightNode;

            binaryNode.children.push(leftNode);
            binaryNode.children.push(rightNode);

            if (rightNode.children[0] != null && rightNode.children[0].type == NodeType.BinaryOp) {
                var rightNodeOp: Node = rightNode.children[0];
                var rightNodeOpType: TokenType = Tokenizer.fromString(rightNodeOp.value).tokens[0].type;
                var rightNodePrecedence: Int = getPrecedence(rightNodeOpType);
                var precedenceDiff: Int = precedence - rightNodePrecedence;
                if (precedenceDiff >= 0) {
                    var chLeft = rightNodeOp.children[0];
                    binaryNode.children[1] = chLeft;
                    binaryNode.children[1].type = NodeType.OperationRight;

                    rightNodeOp.children[0] = createNode(NodeType.OperationLeft);
                    rightNodeOp.children[0].children.push(binaryNode);

                    binaryNode = rightNodeOp;
                }
            }

            addNode(binaryNode);
        }
    }

    public function isOperator(t: Token): Bool {
        return getPrecedence(t.type) > 0;
    }

    public function parseConditionBodyKind(nodeType: NodeType, bodyType: NodeType, condType: NodeType, token: Token): Void {
        var node = createNode(nodeType, token, null, null);

        if (!hasNextOfType(TokenType.LeftParen)) return;
        var conditionTokens: Array<Token> = getTokenArrayDelim(TokenType.LeftParen, TokenType.RightParen);
        var conditionNode = createNode(
            condType,
            conditionTokens[0],
            conditionTokens[conditionTokens.length - 1],
            node
        );

        node.children.push(conditionNode);

        var conditionCtx: ParserContext = new ParserContext(conditionTokens, _parser, conditionNode);
        conditionCtx.parse();

        if (!hasNextOfType(TokenType.LeftBrace)) return;
        var bodyTokens: Array<Token> = getTokenArrayDelim(TokenType.LeftBrace, TokenType.RightBrace);
        var bodyNode = createNode(
            bodyType,
            bodyTokens[0],
            bodyTokens[bodyTokens.length - 1],
            node
        );

        node.children.push(bodyNode);

        var bodyCtx: ParserContext = new ParserContext(bodyTokens, _parser, bodyNode);
        bodyCtx.parse();

        addNode(node);
    }

    public function parseReturn(token: Token): Void {
        prev();
        var tokens: Array<Token> = getTokenArrayDelim(TokenType.Null, TokenType.Semicolon, 1);
        var returnNode: Node = createNode(NodeType.Return);

        var returnCtx: ParserContext = new ParserContext(tokens, _parser, returnNode);
        returnCtx.parse();

        addNode(returnNode);
    }

    public function parseElse(token: Token): Void {
        if (!hasNextOfType(TokenType.LeftBrace)) return;
        var elseNode: Node = createNode(NodeType.IfStatementElse, token, null, null);

        var bodyTokens: Array<Token> = getTokenArrayDelim(TokenType.LeftBrace, TokenType.RightBrace);
        var bodyNode = createNode(
            NodeType.IfStatementBody,
            bodyTokens[0],
            bodyTokens[bodyTokens.length - 1],
            elseNode
        );
        elseNode.children.push(bodyNode);

        var bodyCtx: ParserContext = new ParserContext(bodyTokens, _parser, bodyNode);
        bodyCtx.parse();

        addNode(elseNode);
    }

    public function parseIdentifier(token: Token): Void {
        switch (token.value) {
            case "func":
                parseFunction(token);
            case "need":
                parseImport(token, true);
            case "var":
                parseVarDef(token);
            case "return":
                parseReturn(token);
            case "if":
                parseConditionBodyKind(NodeType.IfStatement, NodeType.IfStatementBody, NodeType.IfStatementCond, token);
            case "else":
                if (hasNext() && peekNext().value == "if") {
                    next();
                    parseConditionBodyKind(NodeType.IfStatementElseIf, NodeType.IfStatementBody, NodeType.IfStatementCond, token);
                } else {
                    parseElse(token);
                }
            case "while":
                parseConditionBodyKind(NodeType.WhileLoop, NodeType.WhileLoopBody, NodeType.WhileLoopCond, token);
            case "continue":
                doExactConversion(token, NodeType.WhileLoopContinue);
            case "break":
                doExactConversion(token, NodeType.WhileLoopBreak);
            case "true" | "false":
                doExactConversion(token, NodeType.BooleanLiteral);
            default:
                if (hasNext()) {
                    var _peekNext = peekNext();
                    if (_peekNext.type == TokenType.LeftParen) {
                        parseFunctionCall(token);
                        return;
                    }

                    if (_peekNext.type == TokenType.Assign) {
                        parseVarAssign(token);
                        return;
                    }
                }

                doExactConversion(token, NodeType.Identifier);
        }
    }

    public function doExactConversion(token: Token, type: NodeType): Void {
        var literal: Node = {
            type: type,
            value: token.value,
            line: token.line,
            column: token.column,
            endLine: token.line,
            endColumn: token.column + token.value.length,
            parent: _root,
            children: []
        };

        addNode(literal);
    }

    public function parseSubExpression(token: Token): Void {
        prev();
        var subExprTokens: Array<Token> = getTokenArrayDelim(TokenType.LeftParen, TokenType.RightParen, 0);
        var subExprNode = createNode(NodeType.SubExpression, token, subExprTokens[subExprTokens.length - 1], null);

        var subExprCtx: ParserContext = new ParserContext(subExprTokens, _parser, subExprNode);
        subExprCtx.parse();

        if (subExprNode.children.length == 0) {
            return;
        }

        addNode(subExprNode);
    }

    public function parseMeta(token: Token): Void {
        if (token.type != TokenType.Meta) return;
        _metaEmpty = false;

        var tokenizer = Tokenizer.fromString(token.value);
        var name: String = tokenizer.tokens.shift().value;

        switch (name) {
            case "native_header":
                var headerName = tokenizer.tokens[0].value;
                _parser.ensureHeader(headerName);
            case "ctype":
                var alclType: String = tokenizer.tokens[0].value;
                var cType: String = tokenizer.tokens[1].value;
                _parser.getTypes().addAlclToCTypeMapping(alclType, cType);
            case "no_global_lib":
                @:privateAccess _parser._wantGlobalLib = false;
            default:
                _meta.set(name, tokenizer.tokens);
        }
    }

    public function addNode(node: Node): Void {
        _root.children.push(node);
        _lastNode = node;
    }

    public function pushLastNodeState(node: Node): Void {
        _lastNode = node;
    }

    public function iter(): Bool {
        if (!hasNext()) {
            return false;
        }

        var next: Token = next();
        var isMeta: Bool = false;

        switch (next.type) {
            case TokenType.Identifier:
                parseIdentifier(next);
            case TokenType.StringLiteral:
                doExactConversion(next, NodeType.StringLiteral);
            case TokenType.Float | TokenType.Integer:
                doExactConversion(next, NodeType.NumberLiteral);
            case TokenType.Meta:
                parseMeta(next);
                isMeta = true;
            case TokenType.LeftParen:
                parseSubExpression(next);
            default:
                var precedence: Int = getPrecedence(next.type);
                if (precedence > 0) {
                    parseOperator(next);
                }
                // TODO: unexpected token
        }

        if (!isMeta && !_metaEmpty) {
            _meta.clear();
            _metaEmpty = true;
        }

        return true;
    }

    public function getPrecedence(op: TokenType): Int {
        switch (op) {
            case TokenType.Or:
                return 1;
            case TokenType.And:
                return 2;
            case TokenType.BitwiseOr:
                return 3;
            case TokenType.BitwiseXor:
                return 4;
            case TokenType.BitwiseAnd:
                return 5;
            case TokenType.Equal | TokenType.NotEqual:
                return 6;
            case TokenType.Less | TokenType.LessEqual | TokenType.Greater | TokenType.GreaterEqual:
                return 7;
            case TokenType.Plus | TokenType.Minus:
                return 8;
            case TokenType.Star | TokenType.Slash | TokenType.Percent:
                return 9;
            case TokenType.Not | TokenType.BitwiseNot:
                return 10;
            default:
                return 0;
        }
    }


    public function parse(): ParserContext {
        while (true) {
            if (!iter()) break;
        }

        extractPosFromChildren(_root);
        return this;
    }

}
