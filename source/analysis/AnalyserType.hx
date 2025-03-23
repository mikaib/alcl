package analysis;

// A general type can be hinted, modified or transformed in any way.
class AnalyserType {

    private var _type: Null<String>;
    private var _params: Array<AnalyserType>;
    private var _isHint: Bool;
    private var _copiedFrom: Null<AnalyserType>;
    private var _onChangeCallbacks: Array<Void->Void>;

    private var _id: Int;
    private static var _count: Int = 0;

    public static function createUnknownType(): AnalyserType {
        return new AnalyserType();
    }

    public static function createType(typeName: String): AnalyserType {
        var analyserType = new AnalyserType();
        analyserType.setTypeStr(typeName);
        return analyserType;
    }

    public static function createFixedType(typeName: String): AnalyserFixedType {
        return createType(typeName).toFixed();
    }

    public static function fromFixed(other: AnalyserFixedType): AnalyserType {
        return createType(other.toString());
    }

    private function new() {
        _type = null;
        _onChangeCallbacks = [];
        _params = [];
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
        for (param in _params) {
            analyserType._params.push(param.toFixed());
        }

        return analyserType;
    }

    public function toMutableType(): AnalyserType {
        var analyserType = new AnalyserType();
        analyserType._type = _type;
        for (param in _params) {
            analyserType._params.push(param.toMutableType());
        }
        return analyserType;
    }

    public function setTypeStr(typeName: String): Void {
        _params = [];

        if (typeName.indexOf("<") != -1 && typeName.lastIndexOf(">") != -1) {
            var baseTypeEnd = typeName.indexOf("<");
            var baseType = typeName.substr(0, baseTypeEnd);
            var paramsStr = typeName.substring(baseTypeEnd + 1, typeName.lastIndexOf(">"));

            _type = baseType;

            var params = parseTypeParams(paramsStr);
            for (param in params) {
                var paramType = new AnalyserType();
                paramType.setTypeStr(param);
                _params.push(paramType);
            }
        } else {
            _type = typeName;
        }

        for (cb in _onChangeCallbacks) {
            cb();
        }
    }

    private function parseTypeParams(paramsStr: String): Array<String> {
        var params: Array<String> = [];
        var currentParam = "";
        var depth = 0;

        for (i in 0...paramsStr.length) {
            var char = paramsStr.charAt(i);

            if (char == "<") {
                depth++;
                currentParam += char;
            } else if (char == ">") {
                depth--;
                currentParam += char;
            } else if (char == "," && depth == 0) {
                params.push(StringTools.trim(currentParam));
                currentParam = "";
            } else {
                currentParam += char;
            }
        }

        if (currentParam != "") {
            params.push(StringTools.trim(currentParam));
        }

        return params;
    }

    public function copyParamsFrom(other: AnalyserType): Void {
        _params = [];
        for (param in other._params) {
            _params.push(param.toMutableType());
        }
    }

    public function setType(type: AnalyserType): Void {
        if (!type.isUnknown()) setTypeStr(type._type);
        setCopiedFrom(type);
        copyParamsFrom(type);
    }

    public function setIfUnknown(type: AnalyserType): Void {
        if (_type == null) {
            setType(type);
        }
    }

    public function setCopiedFrom(type: AnalyserType): Void {
        _copiedFrom = type;
    }

    public function isUnknown(): Bool {
        return _type == null;
    }

    @:op(A == B)
    public function equals(other: AnalyserType): Bool {
        if (other == null) return false;

        var paramsMatch = true;
        for (i in 0..._params.length) {
            if (!_params[i].equals(other._params[i])) {
                paramsMatch = false;
                break;
            }
        }

        return _type == other?._type && paramsMatch;
    }

    public function getBaseTypeStr(): String {
        return _type;
    }

    public function getParams(): Array<AnalyserType> {
        return _params;
    }

    public function getParamCount(): Int {
        return _params.length;
    }

    public function getParam(index: Int): AnalyserType {
        return _params[index];
    }

    public function addParam(param: AnalyserType): Void {
        _params.push(param);
    }

    public function removeParam(index: Int): Void {
        _params.splice(index, 1);
    }

    public function clearParams(): Void {
        _params = [];
    }

    public function setParam(index: Int, param: AnalyserType): Void {
        _params[index] = param;
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

    public function isPointer(): Bool {
        return _type == "Pointer";
    }

    public function isVoidPointer(): Bool {
        return _type == "Pointer" && _params.length == 1 && _params[0].getBaseTypeStr() == "Void";
    }

    public function isComplexType(): Bool {
        return _params.length > 0;
    }

    public function isPrimitiveType(): Bool {
        return !isComplexType();
    }

    public function toDebugString(): String {
        return '${toString()} (#$_id)'; // + (if (_copiedFrom != null) ' copied from ${_copiedFrom.toDebugString()}' else '');
    }

    public function getId(): Int {
        return _id;
    }

    public function getCopiedFrom(): Null<AnalyserType> {
        return _copiedFrom;
    }

    @:to
    public function toString(): String {
        var baseType = _type;
        if (baseType == null) {
            baseType = "Unknown";
        }

        return baseType + (if (_params.length > 0) "<" + _params.map(function(p) return p.toString()).join(", ") + ">" else "");
    }

}