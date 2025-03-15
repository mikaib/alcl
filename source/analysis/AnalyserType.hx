package analysis;

// A general type can be hinted, modified or transformed in any way.
class AnalyserType {

    private var _type: Null<String>;
    private var _isHint: Bool;
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
        return analyserType;
    }

    private function new() {
        _type = null;
        _onChangeCallbacks = [];
        _id = _count++;
        _isHint = false;
    }

    public function isHint(): Bool {
        return _isHint;
    }

    public function setHintStatus(isHint: Bool): Void {
        _isHint = isHint;
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

    public function setTypeStr(typeName: String): Void {
        _type = typeName;

        for (cb in _onChangeCallbacks) {
            cb();
        }
    }

    public function setType(type: AnalyserType): Void {
        if (!type.isUnknown()) setTypeStr(type._type);
    }

    public function setIfUnknown(type: AnalyserType): Void {
        if (_type == null) {
            setType(type);
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

    public function isFloatingPointType(): Bool {
        return _type == "Float32" || _type == "Float64";
    }

    public function isIntegerType(): Bool {
        return _type == "Int32" || _type == "Int64";
    }

    public function isBooleanType(): Bool {
        return _type == "Bool";
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