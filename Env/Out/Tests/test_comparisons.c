#include "alcl/compiler_testing.h"
#include "alcl/global.h"

void test_comparisons() {
    int x = 10;
    int y = 5;
    int result = 0;
    if (x > y) {
        result = 1;    
    }
    alcl_test_int("If Statement", result, 1);
    x = 3;
    y = 5;
    result = 0;
    if (x > y) {
        result = 1;    
    }
    else {
        result = -1;    
    }
    alcl_test_int("Else Statement", result, -1);
    x = 5;
    y = 5;
    result = 0;
    if (x > y) {
        result = 1;    
    }
    else if (x == y) {
        result = 2;    
    }
    else {
        result = -1;    
    }
    alcl_test_int("Elseif Statement", result, 2);
    x = 10;
    y = 5;
    int z = 15;
    result = 0;
    if (x > y) {
        if (z > x) {
            result = 3;    
        }
        else {
            result = 4;    
        }    
    }
    else {
        result = -1;    
    }
    alcl_test_int("Nested If-Else", result, 3);    
}

