package analysis;
import ast.Node;
import errors.ErrorType;

// base constraint
@:structInit
class AnalyserConstraint {

    private var TInt32: AnalyserFixedType = AnalyserType.createFixedType("Int32");
    private var TInt64: AnalyserFixedType = AnalyserType.createFixedType("Int64");
    private var TFloat32: AnalyserFixedType = AnalyserType.createFixedType("Float32");
    private var TFloat64: AnalyserFixedType = AnalyserType.createFixedType("Float64");

    public var a: AnalyserType = null;
    public var b: AnalyserType = null;
    public var priority: AnalyserConstraintPriority = AnalyserConstraintPriority.INFERENCE;
    public var node: Node;
    public var optional: Bool = false;

    public function promoteNumbers(solver: AnalyserSolver): Void {
        if (a.isNumericalType() && b.isNumericalType()) {
            var promoted: AnalyserType;
            if (a.equals(TFloat64) || b.equals(TFloat64)) {
                promoted = TFloat64;
            } else if ((a.equals(TFloat32) && b.equals(TInt64)) || (a.equals(TInt64) && b.equals(TFloat32))) {
                promoted = TFloat64;
            } else if (a.equals(TInt64) || b.equals(TInt64)) {
                promoted = TInt64;
            } else if (a.equals(TFloat32) || b.equals(TFloat32)) {
                promoted = TFloat32;
            } else {
                promoted = TInt32;
            }

            a.setType(promoted);
            b.setType(promoted);
        }
    }

    public function solve(solver: AnalyserSolver): Bool {
        if (a.isUnknown() && b.isUnknown()) {
            return false;
        }

        if (a.isUnknown() && !b.isUnknown()) {
            a.setType(b);
            a.setHintStatus(optional);
            return true;
        }

        if (!a.isUnknown() && b.isUnknown()) {
            b.setType(a);
            b.setHintStatus(optional);
            return true;
        }

        if (!a.equals(b)) {
            if (a.isNumericalType() && b.isNumericalType()) {
                promoteNumbers(solver); // TODO: needs fixing up, may change user defined types... not supposed to happen!!
                return true;
            }

            if (a.isHint()) {
                a.setType(b);
                return true;
            }

            if (b.isHint()) {
                b.setType(a);
                return true;
            }

            return optional;
        }

        return true;
    }

    public function fail(solver: AnalyserSolver): Void {
        solver.analyser.emitError(node, ErrorType.TypeMismatch, 'wanted ${a.toString()} but got ${b.toString()}');
    }

    public function toString(): String {
        return '${a.toString()} == ${b.toString()}';
    }

}
