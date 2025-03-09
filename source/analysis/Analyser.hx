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
    private var TNull: AnalyserFixedType = AnalyserType.createFixedType("Null");
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

    public function tryMatchUserTypeWithCasts(node: Node, scope: AnalyserScope, expect: AnalyserType, got: AnalyserType, ?err: ErrorType = ErrorType.TypeMismatch): AnalyserType {
        if (!expect.equals(got)) {
            var path = findCastPath(scope, got, expect);
            if (path.length == 0) {
                emitError(node, err, 'expected ${expect} but got ${got}');
            } else {
                castNodeTo(node, scope, expect);
            }
        }

        return got;
    }

    public function tryMatchUserType(node: Node, scope: AnalyserScope, expect: AnalyserType, got: AnalyserType, ?err: ErrorType = ErrorType.TypeMismatch): AnalyserType {
        if (!expect.equals(got)) {
            emitError(node, err, 'expected ${expect} but got ${got}');
        }

        return got;
    }

    /*
    ForLoop;
    ForLoopInit;
    ForLoopCond;
    ForLoopIter;
    ForLoopBody;
    WhileLoop;
    WhileLoopCond;
    WhileLoopBody;
     */
    public function inferType(node: Node, scope: AnalyserScope): Void {
        if (node == null) return;
        if (node.analysisType == null) node.analysisType = AnalyserType.createUnknownType();
        if (node.analysisScope == null) node.analysisScope = scope;
        if (!node.analysisType.isUnknown()) return;

        switch(node.type) {
            case NodeType.VarDef:
                tryTypeVariableDefinition(node, scope);
            case NodeType.VarAssign:
                tryTypeVariableAssignment(node, scope);
            case NodeType.BinaryOp:
                tryTypeBinaryOperator(node, scope);
            case NodeType.UnaryOp:
                tryTypeUnaryOperator(node, scope);
            case NodeType.FunctionDecl:
                tryTypeFunctionDecl(node, scope);
            case NodeType.Identifier:
                tryTypeIdentifier(node, scope);
            case NodeType.Ternary:
                tryTypeTernary(node, scope);
            case NodeType.FunctionCall:
                tryTypeFunctionCall(node, scope);
            case NodeType.NullLiteral:
                node.analysisType = AnalyserType.fromFixed(TNull);
            case NodeType.StringLiteral:
                node.analysisType = AnalyserType.fromFixed(TCString);
            case NodeType.FloatLiteral:
                node.analysisType = AnalyserType.fromFixed(TFloat32);
            case NodeType.IntLiteral:
                node.analysisType = AnalyserType.fromFixed(TInt32);
            case NodeType.BooleanLiteral:
                node.analysisType = AnalyserType.fromFixed(TBool);
            case NodeType.Root | NodeType.None | NodeType.CCode | NodeType.FunctionDeclBody | NodeType.FunctionDeclNativeBody | NodeType.FunctionDeclReturnType | NodeType.FunctionDeclParam | NodeType.FunctionDeclParamType | NodeType.TernaryTrue | NodeType.TernaryFalse | NodeType.TernaryCond:
                return; // skip
            default:
                node.analysisType = inferFirstChildOf(node, scope);
        }
    }

    public function tryTypeVariableAssignment(node: Node, scope: AnalyserScope): Void {
        var valueNode: Node = findChildOfType(node, NodeType.VarValue);
        if (valueNode == null) {
            emitError(node, ErrorType.GenericError, 'missing value node in assignment');
            return;
        }

        var variable: AnalyserVariable = scope.getVariable(node.value);
        if (variable == null) {
            emitError(node, ErrorType.UndefinedVariable, 'unknown variable ${node.value}');
            return;
        }

        if (variable.type.isUnknown()) {
            inferType(valueNode, scope);
            variable.type.setType(valueNode.analysisType);
        }

        variable.isInitialized = true;
        node.analysisType = variable.type;
    }

    public function tryTypeVariableDefinition(node: Node, scope: AnalyserScope): Void {
        var typeNode: Node = findChildOfType(node, NodeType.VarType);
        var valueNode: Node = findChildOfType(node, NodeType.VarValue);
        var initialized: Bool = false;

        if (valueNode != null) {
            inferType(valueNode, scope);
            node.analysisType.hintUsage(valueNode.analysisType);
            initialized = true;
        }

        if (typeNode != null) {
            node.analysisType.setTypeStr(typeNode.value);
        }

        scope.defineVariable(node.value, node.analysisType, node, initialized);
    }

    public function tryTypeFunctionCall(node: Node, scope: AnalyserScope): Void {
        var scopeFunction: AnalyserFunction = scope.getFunction(node.value);
        if (scopeFunction == null) {
            emitError(node, ErrorType.FunctionNotDefined, 'unknown function ${node.value}');
            return;
        }

        node.analysisType = scopeFunction.type;

        var params = findAllChildrenOfType(node, NodeType.FunctionCallParam);
        for (paramIdx in 0...params.length) {
            var paramNode = params[paramIdx];
            inferType(paramNode.children[0], scope);

            var analyserParam = scopeFunction.params[paramIdx];
            if (analyserParam == null) {
                emitError(node, ErrorType.FunctionParamCountMismatch, '"${scopeFunction.name}" expects ${scopeFunction.params.length} parameters but got ${params.length}');
                return;
            }

            paramNode.analysisType = paramNode.children[0].analysisType;
            paramNode.analysisType.hintUsage(analyserParam.type);
        }
    }

    public function tryTypeTernary(node: Node, scope: AnalyserScope): Void {
        var ternaryCond = findChildOfType(node, NodeType.TernaryCond);
        inferType(ternaryCond.children[0], scope);
        ternaryCond.analysisType = ternaryCond.children[0].analysisType;

        var ternaryTrue = findChildOfType(node, NodeType.TernaryTrue);
        inferType(ternaryTrue.children[0], scope);
        ternaryTrue.analysisType = ternaryTrue.children[0].analysisType;

        var ternaryFalse = findChildOfType(node, NodeType.TernaryFalse);
        inferType(ternaryFalse.children[0], scope);
        ternaryFalse.analysisType = ternaryFalse.children[0].analysisType;

        ternaryCond.analysisType.hintUsage(TBool.toMutableType());
        ternaryFalse.analysisType.hintUsage(ternaryTrue.analysisType);
        ternaryTrue.analysisType.hintUsage(ternaryFalse.analysisType);

        node.analysisType = ternaryTrue.analysisType;
    }

    public function tryTypeUnaryOperator(node: Node, scope: AnalyserScope): Void {
        inferType(node.children[0], scope);
        node.analysisType = node.children[0].analysisType;

        switch (node.value) {
            case '!': node.analysisType.hintUsage(TBool.toMutableType());
            case '-': node.analysisType.hintUsage(TInt32.toMutableType());
        }
    }

    public function tryTypeIdentifier(node: Node, scope: AnalyserScope): Void {
        var scopeVariable: AnalyserVariable = scope.getVariable(node.value);
        if (scopeVariable == null) {
            emitError(node, ErrorType.UndefinedVariable, 'unknown variable ${node.value}');
            return;
        }

        node.analysisType = scopeVariable.type;

        if (!scopeVariable.isInitialized) {
            emitError(node, ErrorType.UninitializedVariable, 'usage of variable ${node.value} before initialization');
            return;
        }
    }

    public function tryTypeFunctionDecl(node: Node, scope: AnalyserScope): Void {
        // parameters
        var funcParams: Array<Node> = findAllChildrenOfType(node, NodeType.FunctionDeclParam);
        var analyserFuncParams: Array<AnalyserFunctionParam> = [];

        for (p in funcParams) {
            var paramType: AnalyserType = AnalyserType.createUnknownType();
            var paramTypeNode: Node = findChildOfType(p, NodeType.FunctionDeclParamType);

            if (paramTypeNode != null) {
                paramType.setTypeStr(paramTypeNode.value);
                paramTypeNode.analysisType = paramType;
            }

            p.analysisType = paramType; // ast inspection
            scope.defineVariable(p.value, paramType, p);
            analyserFuncParams.push({ name: p.value, type: paramType, origin: p });
        }

        // return type
        var typeNode: Node = findChildOfType(node, NodeType.FunctionDeclReturnType);
        if (typeNode != null) {
            node.analysisType.setTypeStr(typeNode.value);
        }

        node.analysisType.hintUsage(TVoid.toMutableType());
        node.parent.analysisScope.defineFunction(node.value, node.analysisType, analyserFuncParams, node);
    }

    public function tryTypeBinaryOperator(node: Node, scope: AnalyserScope): Void {
        // TODO: support implicit casting
        if (!node.analysisType.isUnknown()) {
            return;
        }

        var left: Node = findChildOfType(node, NodeType.OperationLeft);
        var right: Node = findChildOfType(node, NodeType.OperationRight);

        if (left == null || right == null) {
            emitError(node, ErrorType.GenericError, 'missing left or right node.');
            return;
        }

        inferType(left, scope);
        inferType(right, scope);

        if ((left.analysisType.isUnknown() && !left.analysisType.isNull()) || (right.analysisType.isUnknown() && !right.analysisType.isNull())) {
            if (_compareOps.contains(node.value)) {
                // when comparing one unknown type with a known type, we hint the known type to the unknown type.
                // when we compare two unknown types, one will be hinted to Int32 and the other to the now known type (Int32).
                left.analysisType.hintUsage(right.analysisType);
                right.analysisType.hintUsage(left.analysisType);
            }

            left.analysisType.hintUsage(TInt32);
            right.analysisType.hintUsage(TInt32);
            return;
        }

        // compare logic
        if (_compareOps.contains(node.value)) {
            node.analysisType.setType(TBool);

            if (!left.analysisType.isComparableWith(right.analysisType)) {
                emitError(node, ErrorType.TypeKindMismatch, 'cannot compare ${left.analysisType} and ${right.analysisType}');
            }

            return;
        }

        // arithmetic logic
        if (!isNumericalType(left.analysisType) || !isNumericalType(right.analysisType)) {
            emitError(node, ErrorType.TypeKindMismatch, 'expected numerical types but got ${left.analysisType} and ${right.analysisType}');
            node.analysisType.setType(TInt32);
            return;
        }

        final priority: Array<AnalyserType> = [TInt32, TInt64, TFloat32, TFloat64];
        var leftPriority: Int = findTypeIdxInArray(left.analysisType, priority);
        var rightPriority: Int = findTypeIdxInArray(right.analysisType, priority);

        if (leftPriority == -1 || rightPriority == -1) {
            emitError(node, ErrorType.GenericError, 'could not find type in priority list.');
            return;
        }

        var resultType: AnalyserType = priority[Std.int(Math.max(leftPriority, rightPriority))];
        node.analysisType.setType(resultType);
    }

    public function verifyNode(node: Node, scope: AnalyserScope): Void {
        // first we verify against user-set types
        var userType: AnalyserType = getUserSetType(node);
        if (!node.analysisType.isUnknown() && !userType.isUnknown()) {
            tryMatchUserType(node, scope, userType, node.analysisType, getTypeMismatchErr(node));
        }

        // then we check for node-specific type checks
        switch(node.type) {
            case NodeType.VarAssign:
                verifyVariableAssignment(node, scope);
            case NodeType.VarDef:
                verifyVariableDefinition(node, scope);
            case NodeType.LoopContinue:
                verifyLoopControl(node, scope, ErrorType.ContineOutsideLoop);
            case NodeType.LoopBreak:
                verifyLoopControl(node, scope, ErrorType.BreakOutsideLoop);
            case NodeType.IfStatement:
                verifyIfStatement(node, scope, null, true);
            case NodeType.IfStatementElseIf:
                verifyIfStatement(node, scope, [NodeType.IfStatement, NodeType.IfStatementElseIf], true);
            case NodeType.IfStatementElse:
                verifyIfStatement(node, scope, [NodeType.IfStatement, NodeType.IfStatementElseIf], false);
            case NodeType.BinaryOp:
                verifyBinaryOp(node, scope);
            case NodeType.UnaryOp:
                verifyUnaryOp(node, scope);
            case NodeType.Ternary:
                verifyTernary(node, scope);
            case NodeType.Return:
                verifyReturnType(node, scope);
            case NodeType.FunctionCall:
                verifyFunctionCall(node, scope);
            case NodeType.Identifier | NodeType.FunctionDecl:
                node.analysisType.applyHintedUsageIfUnknown();
            default:
                return;
        }
    }

    public function verifyVariableAssignment(node: Node, scope: AnalyserScope): Void {
        var valueNode: Node = findChildOfType(node, NodeType.VarValue);
        if (valueNode == null) {
            emitError(node, ErrorType.GenericError, 'missing value node in assignment');
            return;
        }

        var variable: AnalyserVariable = scope.getVariable(node.value);
        if (variable == null) {
            emitError(node, ErrorType.UndefinedVariable, 'unknown variable ${node.value}');
            return;
        }

        inferType(valueNode, scope);
        valueNode.analysisType.applyHintedUsageIfUnknown();

        if (!variable.type.equals(valueNode.analysisType)) {
            var castPath = findCastPath(scope, valueNode.analysisType, variable.type);
            if (castPath.length > 0) {
                castNodeTo(valueNode.children[0], scope, variable.type);
                return;
            }

            emitError(node, ErrorType.TypeMismatch, 'expected ${variable.type} but got ${valueNode.analysisType}');
        }
    }

    public function verifyVariableDefinition(node: Node, scope: AnalyserScope): Void {
        var valueNode: Node = findChildOfType(node, NodeType.VarValue);
        if (valueNode == null) {
            var typeNode: Node = findChildOfType(node, NodeType.VarType);
            if (typeNode == null) {
                if (node.analysisType.isUnknown()) {
                    emitError(node, ErrorType.GenericError, 'cannot determine type of variable definition ${node.value}');
                }
                return;
            }

            node.analysisType.setTypeStr(typeNode.value);

            var valueNodeType: NodeType = NodeType.NullLiteral;
            var valueNodeValue: String = 'null';

            if (node.analysisType.isBooleanType()) {
                valueNodeType = NodeType.BooleanLiteral;
                valueNodeValue = 'false';
            } else if (node.analysisType.isFloatingPointType()) {
                valueNodeType = NodeType.FloatLiteral;
                valueNodeValue = '0.0';
            } else if (node.analysisType.isIntegerType()) {
                valueNodeType = NodeType.IntLiteral;
                valueNodeValue = '0';
            }

            valueNode = createNode(NodeType.VarValue, node, null, null, null);
            valueNode.analysisType = AnalyserType.createUnknownType();
            valueNode.analysisScope = scope;
            valueNode.parent = node;

            var valueNodeInternal = createNode(valueNodeType, node, null, null, valueNodeValue);
            valueNode.children.push(valueNodeInternal);
            valueNodeInternal.analysisType = AnalyserType.createUnknownType();
            valueNodeInternal.analysisScope = scope;
            valueNodeInternal.parent = valueNode;

            node.children.push(valueNode);
        }

        valueNode.analysisType = valueNode.children[0].analysisType;
        inferType(valueNode, scope);

        var typeNode: Node = findChildOfType(node, NodeType.VarType);
        if (typeNode != null) {
            node.analysisType.setTypeStr(typeNode.value);
        }

        node.analysisType.applyHintedUsageIfUnknown();

        if (node.analysisType.isUnknown()) {
            emitError(node, ErrorType.GenericError, 'could not infer type of variable definition');
            return;
        }

        if (!valueNode.analysisType.equals(node.analysisType)) {
            var castPath = findCastPath(scope, valueNode.analysisType, node.analysisType);
            if (castPath.length > 0) {
                castNodeTo(valueNode.children[0], scope, node.analysisType);
                return;
            }

            emitError(node, ErrorType.TypeMismatch, 'expected ${node.analysisType} but got ${valueNode.analysisType}');
        }
    }

    public function verifyLoopControl(node: Node, scope: AnalyserScope, error: ErrorType): Void {
        var parent = findParentOfType(node, NodeType.ForLoop) ??  findParentOfType(node, NodeType.WhileLoop);
        if (parent == null) {
            emitError(node, error, '${node.value} outside of loop');
        }
    }

    public function verifyIfStatement(node: Node, scope: AnalyserScope, previousMustBe: Null<Array<NodeType>>, hasCondition: Bool): Void {
        var body = findChildOfType(node, NodeType.IfStatementBody);
        var cond = findChildOfType(node, NodeType.IfStatementCond);

        if (hasCondition) {
            if (cond == null) {
                emitError(node, ErrorType.MissingCondition, '${node.type} is missing a condition!');
                return;
            }

            if (!cond.analysisType.equals(TBool)) {
                emitError(node, ErrorType.TypeMismatch, 'condition of ${node.type} needs to be Bool but got ${cond.analysisType.toString()}');
                return;
            }
        }

        if (body == null) {
            emitError(node, ErrorType.MissingBody, '${node.type} is missing a body!');
            return;
        }

        if (previousMustBe != null) {
            var parent = node.parent;
            var selfIdx = parent.children.indexOf(node);
            var prevIdx = selfIdx - 1;

            if (prevIdx <= 0) {
                emitError(node, ErrorType.UnexpectedNode, 'expected previous node to be one of (${previousMustBe.join(', ')}) but no node was found!');
                return;
            }

            if (!previousMustBe.contains(parent.children[prevIdx].type)) {
                emitError(node, ErrorType.UnexpectedNode, 'expected previous node to be one of (${previousMustBe.join(', ')}) but got ${parent.children[prevIdx].type}');
                return;
            }
        }
    }

    public function verifyFunctionCall(node: Node, scope: AnalyserScope): Void {
        var scopeFunction: AnalyserFunction = scope.getFunction(node.value);
        if (scopeFunction == null) {
            emitError(node, ErrorType.FunctionNotDefined, 'unknown function ${node.value}');
            return;
        }

        var params = findAllChildrenOfType(node, NodeType.FunctionCallParam);
        var failure: Bool = false;
        for (paramIdx in 0...params.length) {
            var paramNode = params[paramIdx];
            var analyserParam = scopeFunction.params[paramIdx];

            if (analyserParam == null) {
                emitError(node, ErrorType.FunctionParamCountMismatch, '"${scopeFunction.name}" expects ${scopeFunction.params.length} parameters but got ${params.length}');
                return;
            }

            if (analyserParam.type.equals(paramNode.analysisType)) {
                continue;
            }

            var castPath = findCastPath(scope, paramNode.analysisType, analyserParam.type);
            if (castPath.length > 0) {
                castNodeTo(paramNode.children[0], scope, analyserParam.type);
                continue;
            }

            failure = true;
        }

        if (failure) {
            emitError(node, ErrorType.FunctionParamTypeMismatch, 'expected (${scopeFunction.params.map(p -> p.type).join(', ')}) but got (${params.map(p -> p.analysisType.toString()).join(', ')})');
        }
    }

    public function verifyReturnType(node: Node, scope: AnalyserScope): Void {
        var funcDecl: Node = findParentOfType(node, NodeType.FunctionDecl);
        if (funcDecl == null) {
            emitError(node, ErrorType.ReturnOutsideFunction, 'cannot find any function decl at a higher level');
            return;
        }

        if (!funcDecl.analysisType.isUnknown() && !funcDecl.analysisType.equals(node.analysisType)) {
            var castPath = findCastPath(scope, node.analysisType, funcDecl.analysisType);
            if (castPath.length == 0) {
                emitError(node, ErrorType.ReturnTypeMismatch, 'expected ${funcDecl.analysisType} but got ${node.analysisType}');
                return;
            }

            castNodeTo(node.children[0], scope, funcDecl.analysisType);
            return;
        }

        funcDecl.analysisType.setType(node.analysisType);

        var userType: AnalyserType = getUserSetType(funcDecl);
        if (!userType.isUnknown()) {
            tryMatchUserTypeWithCasts(node.children[0], scope, userType, node.analysisType, ErrorType.ReturnTypeMismatch);
        }
    }

    public function verifyTernary(node: Node, scope: AnalyserScope): Void {
        var ternaryCond: Node = findChildOfType(node, NodeType.TernaryCond);
        var ternaryTrue: Node = findChildOfType(node, NodeType.TernaryTrue);
        var ternaryFalse: Node = findChildOfType(node, NodeType.TernaryFalse);

        ternaryCond.analysisType.applyHintedUsageIfUnknown();
        ternaryTrue.analysisType.applyHintedUsageIfUnknown();
        ternaryFalse.analysisType.applyHintedUsageIfUnknown();

        if (!ternaryCond.analysisType.equals(TBool)) {
            emitError(node, ErrorType.TypeMismatch, 'Ternary expects Bool got ${ternaryCond.analysisType}');
            return;
        }

        if (!ternaryTrue.analysisType.equals(ternaryFalse.analysisType)) {
            var trueToFalse: Array<AnalyserCastMethod> = findCastPath(scope, ternaryTrue.analysisType, ternaryFalse.analysisType);
            if (trueToFalse.length > 0) {
                castNodeTo(ternaryTrue.children[0], scope, ternaryFalse.analysisType);
                return;
            }

            var falseToTrue: Array<AnalyserCastMethod> = findCastPath(scope, ternaryFalse.analysisType, ternaryTrue.analysisType);
            if (falseToTrue.length > 0) {
                castNodeTo(ternaryFalse.children[0], scope, ternaryTrue.analysisType);
                return;
            }

            emitError(node, ErrorType.TernaryMismatch, 'Ternary has incompatible resulting types, got ${ternaryTrue.analysisType} : ${ternaryFalse.analysisType}');
            return;
        }
    }

    public function verifyBinaryOp(node: Node, scope: AnalyserScope): Void {
        tryTypeBinaryOperator(node, scope);

        if (node.analysisType.isUnknown()) {
            var left = findChildOfType(node, NodeType.OperationLeft);
            var right = findChildOfType(node, NodeType.OperationRight);

            emitError(node, ErrorType.TypeInferenceError, 'could not infer resulting type of binary operation, got ${left.analysisType} ${node.value} ${right.analysisType}');
        }
    }

    public function verifyUnaryOp(node: Node, scope: AnalyserScope): Void {
        switch(node.value) {
            case "!":
                if (!node.analysisType.equals(TBool)) {
                    emitError(node, ErrorType.TypeMismatch, 'expected Bool but got ${node.analysisType}');
                }
            case "-":
                if (!isNumericalType(node.analysisType)) {
                    emitError(node, ErrorType.TypeKindMismatch, 'expected numerical type but got ${node.analysisType}');
                }
            default:
                emitError(node, ErrorType.UnknownUnaryOp, 'Unknown unary operator ${node.value}');
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

    public function getTypeMismatchErr(node: Node): ErrorType {
        switch (node.type) {
            case NodeType.Return:
                return ErrorType.ReturnTypeMismatch;
            default:
                return ErrorType.TypeMismatch;
        }
    }

    public function runAtNode(node: Node, scope: AnalyserScope): Void {
        var subScope: AnalyserScope = getNodeScope(node, scope);

        inferType(node, subScope);
        for (child in node.children) {
            runAtNode(child, subScope);
        }

        for (child in node.children) {
            verifyNode(child, subScope);
        }
    }

    public function getErrors(): ErrorContainer {
        return _errors;
    }

    public function findTypeIdxInArray(type: AnalyserType, array: Array<AnalyserType>): Int {
        for (i in 0...array.length) {
            if (array[i].equals(type)) {
                return i;
            }
        }
        return -1;
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

    public function run(): Void {
        var scope: AnalyserScope = new AnalyserScope(this);

        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt32, TInt64, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt32, TFloat32, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt32, TFloat64, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TInt64, TFloat64, true));
        scope.addCastMethod(AnalyserCastMethod.usingCast(TFloat32, TFloat64, true));

        runAtNode(_parser.getRoot(), scope);
    }

}
