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

#ifndef INCLUDE_a7427bee4ed05162db8b3d016eee135f
#define INCLUDE_a7427bee4ed05162db8b3d016eee135f
#include "stdbool.h"
#endif // INCLUDE_a7427bee4ed05162db8b3d016eee135f

#ifndef ALCL_89a8978523a7eeb9fc75cd33c32358c2
#define ALCL_89a8978523a7eeb9fc75cd33c32358c2
#include "./global.c"
#endif // ALCL_89a8978523a7eeb9fc75cd33c32358c2

int totalTests = 0;
int passingTests = 0;
int failingTests = 0;
ALCL_FUNC void alcl_test_float(char* name, double a, double b) {
    double error = 0.0000000000001;
    totalTests = totalTests + 1;
    if (a < b - error || a > b + error) {
        failingTests = failingTests + 1;
        printf("FAIL: %s (%f != %f)\n", name, a, b);
    } else {
        passingTests = passingTests + 1;
        printf("PASS: %s\n", name);
    }
}

ALCL_FUNC void alcl_test_int(char* name, long long a, long long b) {
    totalTests = totalTests + 1;
    if (a != b) {
        failingTests = failingTests + 1;
        printf("FAIL: %s (%f != %f)\n", name, a, b);
    } else {
        passingTests = passingTests + 1;
        printf("PASS: %s\n", name);
    }
}

ALCL_FUNC void alcl_test_bool(char* name, unsigned char v) {
    totalTests = totalTests + 1;
    if (v == false) {
        failingTests = failingTests + 1;
        printf("FAIL: %s\n", name);
    } else {
        passingTests = passingTests + 1;
        printf("PASS: %s\n", name);
    }
}

ALCL_FUNC int alcl_test_summary() {
    printf("\n");
    printf("Total tests: %d\n", totalTests);
    printf("Passing tests: %d\n", passingTests);
    printf("Failing tests: %d\n", failingTests);

    return failingTests != 0;
}

