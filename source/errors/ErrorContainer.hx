package errors;
import util.Logging;

class ErrorContainer {

    private var _errors: Array<String>;

    public function new() {
        _errors = new Array<String>();
    }

    /**
     * Returns the errors as a string.
     */
    public function addError(error: Error) {
        _errors.push(error.toString());
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
