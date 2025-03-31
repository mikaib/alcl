package analysis;
import ast.Node;
import errors.ErrorType;

// base constraint
@:structInit
class AnalyserConstraint {

    private final TInt32: AnalyserFixedType = AnalyserType.createFixedType("Int32");
    private final TInt64: AnalyserFixedType = AnalyserType.createFixedType("Int64");
    private final TFloat32: AnalyserFixedType = AnalyserType.createFixedType("Float32");
    private final TFloat64: AnalyserFixedType = AnalyserType.createFixedType("Float64");
    private final TCSizeT: AnalyserFixedType = AnalyserType.createFixedType("CSizeT");

    public var a: AnalyserType = null;
    public var b: AnalyserType = null;
    public var priority: AnalyserConstraintPriority = AnalyserConstraintPriority.INFERENCE;
    public var node: Node;
    public var optional: Bool = false;

    public function promoteNumbers(solver: AnalyserSolver): Void {
        if (a.isNumericalType() && b.isNumericalType()) {
            var promoted: AnalyserType = null;
            var promotionResults: Array<{ a: AnalyserType, b: AnalyserType, result: AnalyserType }> = [
                { a: TInt32, b: TInt64, result: TInt64 },
                { a: TInt32, b: TFloat32, result: TFloat32 },
                { a: TInt32, b: TFloat64, result: TFloat64 },
                { a: TInt64, b: TFloat32, result: TFloat64 },
                { a: TInt64, b: TFloat64, result: TFloat64 },
                { a: TFloat32, b: TFloat64, result: TFloat64 }
            ];

            for (i in 0...promotionResults.length) {
                var result = promotionResults[i];
                if (a.equals(result.a) && b.equals(result.b)) {
                    promoted = result.result;
                    break;
                }

                if (a.equals(result.b) && b.equals(result.a)) {
                    promoted = result.result;
                    break;
                }
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
            a.setHintStatus(optional || b.isHint());
            return true;
        }

        if (!a.isUnknown() && b.isUnknown()) {
            b.setType(a);
            b.setHintStatus(optional || a.isHint());
            return true;
        }

        if (!a.equals(b)) {
            if (a.isNumericalType() && b.isNumericalType()) {
                promoteNumbers(solver);
                return true;
            }

            if (a.isVoidPointer() && b.isPointer()) {
                a.setType(b);
                return true;
            }

            if (a.isPointer() && b.isVoidPointer()) {
                b.setType(a);
                return true;
            }

            if (a.isHint()) {
                a.setType(b);
                a.setHintStatus(optional || b.isHint());
                return true;
            }

            if (b.isHint()) {
                b.setType(a);
                b.setHintStatus(optional || a.isHint());
                return true;
            }

            return optional;
        }

        return true;
    }

    public function tryCast(solver: AnalyserSolver): Bool {
        if (solve(solver)) {
            return true;
        }

        var path = solver.analyser.findCastPath(node.analysisScope, b, a);
        if (path.length > 0) {
            // Sys.println('    - casting ${b.toString()} to ${a.toString()} because it didn\'t match the ${node.type}, using path ${path}');
            solver.analyser.castNode(node, path);
            return true;
        }

        return false;
    }

    public function fail(solver: AnalyserSolver): Void {
        solver.analyser.emitError(node, ErrorType.TypeMismatch, 'wanted ${a.toString()} but got ${b.toString()}');
    }

    public function toString(): String {
        return '${a.toString()} == ${b.toString()}' + (node != null ? ' at "${node.type} ${node.value}"' : '');
    }

}
