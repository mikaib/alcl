package analysis;

import errors.ErrorType;

// this constraint doesnt infer types but does check if the type is one of the allowed types
@:structInit
class AnalyserConstraintEither extends AnalyserConstraint {

    public var allowedTypes: Array<AnalyserType>;
    public var type: AnalyserType;

    override public function solve(solver: AnalyserSolver): Bool {
        if (type.isUnknown()) {
            return false;
        }

        for (allowed in allowedTypes) {
            if (type.equals(allowed)) {
                return true;
            }
        }

        return optional;
    }

    override public function tryCast(solver: AnalyserSolver): Bool {
        if (solve(solver)) {
            return true;
        }

        for (allowed in allowedTypes) {
            var path = solver.analyser.findCastPath(node.analysisScope, type, allowed);
            if (path.length > 0) {
                // Sys.println('    - casting ${type.toString()} to ${allowed.toString()} because it doesnt match any of the allowed types [${allowedTypes.map(t -> t.toString()).join(", ")}]');
                solver.analyser.castNode(node, path);
                return true;
            }
        }

        return false;
    }

    override public function fail(solver: AnalyserSolver): Void {
        solver.analyser.emitError(node, ErrorType.TypeMismatch, 'Expected one of [${allowedTypes.map(t -> t.toString()).join(", ")}] but got ${type.toString()}');
    }

    override public function toString(): String {
        return '${type.toString()} == EitherOf[${allowedTypes.map(t -> t.toString()).join(", ")}]';
    }

}
