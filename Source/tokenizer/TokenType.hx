package tokenizer;

enum TokenType {
    Null;
    Identifier;
    Float;
    Integer;
    LeftParen;
    RightParen;
    LeftBrace;
    RightBrace;
    LeftBracket;
    RightBracket;
    Comma;
    Dot;
    Minus;
    Plus;
    Semicolon;
    Slash;
    Star;
    Percent;
    Question;
    Assign;
    Equal;
    Colon;
    StringLiteral;
    Meta;
    Spread;

    And;
    Or;
    Less;
    Greater;
    LessEqual;
    GreaterEqual;
    NotEqual;
    Not; // TODO: implement this
    BitwiseAnd; // TODO: implement this
    BitwiseOr; // TODO: implement this
    BitwiseXor; // TODO: implement this
    BitwiseNot; // TODO: implement this
}

