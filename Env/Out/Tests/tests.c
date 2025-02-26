#include "test_math.h"
#include "test_while.h"
#include "test_comparisons.h"
#include "alcl/global.h"

int main() {
    test_math();
    test_while();
    test_comparisons();
    return alcl_test_summary();    
}

