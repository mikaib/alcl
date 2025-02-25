#ifndef ALCL_FUNC
#define ALCL_FUNC
#endif // ALCL_FUNC

#ifndef ALCL_7c54b339146e6cf4f6af45d2260cf978
#define ALCL_7c54b339146e6cf4f6af45d2260cf978
#include "alcl/compiler_testing.c"
#endif // ALCL_7c54b339146e6cf4f6af45d2260cf978

#ifndef ALCL_89a8978523a7eeb9fc75cd33c32358c2
#define ALCL_89a8978523a7eeb9fc75cd33c32358c2
#include "alcl/global.c"
#endif // ALCL_89a8978523a7eeb9fc75cd33c32358c2

ALCL_FUNC void test_comparisons() {
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

