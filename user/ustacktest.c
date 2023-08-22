#include "ustack.h"

int MAX_STACKS = 4096; 

void test_case_1() {
    void* ptr1 = ustack_malloc(10);
    if (ptr1 != (void*)-1) {
        printf("Allocation 1 successful.\n");

        void* ptr2 = ustack_malloc(20);
        if (ptr2 != (void*)-1) {
            printf("Allocation 2 successful.\n");

            // Deallocate both allocations
            int deallocate1 = ustack_free();
            int deallocate2 = ustack_free();

            if (deallocate1 == 0 && deallocate2 == 0) {
                printf("Deallocation successful.\n");
            } else {
                printf("Deallocation failed.\n");
            }
        } else {
            printf("Allocation 2 failed.\n");
        }
    } else {
        printf("Allocation 1 failed.\n");
    }
}

void test_case_2() {
    // Fill up all available stacks
    for (int i = 0; i < MAX_STACKS; i++) {
        void* ptr = ustack_malloc(10);
        if (ptr == (void*)-1) {
            printf("Allocation %d failed (stacks full).\n", i + 1);
            break;
        }
    }
}


void test_case_3() {
    // Allocate a large block of memory that exceeds the available memory
    void* ptr = ustack_malloc(1024 * 1024 * 1024); // 1GB
    if (ptr == (void*)-1) {
        printf("Allocation failed (out of memory).\n");
    }
}

void test_case_4() {
    int deallocate = ustack_free();
    if (deallocate == -1) {
        printf("Deallocation failed (no allocations).\n");
    }
}


int main(int argc, char *argv[])
{
    test_case_1(); 
    test_case_2();
    test_case_3();
    test_case_4();
    return 0; 
}