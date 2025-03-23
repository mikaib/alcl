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

    public function solveWith(constraints: Array<AnalyserConstraint>): Void {
        var changed: Bool = true;
        var showHints: Bool = false;
        var toRemove: Array<AnalyserConstraint> = [];

        while (changed) {
            changed = false;
            constraints.sort((a, b) -> {
                return b.priority - a.priority;
            });

            for (constraint in constraints) {
                if (constraint.optional && !showHints) continue;
                if (constraint.solve(this)) {
                    toRemove.push(constraint);
                }
            }

            for (constraint in toRemove) {
                constraints.remove(constraint);
                changed = true;
            }

            toRemove.resize(0);

            if (!changed && !showHints) {
                showHints = true;
                changed = true;
            }
        }

        var _toRemove: Array<AnalyserConstraint> = [];
        for (constraint in constraints) {
            var solved: Bool = constraint.tryCast(this);
            if (solved) {
                _toRemove.push(constraint);
            }
        }

        for (constraint in _toRemove) {
            constraints.remove(constraint);
        }

        if (_toRemove.length > 0) {
            solveWith(constraints);
        }
    }

    public function solve(): Bool {
        var constraints: Array<AnalyserConstraint> = _constraints.copy();

        solveWith(constraints);
        if (constraints.length <= 0) {
            return true;
        }

        // Failure!
        for (constraint in constraints) {
            constraint.fail(this);
        }

        return false;
    }

}
