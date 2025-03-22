package analysis;

@:structInit
class AnalyserCastMethod {
    private var _from: AnalyserType;
    private var _to: AnalyserType;
    private var _function: AnalyserFunction = null;
    private var _usingCast: Bool = false;
    private var _usingToPtr: Bool = false;
    private var _usingFromPtr: Bool = false;
    private var _usingFunction: Bool = false;
    private var _isImplicit: Bool = false;

    public static function usingCast(from: AnalyserType, to: AnalyserType, isImplicit: Bool = false): AnalyserCastMethod {
        return {
            _from: from,
            _to: to,
            _usingCast: true,
            _isImplicit: isImplicit
        }
    }

    public static function usingFunction(from: AnalyserType, to: AnalyserType, usingFunction: AnalyserFunction, isImplicit: Bool = false): AnalyserCastMethod {
        return {
            _from: from,
            _to: to,
            _function: usingFunction,
            _usingFunction: true,
            _isImplicit: isImplicit
        }
    }

    public static function usingFromPtr(from: AnalyserType, to: AnalyserType, isImplicit: Bool = false): AnalyserCastMethod {
        return {
            _from: from,
            _to: to,
            _usingFromPtr: true,
            _isImplicit: isImplicit
        }
    }

    public static function usingToPtr(from: AnalyserType, to: AnalyserType, isImplicit: Bool = false): AnalyserCastMethod {
        return {
            _from: from,
            _to: to,
            _usingToPtr: true,
            _isImplicit: isImplicit
        }
    }

    public function getFrom(): AnalyserType {
        return _from;
    }

    public function getTo(): AnalyserType {
        return _to;
    }

    public function getFunction(): AnalyserFunction {
        return _function;
    }

    public function isUsingCast(): Bool {
        return _usingCast;
    }

    public function isUsingFunction(): Bool {
        return _usingFunction;
    }

    public function isUsingFromPtr(): Bool {
        return _usingFromPtr;
    }

    public function isUsingToPtr(): Bool {
        return _usingToPtr;
    }

    public function isImplicit(): Bool {
        return _isImplicit;
    }

    @:to
    public function toString(): String {
        return '$_from->$_to';
    }
}
