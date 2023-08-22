
user/_task3_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <test1>:

#define PGSIZE 4096

//Test1 - Allocating 18 pages, some of them on disk, some in memory.
// then trying to access all arrays that was allocated.
void test1(){
   0:	7155                	addi	sp,sp,-208
   2:	e586                	sd	ra,200(sp)
   4:	e1a2                	sd	s0,192(sp)
   6:	fd26                	sd	s1,184(sp)
   8:	f94a                	sd	s2,176(sp)
   a:	f54e                	sd	s3,168(sp)
   c:	f152                	sd	s4,160(sp)
   e:	ed56                	sd	s5,152(sp)
  10:	e95a                	sd	s6,144(sp)
  12:	0980                	addi	s0,sp,208
    fprintf(2,"-------------test1 start ---------------------\n");
  14:	00001597          	auipc	a1,0x1
  18:	c0c58593          	addi	a1,a1,-1012 # c20 <ustack_free+0x88>
  1c:	4509                	li	a0,2
  1e:	00001097          	auipc	ra,0x1
  22:	8d4080e7          	jalr	-1836(ra) # 8f2 <fprintf>
    int i;
    int j;
    int pid = fork();
  26:	00000097          	auipc	ra,0x0
  2a:	57a080e7          	jalr	1402(ra) # 5a0 <fork>
    if(!pid){
  2e:	c531                	beqz	a0,7a <test1+0x7a>
            fprintf(2,"Filled array num=%d with chars\n", i);
        }
        exit(0);
    }else{
        int status;
        pid = wait(&status);
  30:	f3040513          	addi	a0,s0,-208
  34:	00000097          	auipc	ra,0x0
  38:	57c080e7          	jalr	1404(ra) # 5b0 <wait>
  3c:	862a                	mv	a2,a0
        fprintf(2,"child: pid = %d exit with status %d\n", pid, status);
  3e:	f3042683          	lw	a3,-208(s0)
  42:	00001597          	auipc	a1,0x1
  46:	c9e58593          	addi	a1,a1,-866 # ce0 <ustack_free+0x148>
  4a:	4509                	li	a0,2
  4c:	00001097          	auipc	ra,0x1
  50:	8a6080e7          	jalr	-1882(ra) # 8f2 <fprintf>
    }
        fprintf(2,"-------------test1 finished ---------------------\n");
  54:	00001597          	auipc	a1,0x1
  58:	cb458593          	addi	a1,a1,-844 # d08 <ustack_free+0x170>
  5c:	4509                	li	a0,2
  5e:	00001097          	auipc	ra,0x1
  62:	894080e7          	jalr	-1900(ra) # 8f2 <fprintf>

}
  66:	60ae                	ld	ra,200(sp)
  68:	640e                	ld	s0,192(sp)
  6a:	74ea                	ld	s1,184(sp)
  6c:	794a                	ld	s2,176(sp)
  6e:	79aa                	ld	s3,168(sp)
  70:	7a0a                	ld	s4,160(sp)
  72:	6aea                	ld	s5,152(sp)
  74:	6b4a                	ld	s6,144(sp)
  76:	6169                	addi	sp,sp,208
  78:	8082                	ret
  7a:	84aa                	mv	s1,a0
  7c:	f3040993          	addi	s3,s0,-208
    if(!pid){
  80:	8a4e                	mv	s4,s3
        for(i = 0; i<18; i++){
  82:	892a                	mv	s2,a0
           fprintf(2,"i = %d: allocated memory = %p\n", i, malloc_array[i]);
  84:	00001b17          	auipc	s6,0x1
  88:	bccb0b13          	addi	s6,s6,-1076 # c50 <ustack_free+0xb8>
        for(i = 0; i<18; i++){
  8c:	4ac9                	li	s5,18
           malloc_array[i] = sbrk(PGSIZE); 
  8e:	6505                	lui	a0,0x1
  90:	00000097          	auipc	ra,0x0
  94:	5a0080e7          	jalr	1440(ra) # 630 <sbrk>
  98:	86aa                	mv	a3,a0
  9a:	00aa3023          	sd	a0,0(s4)
           fprintf(2,"i = %d: allocated memory = %p\n", i, malloc_array[i]);
  9e:	864a                	mv	a2,s2
  a0:	85da                	mv	a1,s6
  a2:	4509                	li	a0,2
  a4:	00001097          	auipc	ra,0x1
  a8:	84e080e7          	jalr	-1970(ra) # 8f2 <fprintf>
        for(i = 0; i<18; i++){
  ac:	2905                	addiw	s2,s2,1
  ae:	0a21                	addi	s4,s4,8
  b0:	fd591fe3          	bne	s2,s5,8e <test1+0x8e>
        fprintf(2,"Allocated 18 pages, some of them on disk\n");
  b4:	00001597          	auipc	a1,0x1
  b8:	bbc58593          	addi	a1,a1,-1092 # c70 <ustack_free+0xd8>
  bc:	4509                	li	a0,2
  be:	00001097          	auipc	ra,0x1
  c2:	834080e7          	jalr	-1996(ra) # 8f2 <fprintf>
        fprintf(2,"Lets try to access all pages:\n");
  c6:	00001597          	auipc	a1,0x1
  ca:	bda58593          	addi	a1,a1,-1062 # ca0 <ustack_free+0x108>
  ce:	4509                	li	a0,2
  d0:	00001097          	auipc	ra,0x1
  d4:	822080e7          	jalr	-2014(ra) # 8f2 <fprintf>
        for(i = 0; i<18; i++){
  d8:	6b05                	lui	s6,0x1
                malloc_array[i][j] = 'x'; 
  da:	07800913          	li	s2,120
            fprintf(2,"Filled array num=%d with chars\n", i);
  de:	00001a97          	auipc	s5,0x1
  e2:	be2a8a93          	addi	s5,s5,-1054 # cc0 <ustack_free+0x128>
        for(i = 0; i<18; i++){
  e6:	4a49                	li	s4,18
            for(j = 0; j<PGSIZE; j++)
  e8:	0009b783          	ld	a5,0(s3)
  ec:	01678733          	add	a4,a5,s6
                malloc_array[i][j] = 'x'; 
  f0:	01278023          	sb	s2,0(a5)
            for(j = 0; j<PGSIZE; j++)
  f4:	0785                	addi	a5,a5,1
  f6:	fef71de3          	bne	a4,a5,f0 <test1+0xf0>
            fprintf(2,"Filled array num=%d with chars\n", i);
  fa:	8626                	mv	a2,s1
  fc:	85d6                	mv	a1,s5
  fe:	4509                	li	a0,2
 100:	00000097          	auipc	ra,0x0
 104:	7f2080e7          	jalr	2034(ra) # 8f2 <fprintf>
        for(i = 0; i<18; i++){
 108:	2485                	addiw	s1,s1,1
 10a:	09a1                	addi	s3,s3,8
 10c:	fd449ee3          	bne	s1,s4,e8 <test1+0xe8>
        exit(0);
 110:	4501                	li	a0,0
 112:	00000097          	auipc	ra,0x0
 116:	496080e7          	jalr	1174(ra) # 5a8 <exit>

000000000000011a <test2>:

//Test2 testing alloc and dealloc (testing that delloa works fine, 
//and we dont recieve panic: more that 32 pages for process)
void test2(){
 11a:	1141                	addi	sp,sp,-16
 11c:	e406                	sd	ra,8(sp)
 11e:	e022                	sd	s0,0(sp)
 120:	0800                	addi	s0,sp,16
    fprintf(2,"-------------test2 start ---------------------\n");
 122:	00001597          	auipc	a1,0x1
 126:	c1e58593          	addi	a1,a1,-994 # d40 <ustack_free+0x1a8>
 12a:	4509                	li	a0,2
 12c:	00000097          	auipc	ra,0x0
 130:	7c6080e7          	jalr	1990(ra) # 8f2 <fprintf>
    char* i;
    i = sbrk(20*PGSIZE);
 134:	6551                	lui	a0,0x14
 136:	00000097          	auipc	ra,0x0
 13a:	4fa080e7          	jalr	1274(ra) # 630 <sbrk>
 13e:	862a                	mv	a2,a0
    fprintf(2,"allocated memory = %p\n", i);
 140:	00001597          	auipc	a1,0x1
 144:	b1858593          	addi	a1,a1,-1256 # c58 <ustack_free+0xc0>
 148:	4509                	li	a0,2
 14a:	00000097          	auipc	ra,0x0
 14e:	7a8080e7          	jalr	1960(ra) # 8f2 <fprintf>
    i = sbrk(-20*PGSIZE);
 152:	7531                	lui	a0,0xfffec
 154:	00000097          	auipc	ra,0x0
 158:	4dc080e7          	jalr	1244(ra) # 630 <sbrk>
 15c:	862a                	mv	a2,a0
    fprintf(2,"deallocated memory = %p\n", i);
 15e:	00001597          	auipc	a1,0x1
 162:	c1258593          	addi	a1,a1,-1006 # d70 <ustack_free+0x1d8>
 166:	4509                	li	a0,2
 168:	00000097          	auipc	ra,0x0
 16c:	78a080e7          	jalr	1930(ra) # 8f2 <fprintf>
    i = sbrk(20*PGSIZE);
 170:	6551                	lui	a0,0x14
 172:	00000097          	auipc	ra,0x0
 176:	4be080e7          	jalr	1214(ra) # 630 <sbrk>
 17a:	862a                	mv	a2,a0
    fprintf(2,"allocated memory = %p\n", i);
 17c:	00001597          	auipc	a1,0x1
 180:	adc58593          	addi	a1,a1,-1316 # c58 <ustack_free+0xc0>
 184:	4509                	li	a0,2
 186:	00000097          	auipc	ra,0x0
 18a:	76c080e7          	jalr	1900(ra) # 8f2 <fprintf>
    i = sbrk(-20*PGSIZE);
 18e:	7531                	lui	a0,0xfffec
 190:	00000097          	auipc	ra,0x0
 194:	4a0080e7          	jalr	1184(ra) # 630 <sbrk>
 198:	862a                	mv	a2,a0
    fprintf(2,"deallocated memory = %p\n", i);
 19a:	00001597          	auipc	a1,0x1
 19e:	bd658593          	addi	a1,a1,-1066 # d70 <ustack_free+0x1d8>
 1a2:	4509                	li	a0,2
 1a4:	00000097          	auipc	ra,0x0
 1a8:	74e080e7          	jalr	1870(ra) # 8f2 <fprintf>
    i = sbrk(20*PGSIZE);
 1ac:	6551                	lui	a0,0x14
 1ae:	00000097          	auipc	ra,0x0
 1b2:	482080e7          	jalr	1154(ra) # 630 <sbrk>
 1b6:	862a                	mv	a2,a0
    fprintf(2,"allocated memory = %p\n", i);
 1b8:	00001597          	auipc	a1,0x1
 1bc:	aa058593          	addi	a1,a1,-1376 # c58 <ustack_free+0xc0>
 1c0:	4509                	li	a0,2
 1c2:	00000097          	auipc	ra,0x0
 1c6:	730080e7          	jalr	1840(ra) # 8f2 <fprintf>
    i = sbrk(-20*PGSIZE);
 1ca:	7531                	lui	a0,0xfffec
 1cc:	00000097          	auipc	ra,0x0
 1d0:	464080e7          	jalr	1124(ra) # 630 <sbrk>
 1d4:	862a                	mv	a2,a0
    fprintf(2,"deallocated memory = %p\n", i);
 1d6:	00001597          	auipc	a1,0x1
 1da:	b9a58593          	addi	a1,a1,-1126 # d70 <ustack_free+0x1d8>
 1de:	4509                	li	a0,2
 1e0:	00000097          	auipc	ra,0x0
 1e4:	712080e7          	jalr	1810(ra) # 8f2 <fprintf>

    fprintf(2,"-------------test2 finished ---------------------\n");
 1e8:	00001597          	auipc	a1,0x1
 1ec:	ba858593          	addi	a1,a1,-1112 # d90 <ustack_free+0x1f8>
 1f0:	4509                	li	a0,2
 1f2:	00000097          	auipc	ra,0x0
 1f6:	700080e7          	jalr	1792(ra) # 8f2 <fprintf>


}
 1fa:	60a2                	ld	ra,8(sp)
 1fc:	6402                	ld	s0,0(sp)
 1fe:	0141                	addi	sp,sp,16
 200:	8082                	ret

0000000000000202 <test3>:

//Test3 - parent allocates a lot of memory, forks, 
//and child can access all his data
void test3(){
 202:	715d                	addi	sp,sp,-80
 204:	e486                	sd	ra,72(sp)
 206:	e0a2                	sd	s0,64(sp)
 208:	fc26                	sd	s1,56(sp)
 20a:	f84a                	sd	s2,48(sp)
 20c:	f44e                	sd	s3,40(sp)
 20e:	f052                	sd	s4,32(sp)
 210:	ec56                	sd	s5,24(sp)
 212:	e85a                	sd	s6,16(sp)
 214:	0880                	addi	s0,sp,80
    fprintf(2,"-------------test3 start ---------------------\n");
 216:	00001597          	auipc	a1,0x1
 21a:	bb258593          	addi	a1,a1,-1102 # dc8 <ustack_free+0x230>
 21e:	4509                	li	a0,2
 220:	00000097          	auipc	ra,0x0
 224:	6d2080e7          	jalr	1746(ra) # 8f2 <fprintf>
    uint64 i;
    char* arr = malloc(PGSIZE*17);
 228:	6545                	lui	a0,0x11
 22a:	00000097          	auipc	ra,0x0
 22e:	7b4080e7          	jalr	1972(ra) # 9de <malloc>
 232:	89aa                	mv	s3,a0
    for(i = 0; i < PGSIZE*17; i+=PGSIZE){
 234:	4481                	li	s1,0
        arr[i] = 'a';
 236:	06100913          	li	s2,97
        fprintf(2,"dad: arr[%d]=%c\n", i, arr[i]);
 23a:	00001b17          	auipc	s6,0x1
 23e:	bbeb0b13          	addi	s6,s6,-1090 # df8 <ustack_free+0x260>
    for(i = 0; i < PGSIZE*17; i+=PGSIZE){
 242:	6a85                	lui	s5,0x1
 244:	6a45                	lui	s4,0x11
        arr[i] = 'a';
 246:	009987b3          	add	a5,s3,s1
 24a:	01278023          	sb	s2,0(a5)
        fprintf(2,"dad: arr[%d]=%c\n", i, arr[i]);
 24e:	86ca                	mv	a3,s2
 250:	8626                	mv	a2,s1
 252:	85da                	mv	a1,s6
 254:	4509                	li	a0,2
 256:	00000097          	auipc	ra,0x0
 25a:	69c080e7          	jalr	1692(ra) # 8f2 <fprintf>
    for(i = 0; i < PGSIZE*17; i+=PGSIZE){
 25e:	94d6                	add	s1,s1,s5
 260:	ff4493e3          	bne	s1,s4,246 <test3+0x44>
    }
    int pid = fork();
 264:	00000097          	auipc	ra,0x0
 268:	33c080e7          	jalr	828(ra) # 5a0 <fork>
    if(!pid){
 26c:	c939                	beqz	a0,2c2 <test3+0xc0>
            fprintf(2,"child: arr[%d]=%c\n", i, arr[i]);
        }
        exit(i);
    }else{
        int status;
        pid = wait(&status);
 26e:	fbc40513          	addi	a0,s0,-68
 272:	00000097          	auipc	ra,0x0
 276:	33e080e7          	jalr	830(ra) # 5b0 <wait>
 27a:	862a                	mv	a2,a0
        fprintf(2,"child: pid = %d exit with status %d\n", pid, status);
 27c:	fbc42683          	lw	a3,-68(s0)
 280:	00001597          	auipc	a1,0x1
 284:	a6058593          	addi	a1,a1,-1440 # ce0 <ustack_free+0x148>
 288:	4509                	li	a0,2
 28a:	00000097          	auipc	ra,0x0
 28e:	668080e7          	jalr	1640(ra) # 8f2 <fprintf>
        sbrk(-17*PGSIZE);
 292:	753d                	lui	a0,0xfffef
 294:	00000097          	auipc	ra,0x0
 298:	39c080e7          	jalr	924(ra) # 630 <sbrk>
    }
        fprintf(2,"-------------test3 finished ---------------------\n");
 29c:	00001597          	auipc	a1,0x1
 2a0:	b8c58593          	addi	a1,a1,-1140 # e28 <ustack_free+0x290>
 2a4:	4509                	li	a0,2
 2a6:	00000097          	auipc	ra,0x0
 2aa:	64c080e7          	jalr	1612(ra) # 8f2 <fprintf>

}
 2ae:	60a6                	ld	ra,72(sp)
 2b0:	6406                	ld	s0,64(sp)
 2b2:	74e2                	ld	s1,56(sp)
 2b4:	7942                	ld	s2,48(sp)
 2b6:	79a2                	ld	s3,40(sp)
 2b8:	7a02                	ld	s4,32(sp)
 2ba:	6ae2                	ld	s5,24(sp)
 2bc:	6b42                	ld	s6,16(sp)
 2be:	6161                	addi	sp,sp,80
 2c0:	8082                	ret
        for(i=0; i < PGSIZE*17; i+=PGSIZE){
 2c2:	4481                	li	s1,0
            fprintf(2,"child: arr[%d]=%c\n", i, arr[i]);
 2c4:	00001a97          	auipc	s5,0x1
 2c8:	b4ca8a93          	addi	s5,s5,-1204 # e10 <ustack_free+0x278>
        for(i=0; i < PGSIZE*17; i+=PGSIZE){
 2cc:	6a05                	lui	s4,0x1
 2ce:	6945                	lui	s2,0x11
            fprintf(2,"child: arr[%d]=%c\n", i, arr[i]);
 2d0:	009987b3          	add	a5,s3,s1
 2d4:	0007c683          	lbu	a3,0(a5)
 2d8:	8626                	mv	a2,s1
 2da:	85d6                	mv	a1,s5
 2dc:	4509                	li	a0,2
 2de:	00000097          	auipc	ra,0x0
 2e2:	614080e7          	jalr	1556(ra) # 8f2 <fprintf>
        for(i=0; i < PGSIZE*17; i+=PGSIZE){
 2e6:	94d2                	add	s1,s1,s4
 2e8:	ff2494e3          	bne	s1,s2,2d0 <test3+0xce>
        exit(i);
 2ec:	6545                	lui	a0,0x11
 2ee:	00000097          	auipc	ra,0x0
 2f2:	2ba080e7          	jalr	698(ra) # 5a8 <exit>

00000000000002f6 <main>:




int main(int argc, char** argv){
 2f6:	1141                	addi	sp,sp,-16
 2f8:	e406                	sd	ra,8(sp)
 2fa:	e022                	sd	s0,0(sp)
 2fc:	0800                	addi	s0,sp,16
    test1();
 2fe:	00000097          	auipc	ra,0x0
 302:	d02080e7          	jalr	-766(ra) # 0 <test1>
    test2();
 306:	00000097          	auipc	ra,0x0
 30a:	e14080e7          	jalr	-492(ra) # 11a <test2>
    test3();
 30e:	00000097          	auipc	ra,0x0
 312:	ef4080e7          	jalr	-268(ra) # 202 <test3>

    exit(0);
 316:	4501                	li	a0,0
 318:	00000097          	auipc	ra,0x0
 31c:	290080e7          	jalr	656(ra) # 5a8 <exit>

0000000000000320 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 320:	1141                	addi	sp,sp,-16
 322:	e406                	sd	ra,8(sp)
 324:	e022                	sd	s0,0(sp)
 326:	0800                	addi	s0,sp,16
  extern int main();
  main();
 328:	00000097          	auipc	ra,0x0
 32c:	fce080e7          	jalr	-50(ra) # 2f6 <main>
  exit(0);
 330:	4501                	li	a0,0
 332:	00000097          	auipc	ra,0x0
 336:	276080e7          	jalr	630(ra) # 5a8 <exit>

000000000000033a <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 33a:	1141                	addi	sp,sp,-16
 33c:	e422                	sd	s0,8(sp)
 33e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 340:	87aa                	mv	a5,a0
 342:	0585                	addi	a1,a1,1
 344:	0785                	addi	a5,a5,1
 346:	fff5c703          	lbu	a4,-1(a1)
 34a:	fee78fa3          	sb	a4,-1(a5)
 34e:	fb75                	bnez	a4,342 <strcpy+0x8>
    ;
  return os;
}
 350:	6422                	ld	s0,8(sp)
 352:	0141                	addi	sp,sp,16
 354:	8082                	ret

0000000000000356 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 356:	1141                	addi	sp,sp,-16
 358:	e422                	sd	s0,8(sp)
 35a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 35c:	00054783          	lbu	a5,0(a0) # 11000 <base+0xfff0>
 360:	cb91                	beqz	a5,374 <strcmp+0x1e>
 362:	0005c703          	lbu	a4,0(a1)
 366:	00f71763          	bne	a4,a5,374 <strcmp+0x1e>
    p++, q++;
 36a:	0505                	addi	a0,a0,1
 36c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 36e:	00054783          	lbu	a5,0(a0)
 372:	fbe5                	bnez	a5,362 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 374:	0005c503          	lbu	a0,0(a1)
}
 378:	40a7853b          	subw	a0,a5,a0
 37c:	6422                	ld	s0,8(sp)
 37e:	0141                	addi	sp,sp,16
 380:	8082                	ret

0000000000000382 <strlen>:

uint
strlen(const char *s)
{
 382:	1141                	addi	sp,sp,-16
 384:	e422                	sd	s0,8(sp)
 386:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 388:	00054783          	lbu	a5,0(a0)
 38c:	cf91                	beqz	a5,3a8 <strlen+0x26>
 38e:	0505                	addi	a0,a0,1
 390:	87aa                	mv	a5,a0
 392:	4685                	li	a3,1
 394:	9e89                	subw	a3,a3,a0
 396:	00f6853b          	addw	a0,a3,a5
 39a:	0785                	addi	a5,a5,1
 39c:	fff7c703          	lbu	a4,-1(a5)
 3a0:	fb7d                	bnez	a4,396 <strlen+0x14>
    ;
  return n;
}
 3a2:	6422                	ld	s0,8(sp)
 3a4:	0141                	addi	sp,sp,16
 3a6:	8082                	ret
  for(n = 0; s[n]; n++)
 3a8:	4501                	li	a0,0
 3aa:	bfe5                	j	3a2 <strlen+0x20>

00000000000003ac <memset>:

void*
memset(void *dst, int c, uint n)
{
 3ac:	1141                	addi	sp,sp,-16
 3ae:	e422                	sd	s0,8(sp)
 3b0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 3b2:	ca19                	beqz	a2,3c8 <memset+0x1c>
 3b4:	87aa                	mv	a5,a0
 3b6:	1602                	slli	a2,a2,0x20
 3b8:	9201                	srli	a2,a2,0x20
 3ba:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 3be:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 3c2:	0785                	addi	a5,a5,1
 3c4:	fee79de3          	bne	a5,a4,3be <memset+0x12>
  }
  return dst;
}
 3c8:	6422                	ld	s0,8(sp)
 3ca:	0141                	addi	sp,sp,16
 3cc:	8082                	ret

00000000000003ce <strchr>:

char*
strchr(const char *s, char c)
{
 3ce:	1141                	addi	sp,sp,-16
 3d0:	e422                	sd	s0,8(sp)
 3d2:	0800                	addi	s0,sp,16
  for(; *s; s++)
 3d4:	00054783          	lbu	a5,0(a0)
 3d8:	cb99                	beqz	a5,3ee <strchr+0x20>
    if(*s == c)
 3da:	00f58763          	beq	a1,a5,3e8 <strchr+0x1a>
  for(; *s; s++)
 3de:	0505                	addi	a0,a0,1
 3e0:	00054783          	lbu	a5,0(a0)
 3e4:	fbfd                	bnez	a5,3da <strchr+0xc>
      return (char*)s;
  return 0;
 3e6:	4501                	li	a0,0
}
 3e8:	6422                	ld	s0,8(sp)
 3ea:	0141                	addi	sp,sp,16
 3ec:	8082                	ret
  return 0;
 3ee:	4501                	li	a0,0
 3f0:	bfe5                	j	3e8 <strchr+0x1a>

00000000000003f2 <gets>:

char*
gets(char *buf, int max)
{
 3f2:	711d                	addi	sp,sp,-96
 3f4:	ec86                	sd	ra,88(sp)
 3f6:	e8a2                	sd	s0,80(sp)
 3f8:	e4a6                	sd	s1,72(sp)
 3fa:	e0ca                	sd	s2,64(sp)
 3fc:	fc4e                	sd	s3,56(sp)
 3fe:	f852                	sd	s4,48(sp)
 400:	f456                	sd	s5,40(sp)
 402:	f05a                	sd	s6,32(sp)
 404:	ec5e                	sd	s7,24(sp)
 406:	1080                	addi	s0,sp,96
 408:	8baa                	mv	s7,a0
 40a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 40c:	892a                	mv	s2,a0
 40e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 410:	4aa9                	li	s5,10
 412:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 414:	89a6                	mv	s3,s1
 416:	2485                	addiw	s1,s1,1
 418:	0344d863          	bge	s1,s4,448 <gets+0x56>
    cc = read(0, &c, 1);
 41c:	4605                	li	a2,1
 41e:	faf40593          	addi	a1,s0,-81
 422:	4501                	li	a0,0
 424:	00000097          	auipc	ra,0x0
 428:	19c080e7          	jalr	412(ra) # 5c0 <read>
    if(cc < 1)
 42c:	00a05e63          	blez	a0,448 <gets+0x56>
    buf[i++] = c;
 430:	faf44783          	lbu	a5,-81(s0)
 434:	00f90023          	sb	a5,0(s2) # 11000 <base+0xfff0>
    if(c == '\n' || c == '\r')
 438:	01578763          	beq	a5,s5,446 <gets+0x54>
 43c:	0905                	addi	s2,s2,1
 43e:	fd679be3          	bne	a5,s6,414 <gets+0x22>
  for(i=0; i+1 < max; ){
 442:	89a6                	mv	s3,s1
 444:	a011                	j	448 <gets+0x56>
 446:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 448:	99de                	add	s3,s3,s7
 44a:	00098023          	sb	zero,0(s3)
  return buf;
}
 44e:	855e                	mv	a0,s7
 450:	60e6                	ld	ra,88(sp)
 452:	6446                	ld	s0,80(sp)
 454:	64a6                	ld	s1,72(sp)
 456:	6906                	ld	s2,64(sp)
 458:	79e2                	ld	s3,56(sp)
 45a:	7a42                	ld	s4,48(sp)
 45c:	7aa2                	ld	s5,40(sp)
 45e:	7b02                	ld	s6,32(sp)
 460:	6be2                	ld	s7,24(sp)
 462:	6125                	addi	sp,sp,96
 464:	8082                	ret

0000000000000466 <stat>:

int
stat(const char *n, struct stat *st)
{
 466:	1101                	addi	sp,sp,-32
 468:	ec06                	sd	ra,24(sp)
 46a:	e822                	sd	s0,16(sp)
 46c:	e426                	sd	s1,8(sp)
 46e:	e04a                	sd	s2,0(sp)
 470:	1000                	addi	s0,sp,32
 472:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 474:	4581                	li	a1,0
 476:	00000097          	auipc	ra,0x0
 47a:	172080e7          	jalr	370(ra) # 5e8 <open>
  if(fd < 0)
 47e:	02054563          	bltz	a0,4a8 <stat+0x42>
 482:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 484:	85ca                	mv	a1,s2
 486:	00000097          	auipc	ra,0x0
 48a:	17a080e7          	jalr	378(ra) # 600 <fstat>
 48e:	892a                	mv	s2,a0
  close(fd);
 490:	8526                	mv	a0,s1
 492:	00000097          	auipc	ra,0x0
 496:	13e080e7          	jalr	318(ra) # 5d0 <close>
  return r;
}
 49a:	854a                	mv	a0,s2
 49c:	60e2                	ld	ra,24(sp)
 49e:	6442                	ld	s0,16(sp)
 4a0:	64a2                	ld	s1,8(sp)
 4a2:	6902                	ld	s2,0(sp)
 4a4:	6105                	addi	sp,sp,32
 4a6:	8082                	ret
    return -1;
 4a8:	597d                	li	s2,-1
 4aa:	bfc5                	j	49a <stat+0x34>

00000000000004ac <atoi>:

int
atoi(const char *s)
{
 4ac:	1141                	addi	sp,sp,-16
 4ae:	e422                	sd	s0,8(sp)
 4b0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 4b2:	00054603          	lbu	a2,0(a0)
 4b6:	fd06079b          	addiw	a5,a2,-48
 4ba:	0ff7f793          	andi	a5,a5,255
 4be:	4725                	li	a4,9
 4c0:	02f76963          	bltu	a4,a5,4f2 <atoi+0x46>
 4c4:	86aa                	mv	a3,a0
  n = 0;
 4c6:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 4c8:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 4ca:	0685                	addi	a3,a3,1
 4cc:	0025179b          	slliw	a5,a0,0x2
 4d0:	9fa9                	addw	a5,a5,a0
 4d2:	0017979b          	slliw	a5,a5,0x1
 4d6:	9fb1                	addw	a5,a5,a2
 4d8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 4dc:	0006c603          	lbu	a2,0(a3)
 4e0:	fd06071b          	addiw	a4,a2,-48
 4e4:	0ff77713          	andi	a4,a4,255
 4e8:	fee5f1e3          	bgeu	a1,a4,4ca <atoi+0x1e>
  return n;
}
 4ec:	6422                	ld	s0,8(sp)
 4ee:	0141                	addi	sp,sp,16
 4f0:	8082                	ret
  n = 0;
 4f2:	4501                	li	a0,0
 4f4:	bfe5                	j	4ec <atoi+0x40>

00000000000004f6 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 4f6:	1141                	addi	sp,sp,-16
 4f8:	e422                	sd	s0,8(sp)
 4fa:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 4fc:	02b57463          	bgeu	a0,a1,524 <memmove+0x2e>
    while(n-- > 0)
 500:	00c05f63          	blez	a2,51e <memmove+0x28>
 504:	1602                	slli	a2,a2,0x20
 506:	9201                	srli	a2,a2,0x20
 508:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 50c:	872a                	mv	a4,a0
      *dst++ = *src++;
 50e:	0585                	addi	a1,a1,1
 510:	0705                	addi	a4,a4,1
 512:	fff5c683          	lbu	a3,-1(a1)
 516:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 51a:	fee79ae3          	bne	a5,a4,50e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 51e:	6422                	ld	s0,8(sp)
 520:	0141                	addi	sp,sp,16
 522:	8082                	ret
    dst += n;
 524:	00c50733          	add	a4,a0,a2
    src += n;
 528:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 52a:	fec05ae3          	blez	a2,51e <memmove+0x28>
 52e:	fff6079b          	addiw	a5,a2,-1
 532:	1782                	slli	a5,a5,0x20
 534:	9381                	srli	a5,a5,0x20
 536:	fff7c793          	not	a5,a5
 53a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 53c:	15fd                	addi	a1,a1,-1
 53e:	177d                	addi	a4,a4,-1
 540:	0005c683          	lbu	a3,0(a1)
 544:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 548:	fee79ae3          	bne	a5,a4,53c <memmove+0x46>
 54c:	bfc9                	j	51e <memmove+0x28>

000000000000054e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 54e:	1141                	addi	sp,sp,-16
 550:	e422                	sd	s0,8(sp)
 552:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 554:	ca05                	beqz	a2,584 <memcmp+0x36>
 556:	fff6069b          	addiw	a3,a2,-1
 55a:	1682                	slli	a3,a3,0x20
 55c:	9281                	srli	a3,a3,0x20
 55e:	0685                	addi	a3,a3,1
 560:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 562:	00054783          	lbu	a5,0(a0)
 566:	0005c703          	lbu	a4,0(a1)
 56a:	00e79863          	bne	a5,a4,57a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 56e:	0505                	addi	a0,a0,1
    p2++;
 570:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 572:	fed518e3          	bne	a0,a3,562 <memcmp+0x14>
  }
  return 0;
 576:	4501                	li	a0,0
 578:	a019                	j	57e <memcmp+0x30>
      return *p1 - *p2;
 57a:	40e7853b          	subw	a0,a5,a4
}
 57e:	6422                	ld	s0,8(sp)
 580:	0141                	addi	sp,sp,16
 582:	8082                	ret
  return 0;
 584:	4501                	li	a0,0
 586:	bfe5                	j	57e <memcmp+0x30>

0000000000000588 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 588:	1141                	addi	sp,sp,-16
 58a:	e406                	sd	ra,8(sp)
 58c:	e022                	sd	s0,0(sp)
 58e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 590:	00000097          	auipc	ra,0x0
 594:	f66080e7          	jalr	-154(ra) # 4f6 <memmove>
}
 598:	60a2                	ld	ra,8(sp)
 59a:	6402                	ld	s0,0(sp)
 59c:	0141                	addi	sp,sp,16
 59e:	8082                	ret

00000000000005a0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 5a0:	4885                	li	a7,1
 ecall
 5a2:	00000073          	ecall
 ret
 5a6:	8082                	ret

00000000000005a8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 5a8:	4889                	li	a7,2
 ecall
 5aa:	00000073          	ecall
 ret
 5ae:	8082                	ret

00000000000005b0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 5b0:	488d                	li	a7,3
 ecall
 5b2:	00000073          	ecall
 ret
 5b6:	8082                	ret

00000000000005b8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 5b8:	4891                	li	a7,4
 ecall
 5ba:	00000073          	ecall
 ret
 5be:	8082                	ret

00000000000005c0 <read>:
.global read
read:
 li a7, SYS_read
 5c0:	4895                	li	a7,5
 ecall
 5c2:	00000073          	ecall
 ret
 5c6:	8082                	ret

00000000000005c8 <write>:
.global write
write:
 li a7, SYS_write
 5c8:	48c1                	li	a7,16
 ecall
 5ca:	00000073          	ecall
 ret
 5ce:	8082                	ret

00000000000005d0 <close>:
.global close
close:
 li a7, SYS_close
 5d0:	48d5                	li	a7,21
 ecall
 5d2:	00000073          	ecall
 ret
 5d6:	8082                	ret

00000000000005d8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 5d8:	4899                	li	a7,6
 ecall
 5da:	00000073          	ecall
 ret
 5de:	8082                	ret

00000000000005e0 <exec>:
.global exec
exec:
 li a7, SYS_exec
 5e0:	489d                	li	a7,7
 ecall
 5e2:	00000073          	ecall
 ret
 5e6:	8082                	ret

00000000000005e8 <open>:
.global open
open:
 li a7, SYS_open
 5e8:	48bd                	li	a7,15
 ecall
 5ea:	00000073          	ecall
 ret
 5ee:	8082                	ret

00000000000005f0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 5f0:	48c5                	li	a7,17
 ecall
 5f2:	00000073          	ecall
 ret
 5f6:	8082                	ret

00000000000005f8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 5f8:	48c9                	li	a7,18
 ecall
 5fa:	00000073          	ecall
 ret
 5fe:	8082                	ret

0000000000000600 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 600:	48a1                	li	a7,8
 ecall
 602:	00000073          	ecall
 ret
 606:	8082                	ret

0000000000000608 <link>:
.global link
link:
 li a7, SYS_link
 608:	48cd                	li	a7,19
 ecall
 60a:	00000073          	ecall
 ret
 60e:	8082                	ret

0000000000000610 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 610:	48d1                	li	a7,20
 ecall
 612:	00000073          	ecall
 ret
 616:	8082                	ret

0000000000000618 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 618:	48a5                	li	a7,9
 ecall
 61a:	00000073          	ecall
 ret
 61e:	8082                	ret

0000000000000620 <dup>:
.global dup
dup:
 li a7, SYS_dup
 620:	48a9                	li	a7,10
 ecall
 622:	00000073          	ecall
 ret
 626:	8082                	ret

0000000000000628 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 628:	48ad                	li	a7,11
 ecall
 62a:	00000073          	ecall
 ret
 62e:	8082                	ret

0000000000000630 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 630:	48b1                	li	a7,12
 ecall
 632:	00000073          	ecall
 ret
 636:	8082                	ret

0000000000000638 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 638:	48b5                	li	a7,13
 ecall
 63a:	00000073          	ecall
 ret
 63e:	8082                	ret

0000000000000640 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 640:	48b9                	li	a7,14
 ecall
 642:	00000073          	ecall
 ret
 646:	8082                	ret

0000000000000648 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 648:	1101                	addi	sp,sp,-32
 64a:	ec06                	sd	ra,24(sp)
 64c:	e822                	sd	s0,16(sp)
 64e:	1000                	addi	s0,sp,32
 650:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 654:	4605                	li	a2,1
 656:	fef40593          	addi	a1,s0,-17
 65a:	00000097          	auipc	ra,0x0
 65e:	f6e080e7          	jalr	-146(ra) # 5c8 <write>
}
 662:	60e2                	ld	ra,24(sp)
 664:	6442                	ld	s0,16(sp)
 666:	6105                	addi	sp,sp,32
 668:	8082                	ret

000000000000066a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 66a:	7139                	addi	sp,sp,-64
 66c:	fc06                	sd	ra,56(sp)
 66e:	f822                	sd	s0,48(sp)
 670:	f426                	sd	s1,40(sp)
 672:	f04a                	sd	s2,32(sp)
 674:	ec4e                	sd	s3,24(sp)
 676:	0080                	addi	s0,sp,64
 678:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 67a:	c299                	beqz	a3,680 <printint+0x16>
 67c:	0805c863          	bltz	a1,70c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 680:	2581                	sext.w	a1,a1
  neg = 0;
 682:	4881                	li	a7,0
 684:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 688:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 68a:	2601                	sext.w	a2,a2
 68c:	00000517          	auipc	a0,0x0
 690:	7dc50513          	addi	a0,a0,2012 # e68 <digits>
 694:	883a                	mv	a6,a4
 696:	2705                	addiw	a4,a4,1
 698:	02c5f7bb          	remuw	a5,a1,a2
 69c:	1782                	slli	a5,a5,0x20
 69e:	9381                	srli	a5,a5,0x20
 6a0:	97aa                	add	a5,a5,a0
 6a2:	0007c783          	lbu	a5,0(a5)
 6a6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 6aa:	0005879b          	sext.w	a5,a1
 6ae:	02c5d5bb          	divuw	a1,a1,a2
 6b2:	0685                	addi	a3,a3,1
 6b4:	fec7f0e3          	bgeu	a5,a2,694 <printint+0x2a>
  if(neg)
 6b8:	00088b63          	beqz	a7,6ce <printint+0x64>
    buf[i++] = '-';
 6bc:	fd040793          	addi	a5,s0,-48
 6c0:	973e                	add	a4,a4,a5
 6c2:	02d00793          	li	a5,45
 6c6:	fef70823          	sb	a5,-16(a4)
 6ca:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 6ce:	02e05863          	blez	a4,6fe <printint+0x94>
 6d2:	fc040793          	addi	a5,s0,-64
 6d6:	00e78933          	add	s2,a5,a4
 6da:	fff78993          	addi	s3,a5,-1
 6de:	99ba                	add	s3,s3,a4
 6e0:	377d                	addiw	a4,a4,-1
 6e2:	1702                	slli	a4,a4,0x20
 6e4:	9301                	srli	a4,a4,0x20
 6e6:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6ea:	fff94583          	lbu	a1,-1(s2)
 6ee:	8526                	mv	a0,s1
 6f0:	00000097          	auipc	ra,0x0
 6f4:	f58080e7          	jalr	-168(ra) # 648 <putc>
  while(--i >= 0)
 6f8:	197d                	addi	s2,s2,-1
 6fa:	ff3918e3          	bne	s2,s3,6ea <printint+0x80>
}
 6fe:	70e2                	ld	ra,56(sp)
 700:	7442                	ld	s0,48(sp)
 702:	74a2                	ld	s1,40(sp)
 704:	7902                	ld	s2,32(sp)
 706:	69e2                	ld	s3,24(sp)
 708:	6121                	addi	sp,sp,64
 70a:	8082                	ret
    x = -xx;
 70c:	40b005bb          	negw	a1,a1
    neg = 1;
 710:	4885                	li	a7,1
    x = -xx;
 712:	bf8d                	j	684 <printint+0x1a>

0000000000000714 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 714:	7119                	addi	sp,sp,-128
 716:	fc86                	sd	ra,120(sp)
 718:	f8a2                	sd	s0,112(sp)
 71a:	f4a6                	sd	s1,104(sp)
 71c:	f0ca                	sd	s2,96(sp)
 71e:	ecce                	sd	s3,88(sp)
 720:	e8d2                	sd	s4,80(sp)
 722:	e4d6                	sd	s5,72(sp)
 724:	e0da                	sd	s6,64(sp)
 726:	fc5e                	sd	s7,56(sp)
 728:	f862                	sd	s8,48(sp)
 72a:	f466                	sd	s9,40(sp)
 72c:	f06a                	sd	s10,32(sp)
 72e:	ec6e                	sd	s11,24(sp)
 730:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 732:	0005c903          	lbu	s2,0(a1)
 736:	18090f63          	beqz	s2,8d4 <vprintf+0x1c0>
 73a:	8aaa                	mv	s5,a0
 73c:	8b32                	mv	s6,a2
 73e:	00158493          	addi	s1,a1,1
  state = 0;
 742:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 744:	02500a13          	li	s4,37
      if(c == 'd'){
 748:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 74c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 750:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 754:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 758:	00000b97          	auipc	s7,0x0
 75c:	710b8b93          	addi	s7,s7,1808 # e68 <digits>
 760:	a839                	j	77e <vprintf+0x6a>
        putc(fd, c);
 762:	85ca                	mv	a1,s2
 764:	8556                	mv	a0,s5
 766:	00000097          	auipc	ra,0x0
 76a:	ee2080e7          	jalr	-286(ra) # 648 <putc>
 76e:	a019                	j	774 <vprintf+0x60>
    } else if(state == '%'){
 770:	01498f63          	beq	s3,s4,78e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 774:	0485                	addi	s1,s1,1
 776:	fff4c903          	lbu	s2,-1(s1)
 77a:	14090d63          	beqz	s2,8d4 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 77e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 782:	fe0997e3          	bnez	s3,770 <vprintf+0x5c>
      if(c == '%'){
 786:	fd479ee3          	bne	a5,s4,762 <vprintf+0x4e>
        state = '%';
 78a:	89be                	mv	s3,a5
 78c:	b7e5                	j	774 <vprintf+0x60>
      if(c == 'd'){
 78e:	05878063          	beq	a5,s8,7ce <vprintf+0xba>
      } else if(c == 'l') {
 792:	05978c63          	beq	a5,s9,7ea <vprintf+0xd6>
      } else if(c == 'x') {
 796:	07a78863          	beq	a5,s10,806 <vprintf+0xf2>
      } else if(c == 'p') {
 79a:	09b78463          	beq	a5,s11,822 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 79e:	07300713          	li	a4,115
 7a2:	0ce78663          	beq	a5,a4,86e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 7a6:	06300713          	li	a4,99
 7aa:	0ee78e63          	beq	a5,a4,8a6 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 7ae:	11478863          	beq	a5,s4,8be <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 7b2:	85d2                	mv	a1,s4
 7b4:	8556                	mv	a0,s5
 7b6:	00000097          	auipc	ra,0x0
 7ba:	e92080e7          	jalr	-366(ra) # 648 <putc>
        putc(fd, c);
 7be:	85ca                	mv	a1,s2
 7c0:	8556                	mv	a0,s5
 7c2:	00000097          	auipc	ra,0x0
 7c6:	e86080e7          	jalr	-378(ra) # 648 <putc>
      }
      state = 0;
 7ca:	4981                	li	s3,0
 7cc:	b765                	j	774 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 7ce:	008b0913          	addi	s2,s6,8
 7d2:	4685                	li	a3,1
 7d4:	4629                	li	a2,10
 7d6:	000b2583          	lw	a1,0(s6)
 7da:	8556                	mv	a0,s5
 7dc:	00000097          	auipc	ra,0x0
 7e0:	e8e080e7          	jalr	-370(ra) # 66a <printint>
 7e4:	8b4a                	mv	s6,s2
      state = 0;
 7e6:	4981                	li	s3,0
 7e8:	b771                	j	774 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7ea:	008b0913          	addi	s2,s6,8
 7ee:	4681                	li	a3,0
 7f0:	4629                	li	a2,10
 7f2:	000b2583          	lw	a1,0(s6)
 7f6:	8556                	mv	a0,s5
 7f8:	00000097          	auipc	ra,0x0
 7fc:	e72080e7          	jalr	-398(ra) # 66a <printint>
 800:	8b4a                	mv	s6,s2
      state = 0;
 802:	4981                	li	s3,0
 804:	bf85                	j	774 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 806:	008b0913          	addi	s2,s6,8
 80a:	4681                	li	a3,0
 80c:	4641                	li	a2,16
 80e:	000b2583          	lw	a1,0(s6)
 812:	8556                	mv	a0,s5
 814:	00000097          	auipc	ra,0x0
 818:	e56080e7          	jalr	-426(ra) # 66a <printint>
 81c:	8b4a                	mv	s6,s2
      state = 0;
 81e:	4981                	li	s3,0
 820:	bf91                	j	774 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 822:	008b0793          	addi	a5,s6,8
 826:	f8f43423          	sd	a5,-120(s0)
 82a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 82e:	03000593          	li	a1,48
 832:	8556                	mv	a0,s5
 834:	00000097          	auipc	ra,0x0
 838:	e14080e7          	jalr	-492(ra) # 648 <putc>
  putc(fd, 'x');
 83c:	85ea                	mv	a1,s10
 83e:	8556                	mv	a0,s5
 840:	00000097          	auipc	ra,0x0
 844:	e08080e7          	jalr	-504(ra) # 648 <putc>
 848:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 84a:	03c9d793          	srli	a5,s3,0x3c
 84e:	97de                	add	a5,a5,s7
 850:	0007c583          	lbu	a1,0(a5)
 854:	8556                	mv	a0,s5
 856:	00000097          	auipc	ra,0x0
 85a:	df2080e7          	jalr	-526(ra) # 648 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 85e:	0992                	slli	s3,s3,0x4
 860:	397d                	addiw	s2,s2,-1
 862:	fe0914e3          	bnez	s2,84a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 866:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 86a:	4981                	li	s3,0
 86c:	b721                	j	774 <vprintf+0x60>
        s = va_arg(ap, char*);
 86e:	008b0993          	addi	s3,s6,8
 872:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 876:	02090163          	beqz	s2,898 <vprintf+0x184>
        while(*s != 0){
 87a:	00094583          	lbu	a1,0(s2)
 87e:	c9a1                	beqz	a1,8ce <vprintf+0x1ba>
          putc(fd, *s);
 880:	8556                	mv	a0,s5
 882:	00000097          	auipc	ra,0x0
 886:	dc6080e7          	jalr	-570(ra) # 648 <putc>
          s++;
 88a:	0905                	addi	s2,s2,1
        while(*s != 0){
 88c:	00094583          	lbu	a1,0(s2)
 890:	f9e5                	bnez	a1,880 <vprintf+0x16c>
        s = va_arg(ap, char*);
 892:	8b4e                	mv	s6,s3
      state = 0;
 894:	4981                	li	s3,0
 896:	bdf9                	j	774 <vprintf+0x60>
          s = "(null)";
 898:	00000917          	auipc	s2,0x0
 89c:	5c890913          	addi	s2,s2,1480 # e60 <ustack_free+0x2c8>
        while(*s != 0){
 8a0:	02800593          	li	a1,40
 8a4:	bff1                	j	880 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 8a6:	008b0913          	addi	s2,s6,8
 8aa:	000b4583          	lbu	a1,0(s6)
 8ae:	8556                	mv	a0,s5
 8b0:	00000097          	auipc	ra,0x0
 8b4:	d98080e7          	jalr	-616(ra) # 648 <putc>
 8b8:	8b4a                	mv	s6,s2
      state = 0;
 8ba:	4981                	li	s3,0
 8bc:	bd65                	j	774 <vprintf+0x60>
        putc(fd, c);
 8be:	85d2                	mv	a1,s4
 8c0:	8556                	mv	a0,s5
 8c2:	00000097          	auipc	ra,0x0
 8c6:	d86080e7          	jalr	-634(ra) # 648 <putc>
      state = 0;
 8ca:	4981                	li	s3,0
 8cc:	b565                	j	774 <vprintf+0x60>
        s = va_arg(ap, char*);
 8ce:	8b4e                	mv	s6,s3
      state = 0;
 8d0:	4981                	li	s3,0
 8d2:	b54d                	j	774 <vprintf+0x60>
    }
  }
}
 8d4:	70e6                	ld	ra,120(sp)
 8d6:	7446                	ld	s0,112(sp)
 8d8:	74a6                	ld	s1,104(sp)
 8da:	7906                	ld	s2,96(sp)
 8dc:	69e6                	ld	s3,88(sp)
 8de:	6a46                	ld	s4,80(sp)
 8e0:	6aa6                	ld	s5,72(sp)
 8e2:	6b06                	ld	s6,64(sp)
 8e4:	7be2                	ld	s7,56(sp)
 8e6:	7c42                	ld	s8,48(sp)
 8e8:	7ca2                	ld	s9,40(sp)
 8ea:	7d02                	ld	s10,32(sp)
 8ec:	6de2                	ld	s11,24(sp)
 8ee:	6109                	addi	sp,sp,128
 8f0:	8082                	ret

00000000000008f2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8f2:	715d                	addi	sp,sp,-80
 8f4:	ec06                	sd	ra,24(sp)
 8f6:	e822                	sd	s0,16(sp)
 8f8:	1000                	addi	s0,sp,32
 8fa:	e010                	sd	a2,0(s0)
 8fc:	e414                	sd	a3,8(s0)
 8fe:	e818                	sd	a4,16(s0)
 900:	ec1c                	sd	a5,24(s0)
 902:	03043023          	sd	a6,32(s0)
 906:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 90a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 90e:	8622                	mv	a2,s0
 910:	00000097          	auipc	ra,0x0
 914:	e04080e7          	jalr	-508(ra) # 714 <vprintf>
}
 918:	60e2                	ld	ra,24(sp)
 91a:	6442                	ld	s0,16(sp)
 91c:	6161                	addi	sp,sp,80
 91e:	8082                	ret

0000000000000920 <printf>:

void
printf(const char *fmt, ...)
{
 920:	711d                	addi	sp,sp,-96
 922:	ec06                	sd	ra,24(sp)
 924:	e822                	sd	s0,16(sp)
 926:	1000                	addi	s0,sp,32
 928:	e40c                	sd	a1,8(s0)
 92a:	e810                	sd	a2,16(s0)
 92c:	ec14                	sd	a3,24(s0)
 92e:	f018                	sd	a4,32(s0)
 930:	f41c                	sd	a5,40(s0)
 932:	03043823          	sd	a6,48(s0)
 936:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 93a:	00840613          	addi	a2,s0,8
 93e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 942:	85aa                	mv	a1,a0
 944:	4505                	li	a0,1
 946:	00000097          	auipc	ra,0x0
 94a:	dce080e7          	jalr	-562(ra) # 714 <vprintf>
}
 94e:	60e2                	ld	ra,24(sp)
 950:	6442                	ld	s0,16(sp)
 952:	6125                	addi	sp,sp,96
 954:	8082                	ret

0000000000000956 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 956:	1141                	addi	sp,sp,-16
 958:	e422                	sd	s0,8(sp)
 95a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 95c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 960:	00000797          	auipc	a5,0x0
 964:	6a07b783          	ld	a5,1696(a5) # 1000 <freep>
 968:	a805                	j	998 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 96a:	4618                	lw	a4,8(a2)
 96c:	9db9                	addw	a1,a1,a4
 96e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 972:	6398                	ld	a4,0(a5)
 974:	6318                	ld	a4,0(a4)
 976:	fee53823          	sd	a4,-16(a0)
 97a:	a091                	j	9be <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 97c:	ff852703          	lw	a4,-8(a0)
 980:	9e39                	addw	a2,a2,a4
 982:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 984:	ff053703          	ld	a4,-16(a0)
 988:	e398                	sd	a4,0(a5)
 98a:	a099                	j	9d0 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 98c:	6398                	ld	a4,0(a5)
 98e:	00e7e463          	bltu	a5,a4,996 <free+0x40>
 992:	00e6ea63          	bltu	a3,a4,9a6 <free+0x50>
{
 996:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 998:	fed7fae3          	bgeu	a5,a3,98c <free+0x36>
 99c:	6398                	ld	a4,0(a5)
 99e:	00e6e463          	bltu	a3,a4,9a6 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9a2:	fee7eae3          	bltu	a5,a4,996 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 9a6:	ff852583          	lw	a1,-8(a0)
 9aa:	6390                	ld	a2,0(a5)
 9ac:	02059713          	slli	a4,a1,0x20
 9b0:	9301                	srli	a4,a4,0x20
 9b2:	0712                	slli	a4,a4,0x4
 9b4:	9736                	add	a4,a4,a3
 9b6:	fae60ae3          	beq	a2,a4,96a <free+0x14>
    bp->s.ptr = p->s.ptr;
 9ba:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 9be:	4790                	lw	a2,8(a5)
 9c0:	02061713          	slli	a4,a2,0x20
 9c4:	9301                	srli	a4,a4,0x20
 9c6:	0712                	slli	a4,a4,0x4
 9c8:	973e                	add	a4,a4,a5
 9ca:	fae689e3          	beq	a3,a4,97c <free+0x26>
  } else
    p->s.ptr = bp;
 9ce:	e394                	sd	a3,0(a5)
  freep = p;
 9d0:	00000717          	auipc	a4,0x0
 9d4:	62f73823          	sd	a5,1584(a4) # 1000 <freep>
}
 9d8:	6422                	ld	s0,8(sp)
 9da:	0141                	addi	sp,sp,16
 9dc:	8082                	ret

00000000000009de <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9de:	7139                	addi	sp,sp,-64
 9e0:	fc06                	sd	ra,56(sp)
 9e2:	f822                	sd	s0,48(sp)
 9e4:	f426                	sd	s1,40(sp)
 9e6:	f04a                	sd	s2,32(sp)
 9e8:	ec4e                	sd	s3,24(sp)
 9ea:	e852                	sd	s4,16(sp)
 9ec:	e456                	sd	s5,8(sp)
 9ee:	e05a                	sd	s6,0(sp)
 9f0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9f2:	02051493          	slli	s1,a0,0x20
 9f6:	9081                	srli	s1,s1,0x20
 9f8:	04bd                	addi	s1,s1,15
 9fa:	8091                	srli	s1,s1,0x4
 9fc:	0014899b          	addiw	s3,s1,1
 a00:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 a02:	00000517          	auipc	a0,0x0
 a06:	5fe53503          	ld	a0,1534(a0) # 1000 <freep>
 a0a:	c515                	beqz	a0,a36 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a0c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a0e:	4798                	lw	a4,8(a5)
 a10:	02977f63          	bgeu	a4,s1,a4e <malloc+0x70>
 a14:	8a4e                	mv	s4,s3
 a16:	0009871b          	sext.w	a4,s3
 a1a:	6685                	lui	a3,0x1
 a1c:	00d77363          	bgeu	a4,a3,a22 <malloc+0x44>
 a20:	6a05                	lui	s4,0x1
 a22:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a26:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a2a:	00000917          	auipc	s2,0x0
 a2e:	5d690913          	addi	s2,s2,1494 # 1000 <freep>
  if(p == (char*)-1)
 a32:	5afd                	li	s5,-1
 a34:	a88d                	j	aa6 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 a36:	00000797          	auipc	a5,0x0
 a3a:	5da78793          	addi	a5,a5,1498 # 1010 <base>
 a3e:	00000717          	auipc	a4,0x0
 a42:	5cf73123          	sd	a5,1474(a4) # 1000 <freep>
 a46:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a48:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a4c:	b7e1                	j	a14 <malloc+0x36>
      if(p->s.size == nunits)
 a4e:	02e48b63          	beq	s1,a4,a84 <malloc+0xa6>
        p->s.size -= nunits;
 a52:	4137073b          	subw	a4,a4,s3
 a56:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a58:	1702                	slli	a4,a4,0x20
 a5a:	9301                	srli	a4,a4,0x20
 a5c:	0712                	slli	a4,a4,0x4
 a5e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a60:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a64:	00000717          	auipc	a4,0x0
 a68:	58a73e23          	sd	a0,1436(a4) # 1000 <freep>
      return (void*)(p + 1);
 a6c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a70:	70e2                	ld	ra,56(sp)
 a72:	7442                	ld	s0,48(sp)
 a74:	74a2                	ld	s1,40(sp)
 a76:	7902                	ld	s2,32(sp)
 a78:	69e2                	ld	s3,24(sp)
 a7a:	6a42                	ld	s4,16(sp)
 a7c:	6aa2                	ld	s5,8(sp)
 a7e:	6b02                	ld	s6,0(sp)
 a80:	6121                	addi	sp,sp,64
 a82:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a84:	6398                	ld	a4,0(a5)
 a86:	e118                	sd	a4,0(a0)
 a88:	bff1                	j	a64 <malloc+0x86>
  hp->s.size = nu;
 a8a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a8e:	0541                	addi	a0,a0,16
 a90:	00000097          	auipc	ra,0x0
 a94:	ec6080e7          	jalr	-314(ra) # 956 <free>
  return freep;
 a98:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a9c:	d971                	beqz	a0,a70 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a9e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 aa0:	4798                	lw	a4,8(a5)
 aa2:	fa9776e3          	bgeu	a4,s1,a4e <malloc+0x70>
    if(p == freep)
 aa6:	00093703          	ld	a4,0(s2)
 aaa:	853e                	mv	a0,a5
 aac:	fef719e3          	bne	a4,a5,a9e <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 ab0:	8552                	mv	a0,s4
 ab2:	00000097          	auipc	ra,0x0
 ab6:	b7e080e7          	jalr	-1154(ra) # 630 <sbrk>
  if(p == (char*)-1)
 aba:	fd5518e3          	bne	a0,s5,a8a <malloc+0xac>
        return 0;
 abe:	4501                	li	a0,0
 ac0:	bf45                	j	a70 <malloc+0x92>

0000000000000ac2 <ustack_malloc>:

struct ustack *head = 0;

void* ustack_malloc(uint len){

    if(len > 512) //valid
 ac2:	20000793          	li	a5,512
 ac6:	0ca7e763          	bltu	a5,a0,b94 <ustack_malloc+0xd2>
void* ustack_malloc(uint len){
 aca:	1101                	addi	sp,sp,-32
 acc:	ec06                	sd	ra,24(sp)
 ace:	e822                	sd	s0,16(sp)
 ad0:	e426                	sd	s1,8(sp)
 ad2:	1000                	addi	s0,sp,32
 ad4:	84aa                	mv	s1,a0
        return (void*)-1;
    uint64 address;
    if(head == 0){
 ad6:	00000797          	auipc	a5,0x0
 ada:	5327b783          	ld	a5,1330(a5) # 1008 <head>
 ade:	c7b1                	beqz	a5,b2a <ustack_malloc+0x68>
        head->pa = 4096 - sizeof(struct ustack) - len;
        head->prev = 0;
    }else {
        struct ustack next;

        if(len + sizeof(struct ustack) > head->pa){
 ae0:	43d8                	lw	a4,4(a5)
 ae2:	02051693          	slli	a3,a0,0x20
 ae6:	9281                	srli	a3,a3,0x20
 ae8:	06c1                	addi	a3,a3,16
 aea:	02071613          	slli	a2,a4,0x20
 aee:	9201                	srli	a2,a2,0x20
 af0:	06d66563          	bltu	a2,a3,b5a <ustack_malloc+0x98>
        else{

            next.len = len;
            next.pa = head->pa - len - sizeof(struct ustack);
            next.prev = head;
            head = (struct ustack*)(head->len + sizeof(struct ustack)+(uint64)head);
 af4:	0007e683          	lwu	a3,0(a5)
 af8:	01078613          	addi	a2,a5,16
 afc:	96b2                	add	a3,a3,a2
 afe:	00000617          	auipc	a2,0x0
 b02:	50a60613          	addi	a2,a2,1290 # 1008 <head>
 b06:	e214                	sd	a3,0(a2)
            next.pa = head->pa - len - sizeof(struct ustack);
 b08:	3741                	addiw	a4,a4,-16
 b0a:	9f09                	subw	a4,a4,a0
            head->pa = next.pa;
 b0c:	c2d8                	sw	a4,4(a3)
            head->len = len;
 b0e:	6218                	ld	a4,0(a2)
 b10:	c308                	sw	a0,0(a4)
            head->prev = next.prev;
 b12:	6218                	ld	a4,0(a2)
 b14:	e71c                	sd	a5,8(a4)
        }
    }
    return (void*)head + sizeof(struct ustack);
 b16:	00000517          	auipc	a0,0x0
 b1a:	4f253503          	ld	a0,1266(a0) # 1008 <head>
 b1e:	0541                	addi	a0,a0,16
}
 b20:	60e2                	ld	ra,24(sp)
 b22:	6442                	ld	s0,16(sp)
 b24:	64a2                	ld	s1,8(sp)
 b26:	6105                	addi	sp,sp,32
 b28:	8082                	ret
        address = (uint64)sbrk(4096);
 b2a:	6505                	lui	a0,0x1
 b2c:	00000097          	auipc	ra,0x0
 b30:	b04080e7          	jalr	-1276(ra) # 630 <sbrk>
        if(address == -1)//valid
 b34:	57fd                	li	a5,-1
 b36:	fef505e3          	beq	a0,a5,b20 <ustack_malloc+0x5e>
        head = (struct ustack*) address;
 b3a:	00000797          	auipc	a5,0x0
 b3e:	4ce78793          	addi	a5,a5,1230 # 1008 <head>
 b42:	e388                	sd	a0,0(a5)
        head->len = len;
 b44:	c104                	sw	s1,0(a0)
        head->pa = 4096 - sizeof(struct ustack) - len;
 b46:	6398                	ld	a4,0(a5)
 b48:	6505                	lui	a0,0x1
 b4a:	3541                	addiw	a0,a0,-16
 b4c:	409504bb          	subw	s1,a0,s1
 b50:	c344                	sw	s1,4(a4)
        head->prev = 0;
 b52:	639c                	ld	a5,0(a5)
 b54:	0007b423          	sd	zero,8(a5)
 b58:	bf7d                	j	b16 <ustack_malloc+0x54>
            address = (uint64)sbrk(4096);
 b5a:	6505                	lui	a0,0x1
 b5c:	00000097          	auipc	ra,0x0
 b60:	ad4080e7          	jalr	-1324(ra) # 630 <sbrk>
            if(address == -1)//valid
 b64:	57fd                	li	a5,-1
 b66:	faf50de3          	beq	a0,a5,b20 <ustack_malloc+0x5e>
            next.pa = 4096-sizeof(struct ustack) - (len - head->pa);
 b6a:	00000617          	auipc	a2,0x0
 b6e:	49e60613          	addi	a2,a2,1182 # 1008 <head>
 b72:	6218                	ld	a4,0(a2)
 b74:	435c                	lw	a5,4(a4)
 b76:	6685                	lui	a3,0x1
 b78:	36c1                	addiw	a3,a3,-16
 b7a:	9fb5                	addw	a5,a5,a3
 b7c:	9f85                	subw	a5,a5,s1
            head = (struct ustack*)((uint64)head + sizeof(struct ustack) + head->len );
 b7e:	00076683          	lwu	a3,0(a4)
 b82:	01070593          	addi	a1,a4,16
 b86:	96ae                	add	a3,a3,a1
 b88:	e214                	sd	a3,0(a2)
            head->pa = next.pa;
 b8a:	c2dc                	sw	a5,4(a3)
            head->prev = next.prev;
 b8c:	621c                	ld	a5,0(a2)
 b8e:	e798                	sd	a4,8(a5)
            head->len = len;
 b90:	c384                	sw	s1,0(a5)
 b92:	b751                	j	b16 <ustack_malloc+0x54>
        return (void*)-1;
 b94:	557d                	li	a0,-1
}
 b96:	8082                	ret

0000000000000b98 <ustack_free>:

int ustack_free(void){
    struct ustack* newHead;
    if(head == 0){
 b98:	00000797          	auipc	a5,0x0
 b9c:	4707b783          	ld	a5,1136(a5) # 1008 <head>
 ba0:	cbad                	beqz	a5,c12 <ustack_free+0x7a>
int ustack_free(void){
 ba2:	1101                	addi	sp,sp,-32
 ba4:	ec06                	sd	ra,24(sp)
 ba6:	e822                	sd	s0,16(sp)
 ba8:	e426                	sd	s1,8(sp)
 baa:	e04a                	sd	s2,0(sp)
 bac:	1000                	addi	s0,sp,32
        return -1;
    }
    uint len = head->len;
 bae:	4384                	lw	s1,0(a5)
    newHead = head->prev;
 bb0:	0087b903          	ld	s2,8(a5)
    if(head->prev == 0)
 bb4:	02090d63          	beqz	s2,bee <ustack_free+0x56>
        sbrk(-4096);

    else if(PGROUNDDOWN((uint64)head) == (uint64)head)
 bb8:	03479713          	slli	a4,a5,0x34
 bbc:	cf1d                	beqz	a4,bfa <ustack_free+0x62>
        sbrk(-4096);

    else if(PGROUNDUP((uint64)head) < (uint64)head + sizeof(struct ustack) + head->len)
 bbe:	6705                	lui	a4,0x1
 bc0:	177d                	addi	a4,a4,-1
 bc2:	973e                	add	a4,a4,a5
 bc4:	76fd                	lui	a3,0xfffff
 bc6:	8f75                	and	a4,a4,a3
 bc8:	07c1                	addi	a5,a5,16
 bca:	02049693          	slli	a3,s1,0x20
 bce:	9281                	srli	a3,a3,0x20
 bd0:	97b6                	add	a5,a5,a3
 bd2:	02f76a63          	bltu	a4,a5,c06 <ustack_free+0x6e>
        sbrk(-PGSIZE);

    head = newHead;
 bd6:	00000797          	auipc	a5,0x0
 bda:	4327b923          	sd	s2,1074(a5) # 1008 <head>
    return len;    
 bde:	0004851b          	sext.w	a0,s1
 be2:	60e2                	ld	ra,24(sp)
 be4:	6442                	ld	s0,16(sp)
 be6:	64a2                	ld	s1,8(sp)
 be8:	6902                	ld	s2,0(sp)
 bea:	6105                	addi	sp,sp,32
 bec:	8082                	ret
        sbrk(-4096);
 bee:	757d                	lui	a0,0xfffff
 bf0:	00000097          	auipc	ra,0x0
 bf4:	a40080e7          	jalr	-1472(ra) # 630 <sbrk>
 bf8:	bff9                	j	bd6 <ustack_free+0x3e>
        sbrk(-4096);
 bfa:	757d                	lui	a0,0xfffff
 bfc:	00000097          	auipc	ra,0x0
 c00:	a34080e7          	jalr	-1484(ra) # 630 <sbrk>
 c04:	bfc9                	j	bd6 <ustack_free+0x3e>
        sbrk(-PGSIZE);
 c06:	757d                	lui	a0,0xfffff
 c08:	00000097          	auipc	ra,0x0
 c0c:	a28080e7          	jalr	-1496(ra) # 630 <sbrk>
 c10:	b7d9                	j	bd6 <ustack_free+0x3e>
        return -1;
 c12:	557d                	li	a0,-1
 c14:	8082                	ret
