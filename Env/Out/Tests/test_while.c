#ifndef ALCL_FUNC
#define ALCL_FUNC
#endif // ALCL_FUNC

#ifndef ALCL_7c54b339146e6cf4f6af45d2260cf978
#define ALCL_7c54b339146e6cf4f6af45d2260cf978
#include "alcl/compiler_testing.c"
#endif // ALCL_7c54b339146e6cf4f6af45d2260cf978

#ifndef ALCL_f4243e45d1ba1738c3e3067bc996cb3a
#define ALCL_f4243e45d1ba1738c3e3067bc996cb3a
#include "io.c"
#endif // ALCL_f4243e45d1ba1738c3e3067bc996cb3a

#ifndef ALCL_89a8978523a7eeb9fc75cd33c32358c2
#define ALCL_89a8978523a7eeb9fc75cd33c32358c2
#include "alcl/global.c"
#endif // ALCL_89a8978523a7eeb9fc75cd33c32358c2

ALCL_FUNC void test_while() {
    int i = 0;
    while (i < 5) {
        i = i + 1;    
    }
    alcl_test_int("Basic While Loop", i, 5);
    int a = 0;
    int b = 10;
    while (a < 5 && b > 5) {
        a = a + 1;
        b = b - 1;    
    }
    alcl_test_int("While Loop Complex Condition - a", a, 5);
    alcl_test_int("While Loop Complex Condition - b", b, 5);
    int sum = 0;
    int count = 0;
    while (count < 10) {
        if (count == 4) {
            break;    
        }
        sum = sum + count;
        count = count + 1;    
    }
    alcl_test_int("While Loop Break", sum, 6);
    int evenSum = 0;
    int n = 0;
    while (n < 6) {
        n = n + 1;
        if (n % 2 != 0) {
            continue;    
        }
        evenSum = evenSum + n;    
    }
    alcl_test_int("While Loop Continue - Even Sum", evenSum, 12);    
}

