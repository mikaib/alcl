package analysis;
import ast.Node;

@:structInit
class AnalyserFunction {
    public var name: String;
    public var type: AnalyserType;
    public var params: Array<AnalyserFunctionParam>;
    public var origin: Node;
}
