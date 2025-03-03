package analysis;

class AnalyserType {

    public static function createUnknownType(): AnalyserType {
        return new AnalyserType();
    }

    public static function createType(typeName: String): AnalyserType {
        var analyserType = new AnalyserType();
        analyserType._type = typeName;
        return analyserType;
    }

    private var _type: Null<String>;

    private function new() {
        _type = null;
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