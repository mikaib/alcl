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
    public var fromMerger: Bool = false;

    public function copy(): AnalyserFunction {
        return {
            name: name,
            type: type.toMutableType(),
            params: params.map(function(p) return p.copy()),
            usages: usages,
            defined: defined,
            origin: origin,
            fromMerger: fromMerger
        };
    }
}
