package errors;

@:structInit
class Error {
    public var message: String;
    public var position: { line: Int, column: Int, file: String } = null;
    public var stack: Array<Error> = [];
    public var type: ErrorType = ErrorType.GenericError;

    public function toString(): String {
        var str = '';
        if (this.position != null) {
            str += '${this.position.file}:${this.position.line}:${this.position.column}: ';
        }
        str += '${this.type}: ${this.message}';
        if (this.stack.length > 0) {
            str += '\n';
            for (error in this.stack) {
                str += '  ${error.toString().split('\n').join('\n  ')}\n';
            }
        }
        return str;
    }

}
