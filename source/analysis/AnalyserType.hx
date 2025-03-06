package analysis;

// A general type can be hinted, modified or transformed in any way.
class AnalyserType {

    private var _type: Null<String>;
    private var _onChangeCallbacks: Array<Void->Void>;

    public static function createUnknownType(): AnalyserType {
        return new AnalyserType();
    }

    public static function createType(typeName: String): AnalyserType {
        var analyserType = new AnalyserType();
        analyserType._type = typeName;
        return analyserType;
    }

    public static function createFixedType(typeName: String): AnalyserFixedType {
        var analyserType = new AnalyserFixedType();
        analyserType._type = typeName;
        return analyserType;
    }

    public static function fromFixed(other: AnalyserFixedType): AnalyserType {
        var analyserType = new AnalyserType();
        analyserType._type = other._type;
        return analyserType;
    }

    private function new() {
        _type = null;
        _onChangeCallbacks = [];
    }

    public function onTypeChange(cb: Void->Void, runImmediately: Bool = true): Void {
        _onChangeCallbacks.push(cb);

        if (runImmediately) {
            cb();
        }
    }

    public function toFixed(): AnalyserFixedType {
        var analyserType = new AnalyserFixedType();
        analyserType._type = _type;
        return analyserType;
    }

    public function toMutableType(): AnalyserType {
        var analyserType = new AnalyserType();
        analyserType._type = _type;
        return analyserType;
    }

    public function setType(typeName: String): Void {
        _type = typeName;

        for (cb in _onChangeCallbacks) {
            cb();
        }
    }

    public function hintIfUnknown(typeName: String): Void {
        if (_type == null) {
            _type = typeName;
        }
    }

    public function isUnknown(): Bool {
        return _type == null;
    }

    @:op(A == B)
    public function equals(other: AnalyserType): Bool {
        return _type == other._type;
    }

    @:to
    public function toString(): String {
        var baseType = _type;
        if (baseType == null) {
            return "Unknown";
        }

        return baseType;
    }

}