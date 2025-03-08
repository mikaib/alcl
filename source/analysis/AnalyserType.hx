package analysis;

// A general type can be hinted, modified or transformed in any way.
class AnalyserType {

    private var _type: Null<String>;
    private var _currentHintPriority: Int = 0xFFFF;
    private var _hintedUsageType: Array<AnalyserType>;
    private var _onChangeCallbacks: Array<Void->Void>;

    private var _id: Int;
    private static var _count: Int = 0;

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
        analyserType._hintedUsageType = other._hintedUsageType;
        return analyserType;
    }

    private function new() {
        _type = null;
        _onChangeCallbacks = [];
        _hintedUsageType = [];
        _id = _count++;
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
        analyserType._hintedUsageType = _hintedUsageType; // TODO: maybe copy both of these...
        return analyserType;
    }

    public function toMutableType(): AnalyserType {
        var analyserType = new AnalyserType();
        analyserType._type = _type;
        analyserType._hintedUsageType = _hintedUsageType; // TODO: maybe copy both of these...
        return analyserType;
    }

    public function setTypeStr(typeName: String): Void {
        _type = typeName;

        for (cb in _onChangeCallbacks) {
            cb();
        }
    }

    public function setType(type: AnalyserType): Void {
        setTypeStr(type._type);
    }

    public function setIfUnknown(type: AnalyserType): Void {
        if (_type == null) {
            setType(type);
        }
    }

    public function hintUsage(type: AnalyserType): Void {
        if (_hintedUsageType.contains(type)) return;

        _hintedUsageType.push(type);
    }

    public function applyHintedUsageIfUnknown(): Void {
        if (_type == null && _hintedUsageType.length > 0) {
            for (t in _hintedUsageType) {
                var idx = _hintedUsageType.indexOf(t);
                if (!t.isUnknown()) {
                    _currentHintPriority = idx;
                    setType(t);

                    break;
                } else {
                    t.onTypeChange(() -> {
                        if (idx < _currentHintPriority) {
                            _currentHintPriority = idx;
                            setType(t);
                        }
                    });
                }
            }
        }
    }

    public function isUnknown(): Bool {
        return _type == null;
    }

    @:op(A == B)
    public function equals(other: AnalyserType): Bool {
        return _type == other._type;
    }

    public function isComparableWith(other: AnalyserType): Bool {
        return this.equals(other) || (this.isNumericalType() && other.isNumericalType());
    }

    public function isNumericalType(): Bool {
        return _type == "Int32" || _type == "Int64" || _type == "Float32" || _type == "Float64";
    }

    public function toDebugString(): String {
        var baseType = _type;
        if (baseType == null) {
            baseType = "Unknown";
        }

        return '$baseType (#$_id)';
    }

    @:to
    public function toString(): String {
        var baseType = _type;
        if (baseType == null) {
            baseType = "Unknown";
        }

        return baseType;
    }

}