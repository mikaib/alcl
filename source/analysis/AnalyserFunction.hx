package analysis;
import ast.Node;

@:structInit
class AnalyserFunction {
    public var name: String;
    public var type: AnalyserType;
    public var params: Array<AnalyserFunctionParam>;
    public var usages: Array<Node>;
    public var defined: Bool;
    public var origin: Node;
}
