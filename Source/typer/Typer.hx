package typer;

class Typer {

    // Alcl Types -> C Types (direct map, simple types)
    private var _types: Map<String, String> = [];

    public function addAlclToCTypeMapping(alclType: String, cType: String): Void {
        _types.set(alclType, cType);
    }

    public function convertTypeAlclToC(type: String): String {
        return _types.get(type);
    }

    public function copyFrom(src: Typer): Void {
        for (key in src._types.keys()) {
            _types.set(key, src._types.get(key));
        }
    }

    public function new() {
    }
}
