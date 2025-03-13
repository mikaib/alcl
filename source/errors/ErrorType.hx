package errors;

enum ErrorType {
    GenericError;
    UnsupportedFileType;
    FileNotFound;
    FileIsDirectory;
    SyntaxError;
    TypeMismatch;
    TypeInferenceError;
    TypeCastError;
    ReturnOutsideFunction;
    UndefinedVariable;
    UninitializedVariable;
    UndefinedFunction;
    ArgumentCountMismatch;
}
