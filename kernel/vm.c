#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "spinlock.h"
#include "proc.h"

/*
 * the kernel's page table.
 */
pagetable_t kernel_pagetable;

extern char etext[];  // kernel.ld sets this to end of kernel code.

extern char trampoline[]; // trampoline.S

// Make a direct-map page table for the kernel.
pagetable_t
kvmmake(void)
{
  pagetable_t kpgtbl;

  kpgtbl = (pagetable_t) kalloc();
  memset(kpgtbl, 0, PGSIZE);

  // uart registers
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // virtio mmio disk interface
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // PLIC
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // map kernel text executable and read-only.
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

  // map kernel data and the physical RAM we'll make use of.
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);

  // map kernel stacks
  proc_mapstacks(kpgtbl);
  
  return kpgtbl;
}

// Initialize the one kernel_pagetable
void
kvminit(void)
{
  kernel_pagetable = kvmmake();
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));

  // flush stale entries from the TLB.
  sfence_vma();
}

// Return the address of the PTE in page table pagetable
// that corresponds to virtual address va.  If alloc!=0,
// create any required page-table pages.
//
// The risc-v Sv39 scheme has three levels of page-table
// pages. A page-table page contains 512 64-bit PTEs.
// A 64-bit virtual address is split into five fields:
//   39..63 -- must be zero.
//   30..38 -- 9 bits of level-2 index.
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
  if(va >= MAXVA)
    panic("walk");

  for(int level = 2; level > 0; level--) {
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  return &pagetable[PX(0, va)];
}

// Look up a virtual address, return the physical address,
// or 0 if not mapped.
// Can only be used to look up user pages.
uint64
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    return 0;

  pte = walk(pagetable, va, 0);
  if(pte == 0)
    return 0;
  if((*pte & PTE_V) == 0)
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}

// add a mapping to the kernel page table.
// only used when booting.
// does not flush TLB or enable paging.
void
kvmmap(pagetable_t kpgtbl, uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    panic("kvmmap");
}

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    panic("mappages: size");

  a = PGROUNDDOWN(va);
  last = PGROUNDDOWN(va + size - 1);
  for(;;){
    if((pte = walk(pagetable, a, 1)) == 0)
      return -1;
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if(((*pte & PTE_V) == 0) && ((*pte & PTE_PG) == 0))
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
      panic("uvmunmap: not a leaf");
    if((*pte & PTE_V) && do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    #if SWAP_ALGO != NONE
    struct proc *p = myproc();
    struct page_data *pg;
    //unmap adress a: if it is in memory delete it from memory 
    if(p->pid > 2){
      if(pagetable == p->pagetable && (*pte & PTE_V) && do_free){
        for(pg = p->memory_pages; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
          if(pg->va == a){
            pg->used = 0;
            pg->va = 0;
            pg->age = 0;
            p->memory_pages_count--;
            break;
          }
        }
      }
    }
    //else delete it from swapfile
    if(p->pid > 2){
        if(pagetable == p->pagetable && (*pte & PTE_PG)){
        for(pg = p->swapped_pages; pg < &p->swapped_pages[MAX_PSYC_PAGES]; pg++){
          if(pg->va == a){
            pg->used = 0;
            pg->va = 0;
            pg->age = 0;
            p->swapped_pages_count--;
            break;
          }
        }
      }
    } 
    #endif
    *pte = 0;
  }
}

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
  if(pagetable == 0)
    return 0;
  memset(pagetable, 0, PGSIZE);
  return pagetable;
}

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
  char *mem;

  if(sz >= PGSIZE)
    panic("uvmfirst: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
  memmove(mem, src, sz);
}

// Allocate PTEs and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
uint64
uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz, int xperm)
{
  char *mem;
  uint64 a;

  if(newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for(a = oldsz; a < newsz; a += PGSIZE){
    mem = kalloc();
    if(mem == 0){
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
      kfree(mem);
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    #if SWAP_ALGO != NONE
    struct proc *p = myproc(); 
    if (p->pid > 2)
    {
      update_proc_memory(a, pagetable); 
    }
    #endif
  }
  return newsz;
}


// Deallocate user pages to bring the process size from oldsz to
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if(newsz >= oldsz)
    return oldsz;

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
      freewalk((pagetable_t)child);
      pagetable[i] = 0;
    } else if(pte & PTE_V){
      panic("freewalk: leaf");
    }
  }
  kfree((void*)pagetable);
}

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
  if(sz > 0)
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
}

// Given a parent process's page table, copy
// its memory into a child's page table.
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0)
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
      kfree(mem);
      goto err;
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}


// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
  if(pte == 0)
    panic("uvmclear");
  *pte &= ~PTE_U;
}

// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(dstva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);

    len -= n;
    src += n;
    dstva = va0 + PGSIZE;
  }
  return 0;
}

// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);

    len -= n;
    dst += n;
    srcva = va0 + PGSIZE;
  }
  return 0;
}

// Copy a null-terminated string from user to kernel.
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
        got_null = 1;
        break;
      } else {
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    return 0;
  } else {
    return -1;
  }
}

int find_index_in_memory(){
  struct proc *p = myproc();
  struct page_data *pg;
  for(pg = p->memory_pages; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
    if(!pg->used){
      return (int)(pg - p->memory_pages);
    }
  }
  return -1;
}


// get page that will be swaped out (Task 2)
// Returns page index in memory_pages array, this page will be swapped out
int get_page_by_alg(){
  #if SWAP_ALGO == SCFIFO
  return scfifo_algo();
  #endif
  #if SWAP_ALGO == NFUA
  return nfua_algo();
  #endif
  #if SWAP_ALGO == LAPA
  return lapa_algo();
  #endif
  #if SWAP_ALGO == NONE
  return 1; //will never got here
  #endif
  return 1;
}


//Chose page to remove from main memory (using one of task2 algorithms) 
//and swap this page into file
void swap_files(pagetable_t pagetable){

  struct proc *p = myproc();
  if(p->memory_pages_count + p->swapped_pages_count > MAX_TOTAL_PAGES){
    panic("more than 32 pages per proccess");
  }
  int page_index_to_swap = get_page_by_alg(); //Index1

  struct page_data *pg_to_swap = &p->memory_pages[page_index_to_swap];

  //find free space in swaped pages array,
  //add selected to swap out page to this array 
  //and write this page to swapfile.
  struct page_data *pg;
  for(pg = p->swapped_pages; pg < &p->swapped_pages[MAX_PSYC_PAGES]; pg++){
    if(!pg->used){
      pg->used = 1;
      pg->va = pg_to_swap->va;
      pte_t* pte = walk(pagetable, pg->va, 0); //p->pagetable? or pagetable? 
      uint64 pa = PTE2PA(*pte);
      int offset = (pg - p->swapped_pages)*PGSIZE;

      writeToSwapFile(p, (char*)pa, offset, PGSIZE); 

      p->swapped_pages_count++;

      kfree((void*)pa); 

      *pte |= PTE_PG;     //paged out to secondary storage
      *pte &= ~PTE_V;     //Whenever a page is moved to the paging file,
                          // it should be marked in the process' page table entry that the page is not present.
                          //This is done by clearing the valid (PTE_V) flag. 

      pg_to_swap->used = 0;
      pg_to_swap->va = 0;
      p->memory_pages_count--;
      sfence_vma(); 
      break;
    }
  }

}
//Adding new page created by uvmalloc() to proccess pages
void update_proc_memory(uint64 a, pagetable_t pagetable){
  struct proc *p = myproc();
  //No free space in the psyc memory,
  //Chose page to remove from main memory (using one of task2 algorithms) 
  //and swap this page into file
  if(p->memory_pages_count == MAX_PSYC_PAGES){
    swap_files(pagetable);
  }

  //Now we have free space in psyc memory (maybe we had free space before too):
  //just add all page information to memory_pages array:
  int index_memory = find_index_in_memory();
  struct page_data *pg = &p->memory_pages[index_memory];

  pg->used = 1;
  pg->va = a;

  #if SWAP_ALGO == NFUA
    printf("NFUA\n");

  pg->age = 0;
  #endif

  #if SWAP_ALGO == LAPA
  pg->age = (uint64)~0;
  printf("LAPA\n");
  #endif
  
  #if SWAP_ALGO == SCFIFO
  pg->time=++p->page_timer;
  printf("SCFIFO\n");
  #endif

  p->memory_pages_count++;

  pte_t* pte = walk(pagetable, pg->va, 0);
  //set pte flags:
  *pte &= ~PTE_PG;     //paged in to memory - turn off bit 
  *pte |= PTE_V;
}

