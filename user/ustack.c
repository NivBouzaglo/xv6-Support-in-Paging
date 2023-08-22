#include "ustack.h"
#include "user.h"
#include "kernel/riscv.h"
#include "kernel/types.h"

struct ustack *head = 0;

void* ustack_malloc(uint len){

    if(len > 512) //valid
        return (void*)-1;
    uint64 address;
    if(head == 0){
        address = (uint64)sbrk(4096);
        if(address == -1)//valid
            return (void*)-1; 
        head = (struct ustack*) address;
        head->len = len;
        head->pa = 4096 - sizeof(struct ustack) - len;
        head->prev = 0;
    }else {
        struct ustack next;

        if(len + sizeof(struct ustack) > head->pa){
            address = (uint64)sbrk(4096);

            if(address == -1)//valid
                return (void*)-1;
            next.len = len;
            next.pa = 4096-sizeof(struct ustack) - (len - head->pa);
            next.prev = head;

            head = (struct ustack*)((uint64)head + sizeof(struct ustack) + head->len );
            head->pa = next.pa;
            head->prev = next.prev;
            head->len = len;
        }
        else{

            next.len = len;
            next.pa = head->pa - len - sizeof(struct ustack);
            next.prev = head;
            head = (struct ustack*)(head->len + sizeof(struct ustack)+(uint64)head);
            head->pa = next.pa;
            head->len = len;
            head->prev = next.prev;
        }
    }
    return (void*)head + sizeof(struct ustack);
}

int ustack_free(void){
    struct ustack* newHead;
    if(head == 0){
        return -1;
    }
    uint len = head->len;
    newHead = head->prev;
    if(head->prev == 0)
        sbrk(-4096);

    else if(PGROUNDDOWN((uint64)head) == (uint64)head)
        sbrk(-4096);

    else if(PGROUNDUP((uint64)head) < (uint64)head + sizeof(struct ustack) + head->len)
        sbrk(-PGSIZE);

    head = newHead;
    return len;    
}