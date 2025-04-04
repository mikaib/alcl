package ast;

enum NodeType {
    None;
    Root;
    CCode;
    Cast;
    ToPtr;
    FromPtr;
    FunctionDecl;
    FunctionDeclParam;
    FunctionDeclParamType;
    FunctionDeclReturnType;
    FunctionDeclBody;
    FunctionDeclNativeBody;
    FunctionDeclExternBody;
    FunctionDeclNoRemap;
    FunctionDeclExternHeader;
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
    NullLiteral;
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
    ClassDecl;
    ClassBody;
    ClassExtends;
    Return;
}
