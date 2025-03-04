package analysis;

// A fixed type can NEVER be mutated, useful for constants.
class AnalyserFixedType extends AnalyserType {
    override public function hintIfUnknown(typeName: String): Void {}
    override public function setType(typeName: String): Void {}
}
