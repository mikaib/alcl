#include "stdio.h"
#include "stdlib.h"
#include "stdbool.h"
#include "./global.h"

int totalTests = 0;
int passingTests = 0;
int failingTests = 0;
void alcl_test_float(char* name, double a, double b) {
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

void alcl_test_int(char* name, long long a, long long b) {
    totalTests = totalTests + 1;
    if (a != b) {
        failingTests = failingTests + 1;
        printf("FAIL: %s (%llu != %llu)\n", name, a, b);
    } else {
        passingTests = passingTests + 1;
        printf("PASS: %s\n", name);
    }
}

void alcl_test_bool(char* name, unsigned char v) {
    totalTests = totalTests + 1;
    if (v == false) {
        failingTests = failingTests + 1;
        printf("FAIL: %s\n", name);
    } else {
        passingTests = passingTests + 1;
        printf("PASS: %s\n", name);
    }
}

int alcl_test_summary() {
    printf("\n");
    printf("Total tests: %d\n", totalTests);
    printf("Passing tests: %d\n", passingTests);
    printf("Failing tests: %d\n", failingTests);

    return failingTests != 0;
}

