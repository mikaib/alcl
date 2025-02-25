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

#ifndef ALCL_ad14e1535988300604fc36d053eec0fd
#define ALCL_ad14e1535988300604fc36d053eec0fd
#include "alcl/global.c"
#endif // ALCL_ad14e1535988300604fc36d053eec0fd

ALCL_FUNC void alcl_test_float(char* name, double a, double b) {
    double error = 0.0000000000001;
    if (a < b - error || a > b + error) {
        printf("FAIL: %s (%f != %f)\n", name, a, b);
    } else {
        printf("PASS: %s\n", name);
    }
}

ALCL_FUNC void alcl_test_int(char* name, long long a, long long b) {
    if (a != b) {
        printf("FAIL: %s (%f != %f)\n", name, a, b);
    } else {
        printf("PASS: %s\n", name);
    }
}

ALCL_FUNC void alcl_test_bool(char* name, bool v) {
    if (v == false) {
        printf("FAIL: %s\n", name, a, b);
    } else {
        printf("PASS: %s\n", name);
    }
}

