package analysis;
import ast.Node;

@:structInit
class AnalyserFunction {
    public var name: String;
    public var remapTo: Null<String> = null;
    public var type: AnalyserType;
    public var params: Array<AnalyserFunctionParam>;
    public var usages: Array<Node>;
    public var defined: Bool;
    public var origin: Node;
    public var fromMerger: Bool = false;
    public var isExtern: Bool = false;
    public var headers: Array<String> = [];

    public function copy(): AnalyserFunction {
        return {
            name: name,
            type: type.toMutableType(),
            params: params.map(function(p) return p.copy()),
            usages: usages,
            defined: defined,
            origin: origin,
            fromMerger: fromMerger,
            isExtern: isExtern,
            headers: headers,
            remapTo: remapTo
        };
    }
}
