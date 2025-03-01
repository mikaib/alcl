package analysis;
import ast.Node;

@:structInit
class AnalyserVariable {
    public var name: String;
    public var type: String;
    public var origin: Node;
}
