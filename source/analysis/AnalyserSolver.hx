package analysis;
import errors.ErrorType;

class AnalyserSolver {

    private var _constraints: Array<AnalyserConstraint>;
    private var _analyser: Analyser;

    public function new(analyser: Analyser) {
        _constraints = [];
        _analyser = analyser;
    }

    public function addConstraint(constraint: AnalyserConstraint): Void {
        _constraints.push(constraint);
    }

    public function solve(): Bool {
        var changed: Bool = true;
        var constraints: Array<AnalyserConstraint> = _constraints.copy();
        var toRemove: Array<AnalyserConstraint> = [];

        while (changed) {
            trace('-------');
            changed = false;
            constraints.sort((a, b) -> {
                return b.priority - a.priority;
            });

            for (constraint in constraints) {
                trace(constraint.a, constraint.b, constraints.indexOf(constraint), constraints.length);

                if (constraint.a.isUnknown() && constraint.b.isUnknown()) {
                    continue;
                } else if (constraint.a.isUnknown() && !constraint.b.isUnknown()) {
                    constraint.a.setType(constraint.b);
                } else if (!constraint.a.isUnknown() && constraint.b.isUnknown()) {
                    constraint.b.setType(constraint.a);
                } else {
                   _analyser.emitError(constraint.node, ErrorType.TypeMismatch, '${constraint.a} and ${constraint.b} are incompatible!');
                    continue;
                }

                toRemove.push(constraint);
            }

            for (constraint in toRemove) {
                constraints.remove(constraint);
                changed = true;
            }

            toRemove.resize(0);
        }

        return constraints.length <= 0;
    }

}
