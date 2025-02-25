package compiler;

@:structInit
class Token {
    public var type: TokenType;
    public var value: String;
    public var line: Int;
    public var column: Int;
    public var index: Int;
}
