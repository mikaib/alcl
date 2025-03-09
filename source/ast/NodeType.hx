package ast;

enum NodeType {
    None;
    Root;
    CCode;
    Cast;
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
    FloatLiteral;
    IntLiteral;
    BooleanLiteral;
    Identifier;
    ForLoop;
    ForLoopInit;
    ForLoopCond;
    ForLoopIter;
    ForLoopBody;
    WhileLoop;
    WhileLoopCond;
    WhileLoopBody;
    LoopBreak;
    LoopContinue;
    IfStatement;
    IfStatementElse;
    IfStatementElseIf;
    IfStatementCond;
    IfStatementBody;
    Ternary;
    TernaryCond;
    TernaryTrue;
    TernaryFalse;
    UnaryOp;
    BinaryOp;
    OperationLeft;
    OperationRight;
    SubExpression;
    Return;
}
