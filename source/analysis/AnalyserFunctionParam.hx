package analysis;
import ast.Node;

@:structInit
class AnalyserFunctionParam {
    public var name: String;
    public var type: AnalyserType;
    public var origin: Node;
}
