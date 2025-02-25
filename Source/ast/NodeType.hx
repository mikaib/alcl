package ast;

enum NodeType {
    None;
    Root;
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
    NumberLiteral;
    BooleanLiteral;
    Identifier;
    WhileLoop;
    WhileLoopCond;
    WhileLoopBody;
    WhileLoopBreak;
    WhileLoopContinue;
    IfStatement;
    IfStatementElse;
    IfStatementElseIf;
    IfStatementCond;
    IfStatementBody;
    UnaryOp;
    BinaryOp;
    OperationLeft;
    OperationRight;
    SubExpression;
    Return;
}
