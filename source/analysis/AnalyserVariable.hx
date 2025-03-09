package analysis;
import ast.Node;

@:structInit
class AnalyserVariable {
    public var name: String;
    public var type: AnalyserType;
    public var origin: Node;
    public var isInitialized: Bool;
}
