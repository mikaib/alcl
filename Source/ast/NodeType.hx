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
    Identifier;
    WhileLoop;
    WhileLoopCond;
    WhileLoopBody;
    UnaryOp;
    BinaryOp;
    OperationLeft;
    OperationRight;
    SubExpression;
    Return;
}
