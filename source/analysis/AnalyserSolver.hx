package analysis;
import errors.ErrorType;

class AnalyserSolver {

    private var _constraints: Array<AnalyserConstraint>;
    public var analyser: Analyser;

    public function new(analyser: Analyser) {
        _constraints = [];
        this.analyser = analyser;
    }

    public function addConstraint(constraint: AnalyserConstraint): Void {
        _constraints.push(constraint);
    }

    public function solve(): Bool {
        var changed: Bool = true;
        var constraints: Array<AnalyserConstraint> = _constraints.copy();
        var toRemove: Array<AnalyserConstraint> = [];

        while (changed) {
            trace('SOLVE:');
            changed = false;
            constraints.sort((a, b) -> {
                return b.priority - a.priority;
            });

            for (constraint in constraints) {
                trace('    ' + constraint.toString());

                if (constraint.solve(this)) {
                    toRemove.push(constraint);
                }
            }

            for (constraint in toRemove) {
                constraints.remove(constraint);
                changed = true;
            }

            toRemove.resize(0);
        }

        for (constraint in constraints) {
            constraint.fail(this);
        }

        return constraints.length <= 0;
    }

}
