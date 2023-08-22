#include "kernel/types.h"
#include "user.h"

typedef
struct ustack {
    uint len;
    uint pa;
    struct ustack* prev;
}ustack;


void*
ustack_malloc(uint len); 

int ustack_free(void);