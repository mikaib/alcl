package errors;

enum ErrorType {
    GenericError;
    UnsupportedFileType;
    FileNotFound;
    FileIsDirectory;
    UnexpectedNode;
    ReturnOutsideFunction;
    TypeMismatch;
    ReturnTypeMismatch;
    UndefinedVariable;
    FunctionNotDefined;
    FunctionParamCountMismatch;
    FunctionParamTypeMismatch;
}
