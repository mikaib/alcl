#ifndef ALCL_FUNC
#define ALCL_FUNC
#endif // ALCL_FUNC

#ifndef INCLUDE_d6563ee84dfb2373f031176fbe02d8c4
#define INCLUDE_d6563ee84dfb2373f031176fbe02d8c4
#include "stdio.h"
#endif // INCLUDE_d6563ee84dfb2373f031176fbe02d8c4

#ifndef INCLUDE_2710e462964f946c30376bac313b7c7b
#define INCLUDE_2710e462964f946c30376bac313b7c7b
#include "stdlib.h"
#endif // INCLUDE_2710e462964f946c30376bac313b7c7b

#ifndef ALCL_89a8978523a7eeb9fc75cd33c32358c2
#define ALCL_89a8978523a7eeb9fc75cd33c32358c2
#include "alcl/global.c"
#endif // ALCL_89a8978523a7eeb9fc75cd33c32358c2

ALCL_FUNC void alcl_test_float64(char* name, double a, double b) {
    double error = 0.0000000000001;
    if (a < b - error || a > b + error) {
        printf("FAIL: %s (%f != %f)\n", name, a, b);
    } else {
        printf("PASS: %s\n", name);
    }
}

