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

ALCL_FUNC void arithmetic() {
    alcl_test_float("Arithmetic Addition", 5 + 3, 8);
    alcl_test_float("Arithmetic Subtraction", 10 - 3, 7);
    alcl_test_float("Arithmetic Multiplication", 4 * 2, 8);
    alcl_test_float("Arithmetic Division", 12 / 3, 4);
    alcl_test_float("Arithmetic Subtraction Double", 10 -  - 3, 13);    
}

ALCL_FUNC void negative() {
    alcl_test_float("Negative Addition", -5 + 3, -2);
    alcl_test_float("Negative Subtraction", 5 + (-3), 2);
    alcl_test_float("Negative Multiplication", -10 * 2, -20);
    alcl_test_float("Negative Division", 10 /  - 2, -5);    
}

ALCL_FUNC void large() {
    alcl_test_float("Large Addition", 1000000 + 500000, 1500000);
    alcl_test_float("Large Subtraction", 1000000000 - 999999999, 1);
    alcl_test_float("Large Multiplication", 100000 * 1000, 100000000);
    alcl_test_float("Large Division", 1000000000 / 5000, 200000);    
}

ALCL_FUNC void division_by_zero() {
    
}

ALCL_FUNC void floating_point() {
    alcl_test_float("Floating Point Addition", 10.5 + 3.5, 14);
    alcl_test_float("Floating Point Subtraction", 10.5 - 3.5, 7);
    alcl_test_float("Floating Point Multiplication", 10.5 * 3.5, 36.75);
    alcl_test_float("Floating Point Division", 10.5 / 3.5, 3);    
}

ALCL_FUNC void mixed() {
    alcl_test_float("Mixed 1", 2 + 3 * 4, 14);
    alcl_test_float("Mixed 2", 6 - 4 / 2, 4);
    alcl_test_float("Mixed 3", 5 + 2 - 3 * 4, -5);    
}

ALCL_FUNC void order_of_operations() {
    alcl_test_float("Order of Operations 1", 5 + 3 * 2, 11);
    alcl_test_float("Order of Operations 2", 5 * 3 + 2, 17);    
}

ALCL_FUNC void parentheses() {
    alcl_test_float("Parentheses 1", (5 + 3) * 2, 16);
    alcl_test_float("Parentheses 2", 5 * (3 + 2), 25);
    alcl_test_float("Parentheses 3", 5 + (2 - 3) * 4, 1);
    alcl_test_float("Parentheses 4", 5 + 2 - 3 * 4, -5);
    alcl_test_float("Parentheses 5", 5 + 2 - (3 * 4), -5);    
}

ALCL_FUNC void binop_vs_unaryop() {
    alcl_test_float("Binop vs Unaryop 1", 5 +  - 3, 2);
    alcl_test_float("Binop vs Unaryop 2", 5 -  - 3, 8);
    alcl_test_float("Binop vs Unaryop 3", 5 *  - 3, -15);
    alcl_test_float("Binop vs Unaryop 4", 5.0 /  - 3.0, -1.6666666666666667);    
}

ALCL_FUNC void modulus() {
    alcl_test_float("Modulus 1", 10 % 3, 1);
    alcl_test_float("Modulus 2", 25 % 4, 1);    
}

ALCL_FUNC void mixed_division_modulus() {
    alcl_test_float("Mixed Division and Modulus 1", 10 / 3 * 3 + 10 % 3, 10);    
}

ALCL_FUNC void other() {
    alcl_test_float("Other 1", 10 + 5 * 2 - 20 / 4 + 3 * 6 - 8, 25);
    alcl_test_float("Other 2", (1.0 / ((10.0) * 10.0)), 0.01);    
}

ALCL_FUNC void test_math() {
    arithmetic();
    negative();
    large();
    division_by_zero();
    floating_point();
    mixed();
    order_of_operations();
    parentheses();
    modulus();
    mixed_division_modulus();
    binop_vs_unaryop();
    other();    
}

