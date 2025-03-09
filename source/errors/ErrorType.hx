package errors;

enum ErrorType {
    GenericError;
    UnsupportedFileType;
    FileNotFound;
    FileIsDirectory;
    UnexpectedNode;
    ReturnOutsideFunction;
    TypeMismatch;
    TypeKindMismatch;
    TypeInferenceError;
    TypeCastError;
    ReturnTypeMismatch;
    UndefinedVariable;
    FunctionNotDefined;
    FunctionParamCountMismatch;
    FunctionParamTypeMismatch;
    UnknownUnaryOp;
    TernaryMismatch;
    MissingCondition;
    MissingBody;
}
