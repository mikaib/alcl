#ifndef ALCL_FUNC
#define ALCL_FUNC
#endif // ALCL_FUNC

#ifndef ALCL_e48ca9b59ccefab66abcad3c3019185e
#define ALCL_e48ca9b59ccefab66abcad3c3019185e
#include "alcl/compiler_testing.c"
#endif // ALCL_e48ca9b59ccefab66abcad3c3019185e

#ifndef ALCL_ddcd579ef34fccd633d605019cbc84e0
#define ALCL_ddcd579ef34fccd633d605019cbc84e0
#include "io.c"
#endif // ALCL_ddcd579ef34fccd633d605019cbc84e0

#ifndef ALCL_ad14e1535988300604fc36d053eec0fd
#define ALCL_ad14e1535988300604fc36d053eec0fd
#include "alcl/global.c"
#endif // ALCL_ad14e1535988300604fc36d053eec0fd

void main() {
    int i = 0;
    while (i<10) {
        println("ello");
        i = i + 1;    
    }
    alcl_test_int("While Loop", i, 10);    
}

