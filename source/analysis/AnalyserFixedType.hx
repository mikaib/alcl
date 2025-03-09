package analysis;

// A fixed type can NEVER be mutated, useful for constants.
class AnalyserFixedType extends AnalyserType {
    override public function setTypeStr(type: String): Void {}
}
