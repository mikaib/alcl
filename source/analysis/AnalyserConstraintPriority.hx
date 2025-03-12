package analysis;

enum abstract AnalyserConstraintPriority(Int) from Int to Int {
    public var HINT = -1;
    public var INFERENCE = 0;
    public var CONSTANT = 1;
    public var USER = 2;
}
