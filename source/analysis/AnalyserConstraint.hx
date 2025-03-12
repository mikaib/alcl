package analysis;
import ast.Node;

@:structInit
class AnalyserConstraint {
    public var a: AnalyserType;
    public var b: AnalyserType;
    public var priority: AnalyserConstraintPriority;
    public var node: Node;
}
