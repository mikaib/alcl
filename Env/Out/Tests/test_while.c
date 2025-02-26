#include "alcl/compiler_testing.h"
#include "io.h"
#include "alcl/global.h"

void test_while() {
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

