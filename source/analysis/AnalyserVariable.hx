package analysis;
import ast.Node;

@:structInit
class AnalyserVariable {
    public var name: String;
    public var type: AnalyserType;
    public var origin: Node;
    public var isInitialized: Bool;
    public var fromMerger: Bool = false;

    public function copy(): AnalyserVariable {
        return {
            name: name,
            type: type.toMutableType(),
            origin: origin,
            isInitialized: isInitialized,
            fromMerger: fromMerger
        };
    }

}