//task 2 handle page fault
int page_fault_handler(){
  struct proc *p = myproc();
  uint64 va = r_stval();
  
  pte_t* pte = walk(p->pagetable, va, 0);

  if(*pte & PTE_PG){
    //memory full
    if(p->memory_pages_count == MAX_PSYC_PAGES){
      swap_files(p->pagetable);
    }

    uint64 swap_va = PGROUNDDOWN(va);
    char *mem = kalloc();
    
    struct page_data *pg;
    for(pg = p->swapped_pages; pg < &p->swapped_pages[MAX_PSYC_PAGES]; pg++){
      if(pg->va == swap_va){
        pte_t* g_pte = walk(p->pagetable, swap_va, 0);
        int offset = (pg - p->swapped_pages);

        readFromSwapFile(p, mem, offset*PGSIZE, PGSIZE);

        int index_memory = find_index_in_memory();
        
        struct page_data *free_memory_page = &p->memory_pages[index_memory];

        free_memory_page->used = 1;
        free_memory_page->va = pg->va;

        #if SWAP_ALGO == NUFA
        printf("NFUA\n");
        free_memory_page->age = 0;
        #endif

        #if SWAP_ALGO == LAPA
          printf("LAPA\n");
        free_memory_page->age = (uint64)~0;
        #endif

        #if SWAP_ALGO == SCFIFO
          printf("SCFIFO\n");
        free_memory_page->time=++p->page_timer;
        #endif

        //free the page
        p->swapped_pages_count--;
        pg->used = 0;
        pg->va = 0;
        pg->age = 0;
        p->memory_pages_count++;

        //set pte flags:
        *g_pte = PA2PTE((uint64)mem) | PTE_FLAGS(*pte); //map new adress 
        *g_pte &= ~PTE_PG;     //paged in to memory - turn off bit 
        *g_pte |= PTE_V;
        break;
      }
    }
    sfence_vma();
    return 3;
  }else{
    return 0; //this is segfault
  }
}


// task 2 - choose file 
int choose_from_memory_by_LIFO() 
{
  struct proc *p = myproc();

  struct page_data *mg; 
  mg = p -> memory_pages; 
  return (int)(mg - p->memory_pages); 
}
// task 2 - choose file 
int choose_from_swap_by_LIFO() 
{
  return 1; 
  struct proc *p = myproc();
  struct page_data *g;
  int youngest = p->swapped_pages[0].time; 
  struct page_data *mg = p ->swapped_pages; 
  for(g = p -> swapped_pages ; g< &p-> swapped_pages[MAX_TOTAL_PAGES] ; g++)
  {
     if(g->time < youngest && g -> used == 0 )
     {
      youngest = g-> time; 
      mg = g; 
     }
  }
  return (int)(mg - p->memory_pages); 
}


void update_age(struct proc* p){
  struct page_data *pg;
  pte_t* pte;
  for(pg = p->memory_pages; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
    if(pg->used){
      pte = walk(p->pagetable, pg->va, 0);
      if(*pte & PTE_A){
        //When a page got accessed (check the status of the PTE_A), 
        //the counter isshifted right by one bit, 
        //and then the digit 1 is added to the most significant bit
        pg->age = (pg->age >> 1);
        pg->age |= (0x8000000000000000);
      }
      else{
        //shifted right by one bit if its unsed page
        pg->age = (pg->age >> 1); 
      }

      *pte &= ~ PTE_A; //turn off PTE_A
    }
  }
}

int nfua_algo(){
  struct proc *p = myproc();
  struct page_data *pg;
  uint64 min_age = ~0;
  int min_age_index = 1;
  for(pg = p->memory_pages+1; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
    if(pg->used && pg->age < min_age){
      min_age = pg->age;
      min_age_index = (int)(pg - p->memory_pages);
    }
  }
  return min_age_index;
}

int scfifo_algo(){
  struct proc *p = myproc();
  struct page_data *pg;
  uint64 min_creation_time = (uint64)~0;
  int min_creation_index = 1;

  again:
  min_creation_time = (uint64)~0;
  min_creation_index = 1;

  for(pg = p->memory_pages; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){ //min creation time for fifo 
    if(pg->used && pg->time<= min_creation_time){
      min_creation_index=(int)(pg - p->memory_pages);
      min_creation_time=pg->time;
    }
  }
  pte_t* pte=walk(p->pagetable,p->memory_pages[min_creation_index].va,0); // return addr
  if((*pte & PTE_A)!=0){ //second chance 
    *pte &=~ PTE_A; // trun off the access flag
    p->memory_pages[min_creation_index].time= ++p->page_timer;  
    goto again; // find again 
  }
  // if got here then we found pg with min time that PTE_A is turned off
  return min_creation_index;
}

int lapa_algo(){
  struct proc *p = myproc();
  struct page_data *pg;
  int min_number_of_1=64;
  int index_with_min_1=-1;
  for(pg = p->memory_pages+1; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
    int counter=0,stoploop=0;
    if(pg->used){
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
          uint64 mask = 1 << i;
          if((pg->age & mask)!=0)// if 1 is found 
              counter++;
          if(counter>min_number_of_1) // in case count is bigger than current min 
            stoploop=1;           // stop counting and break from loop
        }
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
          min_number_of_1=counter;
          index_with_min_1=(int)(pg - p->memory_pages);
        }
      }
    }
    return index_with_min_1;
}