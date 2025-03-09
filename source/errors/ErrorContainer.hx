package errors;
import util.Logging;

class ErrorContainer {

    private var _errors: Array<String>;
    private var _errorObjs: Array<Error>;

    public function new() {
        _errors = [];
        _errorObjs = [];
    }

    /**
     * Returns the errors as a string.
     */
    public function addError(error: Error) {
        for (e in _errorObjs) {
            if (e.equals(error)) {
                return;
            }
        }

        _errors.push(error.toString());
        _errorObjs.push(error);
    }

    /**
     * Check if it has errors.
     */
    public function hasErrors(): Bool {
        return _errors.length > 0;
    }

    /**
     * Returns the errors as a string.
     */
    public function printErrors(exit: Bool = true): Void {
        for (error in _errors) {
            Logging.error(error);
        }

        if (exit && _errors.length > 0) {
            Sys.exit(1);
        }
    }

}
