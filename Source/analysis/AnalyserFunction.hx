package analysis;
import ast.Node;

@:structInit
class AnalyserFunction {
    public var name: String;
    public var type: String;
    public var params: Array<AnalyserFunctionParam>;
    public var origin: Node;
}
