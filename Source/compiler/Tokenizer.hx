package compiler;

import util.Logging;

class Tokenizer {

    public var code: String;
    public var tokens: Array<Token>;
    public var inlineTokenizer: Bool;

    /**
     * Create a new Tokenizer from a string.
     */
    public static function fromString(code: String, inlineTokenizer: Bool = true) {
        var t = new Tokenizer(code, inlineTokenizer);
        t.tokenize();

        return t;
    }

    /**
     * Create a new Tokenizer from a string.
     */
    private function new(code: String, inlineTokenizer: Bool = true) {
        this.code = code;
        this.tokens = [];
        this.inlineTokenizer = inlineTokenizer;
    }

    /**
     * Tokenize the code.
     */
    public function tokenize() {
        var i = 0;
        var line = 1;
        var column = 1;

        while (i < code.length) {
            var c = code.charAt(i);

            switch (c) {
                case '\t':
                    column++;
                    i++;
                    continue;

                case ' ':
                    column++;
                    i++;
                    continue;

                case '\r':
                    column++;
                    i++;
                    continue;

                case '\n':
                    line++;
                    column = 1;
                    i++;

                    if (tokens.length > 0) {
                        var lastToken = tokens[tokens.length - 1];
                        if (lastToken.type != TokenType.Semicolon && !inlineTokenizer) {
                            tokens.push({ type: TokenType.Semicolon, value: ';', line: line, column: column, index: i });
                        }
                    }
                    continue;

                case '(':
                    tokens.push({ type: TokenType.LeftParen, value: c, line: line, column: column, index: i });
                    column++;

                case ')':
                    tokens.push({ type: TokenType.RightParen, value: c, line: line, column: column, index: i });
                    column++;

                case '{':
                    tokens.push({ type: TokenType.LeftBrace, value: c, line: line, column: column, index: i });
                    column++;

                case '}':
                    tokens.push({ type: TokenType.RightBrace, value: c, line: line, column: column, index: i });
                    column++;

                case '[':
                    tokens.push({ type: TokenType.LeftBracket, value: c, line: line, column: column, index: i });
                    column++;

                case ']':
                    tokens.push({ type: TokenType.RightBracket, value: c, line: line, column: column, index: i });
                    column++;

                case ',':
                    tokens.push({ type: TokenType.Comma, value: c, line: line, column: column, index: i });
                    column++;

                case '.':
                    tokens.push({ type: TokenType.Dot, value: c, line: line, column: column, index: i });
                    column++;

                case '-':
                    tokens.push({ type: TokenType.Minus, value: c, line: line, column: column, index: i });
                    column++;

                case '+':
                    tokens.push({ type: TokenType.Plus, value: c, line: line, column: column, index: i });
                    column++;

                case ';':
                    tokens.push({ type: TokenType.Semicolon, value: c, line: line, column: column, index: i });
                    column++;

                case '/':
                    if (i + 1 < code.length && code.charAt(i + 1) == '/') { // comments
                        var j = i + 2;
                        while (j < code.length) {
                            var c2 = code.charAt(j);
                            if (c2 == '\n') {
                                break;
                            }
                            j++;
                        }
                        line += 1;
                        column = 1;
                        i = j;
                        continue;
                    }

                    tokens.push({ type: TokenType.Slash, value: c, line: line, column: column, index: i });
                    column++;

                case '*':
                    tokens.push({ type: TokenType.Star, value: c, line: line, column: column, index: i });
                    column++;

                case '%':
                    tokens.push({ type: TokenType.Percent, value: c, line: line, column: column, index: i });
                    column++;

                case '?':
                    tokens.push({ type: TokenType.Question, value: c, line: line, column: column, index: i });
                    column++;

                case ':':
                    tokens.push({ type: TokenType.Colon, value: c, line: line, column: column, index: i });
                    column++;

                case '=':
                    if (i + 1 < code.length && code.charAt(i + 1) == '=') {
                        tokens.push({ type: TokenType.Equal, value: '==', line: line, column: column, index: i });
                        column += 2;
                        i++;
                    } else {
                        tokens.push({ type: TokenType.Assign, value: c, line: line, column: column, index: i });
                        column++;
                    }

                case '"':
                    var startIdx = i;
                    var quoteType = c;
                    i++;
                    while (i < code.length && code.charAt(i) != quoteType) {
                        i++;
                    }
                    var stringValue = code.substring(startIdx + 1, i);
                    tokens.push({ type: TokenType.StringLiteral, value: stringValue, line: line, column: column, index: startIdx });
                    column += i - startIdx + 1;
                    i++;
                    continue;

                default:
                    var charCode = c.charCodeAt(0);

                    // modifiers
                    if (charCode == 35 && StringTools.trim(getChars(i - column + 1, i)) == "") {
                        var value = "";
                        var j = i + 1;
                        while (j < code.length) {
                            var c2 = code.charAt(j);
                            if (c2 == '\n') {
                                break;
                            }
                            value += c2;
                            j++;
                        }

                        tokens.push({ type: TokenType.Meta, value: value, line: line, column: column, index: i });
                        line += 1;
                        column = 1;
                        i = j;
                  } else if ((charCode >= 48 && charCode <= 57) || c == '.') {
                        // integers and floating point
                        var value = c;
                        var j = i + 1;
                        var hasDot = (c == '.');
                        while (j < code.length) {
                            var c2 = code.charAt(j);
                            var charCode2 = c2.charCodeAt(0);
                            if ((charCode2 >= 48 && charCode2 <= 57) || (c2 == '.' && !hasDot)) {
                                if (c2 == '.') {
                                    hasDot = true;
                                }
                                value += c2;
                                j++;
                            } else {
                                break;
                            }
                        }

                        tokens.push({ type: hasDot ? TokenType.Float : TokenType.Integer, value: value, line: line, column: column, index: i });

                        column += j - i;
                        i = j;
                        continue;
                    } else {
                        // identifiers
                        var value = c;
                        var j = i + 1;
                        while (j < code.length) {
                            var c2 = code.charAt(j);
                            var charCode2 = c2.charCodeAt(0);
                            if ((charCode2 >= 65 && charCode2 <= 90) ||
                            (charCode2 >= 97 && charCode2 <= 122) ||
                            (charCode2 >= 48 && charCode2 <= 57) ||
                            charCode2 == 95) {
                                value += c2;
                                j++;
                            } else {
                                break;
                            }
                        }

                        tokens.push({ type: TokenType.Identifier, value: value, line: line, column: column, index: i });

                        column += j - i;
                        i = j;
                        continue;
                    }
            }

            i++; // Move to the next character
        }

    }

    /**
     * Get chars from the code.
     * @param startLine The start line.
     * @param startColumn The start column.
     * @param endLine The end line.
     * @param endColumn The end column.
     */
    public function getChars(fromIdx:Int, toIdx:Int):String {
        return code.substring(fromIdx, toIdx);
    }

    /**
     * Get the tokens.
     */
    public function iterator():Iterator<Token> {
        return tokens.iterator();
    }

    /**
     * Print the tokens.
     */
    public function print() {
        for (token in tokens) {
            Logging.debug('[${token.line}:${token.column}] (${token.type}) ${token.value}');
        }
    }

}
