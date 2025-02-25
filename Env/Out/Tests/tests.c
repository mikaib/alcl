#ifndef ALCL_FUNC
#define ALCL_FUNC
#endif // ALCL_FUNC

#ifndef ALCL_9a528d63d0f70fda3c408ac31acf5ad9
#define ALCL_9a528d63d0f70fda3c408ac31acf5ad9
#include "test_math.c"
#endif // ALCL_9a528d63d0f70fda3c408ac31acf5ad9

#ifndef ALCL_d03f7d7ad27bf6b5078684f540d284f3
#define ALCL_d03f7d7ad27bf6b5078684f540d284f3
#include "test_while.c"
#endif // ALCL_d03f7d7ad27bf6b5078684f540d284f3

#ifndef ALCL_c35dc6e77baa10a5f6c460d0c0db2aa9
#define ALCL_c35dc6e77baa10a5f6c460d0c0db2aa9
#include "test_comparisons.c"
#endif // ALCL_c35dc6e77baa10a5f6c460d0c0db2aa9

#ifndef ALCL_89a8978523a7eeb9fc75cd33c32358c2
#define ALCL_89a8978523a7eeb9fc75cd33c32358c2
#include "alcl/global.c"
#endif // ALCL_89a8978523a7eeb9fc75cd33c32358c2

int main() {
    test_math();
    test_while();
    test_comparisons();
    return alcl_test_summary();    
}

