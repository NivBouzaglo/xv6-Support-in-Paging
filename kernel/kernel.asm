
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	91013103          	ld	sp,-1776(sp) # 80008910 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	91e70713          	addi	a4,a4,-1762 # 80008970 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	60c78793          	addi	a5,a5,1548 # 80006670 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffcc41f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	938080e7          	jalr	-1736(ra) # 80002a64 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	92650513          	addi	a0,a0,-1754 # 80010ab0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	91648493          	addi	s1,s1,-1770 # 80010ab0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	9a690913          	addi	s2,s2,-1626 # 80010b48 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	d68080e7          	jalr	-664(ra) # 80001f28 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	6e6080e7          	jalr	1766(ra) # 800028ae <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	41a080e7          	jalr	1050(ra) # 800025f0 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	7fc080e7          	jalr	2044(ra) # 80002a0e <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	88a50513          	addi	a0,a0,-1910 # 80010ab0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	87450513          	addi	a0,a0,-1932 # 80010ab0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8cf72b23          	sw	a5,-1834(a4) # 80010b48 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7e450513          	addi	a0,a0,2020 # 80010ab0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	7c8080e7          	jalr	1992(ra) # 80002aba <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7b650513          	addi	a0,a0,1974 # 80010ab0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	79270713          	addi	a4,a4,1938 # 80010ab0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	76878793          	addi	a5,a5,1896 # 80010ab0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7d27a783          	lw	a5,2002(a5) # 80010b48 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	72670713          	addi	a4,a4,1830 # 80010ab0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	71648493          	addi	s1,s1,1814 # 80010ab0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6da70713          	addi	a4,a4,1754 # 80010ab0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	76f72223          	sw	a5,1892(a4) # 80010b50 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	69e78793          	addi	a5,a5,1694 # 80010ab0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	70c7ab23          	sw	a2,1814(a5) # 80010b4c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	70a50513          	addi	a0,a0,1802 # 80010b48 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	20e080e7          	jalr	526(ra) # 80002654 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	65050513          	addi	a0,a0,1616 # 80010ab0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00031797          	auipc	a5,0x31
    8000047c:	dd078793          	addi	a5,a5,-560 # 80031248 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	6207a323          	sw	zero,1574(a5) # 80010b70 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	3af72923          	sw	a5,946(a4) # 80008930 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	5b6dad83          	lw	s11,1462(s11) # 80010b70 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	56050513          	addi	a0,a0,1376 # 80010b58 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	40250513          	addi	a0,a0,1026 # 80010b58 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	3e648493          	addi	s1,s1,998 # 80010b58 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	3a650513          	addi	a0,a0,934 # 80010b78 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	1327a783          	lw	a5,306(a5) # 80008930 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	1027b783          	ld	a5,258(a5) # 80008938 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	10273703          	ld	a4,258(a4) # 80008940 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	318a0a13          	addi	s4,s4,792 # 80010b78 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	0d048493          	addi	s1,s1,208 # 80008938 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	0d098993          	addi	s3,s3,208 # 80008940 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	dc2080e7          	jalr	-574(ra) # 80002654 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	2aa50513          	addi	a0,a0,682 # 80010b78 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0527a783          	lw	a5,82(a5) # 80008930 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	05873703          	ld	a4,88(a4) # 80008940 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	0487b783          	ld	a5,72(a5) # 80008938 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	27c98993          	addi	s3,s3,636 # 80010b78 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	03448493          	addi	s1,s1,52 # 80008938 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	03490913          	addi	s2,s2,52 # 80008940 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	cd4080e7          	jalr	-812(ra) # 800025f0 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	24648493          	addi	s1,s1,582 # 80010b78 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	fee7bd23          	sd	a4,-6(a5) # 80008940 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	1bc48493          	addi	s1,s1,444 # 80010b78 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00032797          	auipc	a5,0x32
    80000a02:	9e278793          	addi	a5,a5,-1566 # 800323e0 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	19290913          	addi	s2,s2,402 # 80010bb0 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0f650513          	addi	a0,a0,246 # 80010bb0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00032517          	auipc	a0,0x32
    80000ad2:	91250513          	addi	a0,a0,-1774 # 800323e0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	0c048493          	addi	s1,s1,192 # 80010bb0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	0a850513          	addi	a0,a0,168 # 80010bb0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	07c50513          	addi	a0,a0,124 # 80010bb0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	39c080e7          	jalr	924(ra) # 80001f0c <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	36a080e7          	jalr	874(ra) # 80001f0c <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	35e080e7          	jalr	862(ra) # 80001f0c <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	346080e7          	jalr	838(ra) # 80001f0c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	306080e7          	jalr	774(ra) # 80001f0c <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	2da080e7          	jalr	730(ra) # 80001f0c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	07c080e7          	jalr	124(ra) # 80001efc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	ac070713          	addi	a4,a4,-1344 # 80008948 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	060080e7          	jalr	96(ra) # 80001efc <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	d3c080e7          	jalr	-708(ra) # 80002bfa <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	7ea080e7          	jalr	2026(ra) # 800066b0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	570080e7          	jalr	1392(ra) # 8000243e <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	f1a080e7          	jalr	-230(ra) # 80001e48 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	c9c080e7          	jalr	-868(ra) # 80002bd2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	cbc080e7          	jalr	-836(ra) # 80002bfa <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	754080e7          	jalr	1876(ra) # 8000669a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	762080e7          	jalr	1890(ra) # 800066b0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	3e0080e7          	jalr	992(ra) # 80003336 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	a84080e7          	jalr	-1404(ra) # 800039e2 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	d34080e7          	jalr	-716(ra) # 80004c9a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00006097          	auipc	ra,0x6
    80000f72:	84a080e7          	jalr	-1974(ra) # 800067b8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	2aa080e7          	jalr	682(ra) # 80002220 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	9cf72223          	sw	a5,-1596(a4) # 80008948 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9b87b783          	ld	a5,-1608(a5) # 80008950 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00001097          	auipc	ra,0x1
    80001232:	b84080e7          	jalr	-1148(ra) # 80001db2 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6ea7be23          	sd	a0,1788(a5) # 80008950 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8bb6                	mv	s7,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if(((*pte & PTE_V) == 0) && ((*pte & PTE_PG) == 0))
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b05                	li	s6,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6a85                	lui	s5,0x1
    80001290:	0735e963          	bltu	a1,s3,80001302 <uvmunmap+0x9e>
      }
    } 
    #endif
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012ea:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800012ec:	00c79513          	slli	a0,a5,0xc
    800012f0:	fffff097          	auipc	ra,0xfffff
    800012f4:	6fa080e7          	jalr	1786(ra) # 800009ea <kfree>
    *pte = 0;
    800012f8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fc:	9956                	add	s2,s2,s5
    800012fe:	f9397be3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001302:	4601                	li	a2,0
    80001304:	85ca                	mv	a1,s2
    80001306:	8552                	mv	a0,s4
    80001308:	00000097          	auipc	ra,0x0
    8000130c:	cae080e7          	jalr	-850(ra) # 80000fb6 <walk>
    80001310:	84aa                	mv	s1,a0
    80001312:	d545                	beqz	a0,800012ba <uvmunmap+0x56>
    if(((*pte & PTE_V) == 0) && ((*pte & PTE_PG) == 0))
    80001314:	611c                	ld	a5,0(a0)
    80001316:	2017f713          	andi	a4,a5,513
    8000131a:	db45                	beqz	a4,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000131c:	3ff7f713          	andi	a4,a5,1023
    80001320:	fb670de3          	beq	a4,s6,800012da <uvmunmap+0x76>
    if((*pte & PTE_V) && do_free){
    80001324:	0017f713          	andi	a4,a5,1
    80001328:	db61                	beqz	a4,800012f8 <uvmunmap+0x94>
    8000132a:	fc0b87e3          	beqz	s7,800012f8 <uvmunmap+0x94>
    8000132e:	bf75                	j	800012ea <uvmunmap+0x86>

0000000080001330 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001330:	1101                	addi	sp,sp,-32
    80001332:	ec06                	sd	ra,24(sp)
    80001334:	e822                	sd	s0,16(sp)
    80001336:	e426                	sd	s1,8(sp)
    80001338:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	7ac080e7          	jalr	1964(ra) # 80000ae6 <kalloc>
    80001342:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001344:	c519                	beqz	a0,80001352 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001346:	6605                	lui	a2,0x1
    80001348:	4581                	li	a1,0
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	988080e7          	jalr	-1656(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001352:	8526                	mv	a0,s1
    80001354:	60e2                	ld	ra,24(sp)
    80001356:	6442                	ld	s0,16(sp)
    80001358:	64a2                	ld	s1,8(sp)
    8000135a:	6105                	addi	sp,sp,32
    8000135c:	8082                	ret

000000008000135e <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000135e:	7179                	addi	sp,sp,-48
    80001360:	f406                	sd	ra,40(sp)
    80001362:	f022                	sd	s0,32(sp)
    80001364:	ec26                	sd	s1,24(sp)
    80001366:	e84a                	sd	s2,16(sp)
    80001368:	e44e                	sd	s3,8(sp)
    8000136a:	e052                	sd	s4,0(sp)
    8000136c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000136e:	6785                	lui	a5,0x1
    80001370:	04f67863          	bgeu	a2,a5,800013c0 <uvmfirst+0x62>
    80001374:	8a2a                	mv	s4,a0
    80001376:	89ae                	mv	s3,a1
    80001378:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	76c080e7          	jalr	1900(ra) # 80000ae6 <kalloc>
    80001382:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001384:	6605                	lui	a2,0x1
    80001386:	4581                	li	a1,0
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	94a080e7          	jalr	-1718(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001390:	4779                	li	a4,30
    80001392:	86ca                	mv	a3,s2
    80001394:	6605                	lui	a2,0x1
    80001396:	4581                	li	a1,0
    80001398:	8552                	mv	a0,s4
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	d04080e7          	jalr	-764(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    800013a2:	8626                	mv	a2,s1
    800013a4:	85ce                	mv	a1,s3
    800013a6:	854a                	mv	a0,s2
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	986080e7          	jalr	-1658(ra) # 80000d2e <memmove>
}
    800013b0:	70a2                	ld	ra,40(sp)
    800013b2:	7402                	ld	s0,32(sp)
    800013b4:	64e2                	ld	s1,24(sp)
    800013b6:	6942                	ld	s2,16(sp)
    800013b8:	69a2                	ld	s3,8(sp)
    800013ba:	6a02                	ld	s4,0(sp)
    800013bc:	6145                	addi	sp,sp,48
    800013be:	8082                	ret
    panic("uvmfirst: more than a page");
    800013c0:	00007517          	auipc	a0,0x7
    800013c4:	d9850513          	addi	a0,a0,-616 # 80008158 <digits+0x118>
    800013c8:	fffff097          	auipc	ra,0xfffff
    800013cc:	176080e7          	jalr	374(ra) # 8000053e <panic>

00000000800013d0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013d0:	1101                	addi	sp,sp,-32
    800013d2:	ec06                	sd	ra,24(sp)
    800013d4:	e822                	sd	s0,16(sp)
    800013d6:	e426                	sd	s1,8(sp)
    800013d8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013da:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013dc:	00b67d63          	bgeu	a2,a1,800013f6 <uvmdealloc+0x26>
    800013e0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013e2:	6785                	lui	a5,0x1
    800013e4:	17fd                	addi	a5,a5,-1
    800013e6:	00f60733          	add	a4,a2,a5
    800013ea:	767d                	lui	a2,0xfffff
    800013ec:	8f71                	and	a4,a4,a2
    800013ee:	97ae                	add	a5,a5,a1
    800013f0:	8ff1                	and	a5,a5,a2
    800013f2:	00f76863          	bltu	a4,a5,80001402 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013f6:	8526                	mv	a0,s1
    800013f8:	60e2                	ld	ra,24(sp)
    800013fa:	6442                	ld	s0,16(sp)
    800013fc:	64a2                	ld	s1,8(sp)
    800013fe:	6105                	addi	sp,sp,32
    80001400:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001402:	8f99                	sub	a5,a5,a4
    80001404:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001406:	4685                	li	a3,1
    80001408:	0007861b          	sext.w	a2,a5
    8000140c:	85ba                	mv	a1,a4
    8000140e:	00000097          	auipc	ra,0x0
    80001412:	e56080e7          	jalr	-426(ra) # 80001264 <uvmunmap>
    80001416:	b7c5                	j	800013f6 <uvmdealloc+0x26>

0000000080001418 <uvmalloc>:
  if(newsz < oldsz)
    80001418:	0ab66563          	bltu	a2,a1,800014c2 <uvmalloc+0xaa>
{
    8000141c:	7139                	addi	sp,sp,-64
    8000141e:	fc06                	sd	ra,56(sp)
    80001420:	f822                	sd	s0,48(sp)
    80001422:	f426                	sd	s1,40(sp)
    80001424:	f04a                	sd	s2,32(sp)
    80001426:	ec4e                	sd	s3,24(sp)
    80001428:	e852                	sd	s4,16(sp)
    8000142a:	e456                	sd	s5,8(sp)
    8000142c:	e05a                	sd	s6,0(sp)
    8000142e:	0080                	addi	s0,sp,64
    80001430:	8aaa                	mv	s5,a0
    80001432:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001434:	6985                	lui	s3,0x1
    80001436:	19fd                	addi	s3,s3,-1
    80001438:	95ce                	add	a1,a1,s3
    8000143a:	79fd                	lui	s3,0xfffff
    8000143c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001440:	08c9f363          	bgeu	s3,a2,800014c6 <uvmalloc+0xae>
    80001444:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001446:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	69c080e7          	jalr	1692(ra) # 80000ae6 <kalloc>
    80001452:	84aa                	mv	s1,a0
    if(mem == 0){
    80001454:	c51d                	beqz	a0,80001482 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001456:	6605                	lui	a2,0x1
    80001458:	4581                	li	a1,0
    8000145a:	00000097          	auipc	ra,0x0
    8000145e:	878080e7          	jalr	-1928(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001462:	875a                	mv	a4,s6
    80001464:	86a6                	mv	a3,s1
    80001466:	6605                	lui	a2,0x1
    80001468:	85ca                	mv	a1,s2
    8000146a:	8556                	mv	a0,s5
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	c32080e7          	jalr	-974(ra) # 8000109e <mappages>
    80001474:	e90d                	bnez	a0,800014a6 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001476:	6785                	lui	a5,0x1
    80001478:	993e                	add	s2,s2,a5
    8000147a:	fd4968e3          	bltu	s2,s4,8000144a <uvmalloc+0x32>
  return newsz;
    8000147e:	8552                	mv	a0,s4
    80001480:	a809                	j	80001492 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001482:	864e                	mv	a2,s3
    80001484:	85ca                	mv	a1,s2
    80001486:	8556                	mv	a0,s5
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	f48080e7          	jalr	-184(ra) # 800013d0 <uvmdealloc>
      return 0;
    80001490:	4501                	li	a0,0
}
    80001492:	70e2                	ld	ra,56(sp)
    80001494:	7442                	ld	s0,48(sp)
    80001496:	74a2                	ld	s1,40(sp)
    80001498:	7902                	ld	s2,32(sp)
    8000149a:	69e2                	ld	s3,24(sp)
    8000149c:	6a42                	ld	s4,16(sp)
    8000149e:	6aa2                	ld	s5,8(sp)
    800014a0:	6b02                	ld	s6,0(sp)
    800014a2:	6121                	addi	sp,sp,64
    800014a4:	8082                	ret
      kfree(mem);
    800014a6:	8526                	mv	a0,s1
    800014a8:	fffff097          	auipc	ra,0xfffff
    800014ac:	542080e7          	jalr	1346(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b0:	864e                	mv	a2,s3
    800014b2:	85ca                	mv	a1,s2
    800014b4:	8556                	mv	a0,s5
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	f1a080e7          	jalr	-230(ra) # 800013d0 <uvmdealloc>
      return 0;
    800014be:	4501                	li	a0,0
    800014c0:	bfc9                	j	80001492 <uvmalloc+0x7a>
    return oldsz;
    800014c2:	852e                	mv	a0,a1
}
    800014c4:	8082                	ret
  return newsz;
    800014c6:	8532                	mv	a0,a2
    800014c8:	b7e9                	j	80001492 <uvmalloc+0x7a>

00000000800014ca <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014ca:	7179                	addi	sp,sp,-48
    800014cc:	f406                	sd	ra,40(sp)
    800014ce:	f022                	sd	s0,32(sp)
    800014d0:	ec26                	sd	s1,24(sp)
    800014d2:	e84a                	sd	s2,16(sp)
    800014d4:	e44e                	sd	s3,8(sp)
    800014d6:	e052                	sd	s4,0(sp)
    800014d8:	1800                	addi	s0,sp,48
    800014da:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014dc:	84aa                	mv	s1,a0
    800014de:	6905                	lui	s2,0x1
    800014e0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e2:	4985                	li	s3,1
    800014e4:	a821                	j	800014fc <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e8:	0532                	slli	a0,a0,0xc
    800014ea:	00000097          	auipc	ra,0x0
    800014ee:	fe0080e7          	jalr	-32(ra) # 800014ca <freewalk>
      pagetable[i] = 0;
    800014f2:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f6:	04a1                	addi	s1,s1,8
    800014f8:	03248163          	beq	s1,s2,8000151a <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fc:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014fe:	00f57793          	andi	a5,a0,15
    80001502:	ff3782e3          	beq	a5,s3,800014e6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001506:	8905                	andi	a0,a0,1
    80001508:	d57d                	beqz	a0,800014f6 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150a:	00007517          	auipc	a0,0x7
    8000150e:	c6e50513          	addi	a0,a0,-914 # 80008178 <digits+0x138>
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	02c080e7          	jalr	44(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151a:	8552                	mv	a0,s4
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	4ce080e7          	jalr	1230(ra) # 800009ea <kfree>
}
    80001524:	70a2                	ld	ra,40(sp)
    80001526:	7402                	ld	s0,32(sp)
    80001528:	64e2                	ld	s1,24(sp)
    8000152a:	6942                	ld	s2,16(sp)
    8000152c:	69a2                	ld	s3,8(sp)
    8000152e:	6a02                	ld	s4,0(sp)
    80001530:	6145                	addi	sp,sp,48
    80001532:	8082                	ret

0000000080001534 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001534:	1101                	addi	sp,sp,-32
    80001536:	ec06                	sd	ra,24(sp)
    80001538:	e822                	sd	s0,16(sp)
    8000153a:	e426                	sd	s1,8(sp)
    8000153c:	1000                	addi	s0,sp,32
    8000153e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001540:	e999                	bnez	a1,80001556 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001542:	8526                	mv	a0,s1
    80001544:	00000097          	auipc	ra,0x0
    80001548:	f86080e7          	jalr	-122(ra) # 800014ca <freewalk>
}
    8000154c:	60e2                	ld	ra,24(sp)
    8000154e:	6442                	ld	s0,16(sp)
    80001550:	64a2                	ld	s1,8(sp)
    80001552:	6105                	addi	sp,sp,32
    80001554:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001556:	6605                	lui	a2,0x1
    80001558:	167d                	addi	a2,a2,-1
    8000155a:	962e                	add	a2,a2,a1
    8000155c:	4685                	li	a3,1
    8000155e:	8231                	srli	a2,a2,0xc
    80001560:	4581                	li	a1,0
    80001562:	00000097          	auipc	ra,0x0
    80001566:	d02080e7          	jalr	-766(ra) # 80001264 <uvmunmap>
    8000156a:	bfe1                	j	80001542 <uvmfree+0xe>

000000008000156c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156c:	c679                	beqz	a2,8000163a <uvmcopy+0xce>
{
    8000156e:	715d                	addi	sp,sp,-80
    80001570:	e486                	sd	ra,72(sp)
    80001572:	e0a2                	sd	s0,64(sp)
    80001574:	fc26                	sd	s1,56(sp)
    80001576:	f84a                	sd	s2,48(sp)
    80001578:	f44e                	sd	s3,40(sp)
    8000157a:	f052                	sd	s4,32(sp)
    8000157c:	ec56                	sd	s5,24(sp)
    8000157e:	e85a                	sd	s6,16(sp)
    80001580:	e45e                	sd	s7,8(sp)
    80001582:	0880                	addi	s0,sp,80
    80001584:	8b2a                	mv	s6,a0
    80001586:	8aae                	mv	s5,a1
    80001588:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158c:	4601                	li	a2,0
    8000158e:	85ce                	mv	a1,s3
    80001590:	855a                	mv	a0,s6
    80001592:	00000097          	auipc	ra,0x0
    80001596:	a24080e7          	jalr	-1500(ra) # 80000fb6 <walk>
    8000159a:	c531                	beqz	a0,800015e6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0 && (*pte & PTE_PG) == 0)
    8000159c:	6118                	ld	a4,0(a0)
    8000159e:	20177793          	andi	a5,a4,513
    800015a2:	cbb1                	beqz	a5,800015f6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a4:	00a75593          	srli	a1,a4,0xa
    800015a8:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ac:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b0:	fffff097          	auipc	ra,0xfffff
    800015b4:	536080e7          	jalr	1334(ra) # 80000ae6 <kalloc>
    800015b8:	892a                	mv	s2,a0
    800015ba:	c939                	beqz	a0,80001610 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015bc:	6605                	lui	a2,0x1
    800015be:	85de                	mv	a1,s7
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	76e080e7          	jalr	1902(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c8:	8726                	mv	a4,s1
    800015ca:	86ca                	mv	a3,s2
    800015cc:	6605                	lui	a2,0x1
    800015ce:	85ce                	mv	a1,s3
    800015d0:	8556                	mv	a0,s5
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	acc080e7          	jalr	-1332(ra) # 8000109e <mappages>
    800015da:	e515                	bnez	a0,80001606 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015dc:	6785                	lui	a5,0x1
    800015de:	99be                	add	s3,s3,a5
    800015e0:	fb49e6e3          	bltu	s3,s4,8000158c <uvmcopy+0x20>
    800015e4:	a081                	j	80001624 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e6:	00007517          	auipc	a0,0x7
    800015ea:	ba250513          	addi	a0,a0,-1118 # 80008188 <digits+0x148>
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f6:	00007517          	auipc	a0,0x7
    800015fa:	bb250513          	addi	a0,a0,-1102 # 800081a8 <digits+0x168>
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
      kfree(mem);
    80001606:	854a                	mv	a0,s2
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	3e2080e7          	jalr	994(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001610:	4685                	li	a3,1
    80001612:	00c9d613          	srli	a2,s3,0xc
    80001616:	4581                	li	a1,0
    80001618:	8556                	mv	a0,s5
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	c4a080e7          	jalr	-950(ra) # 80001264 <uvmunmap>
  return -1;
    80001622:	557d                	li	a0,-1
}
    80001624:	60a6                	ld	ra,72(sp)
    80001626:	6406                	ld	s0,64(sp)
    80001628:	74e2                	ld	s1,56(sp)
    8000162a:	7942                	ld	s2,48(sp)
    8000162c:	79a2                	ld	s3,40(sp)
    8000162e:	7a02                	ld	s4,32(sp)
    80001630:	6ae2                	ld	s5,24(sp)
    80001632:	6b42                	ld	s6,16(sp)
    80001634:	6ba2                	ld	s7,8(sp)
    80001636:	6161                	addi	sp,sp,80
    80001638:	8082                	ret
  return 0;
    8000163a:	4501                	li	a0,0
}
    8000163c:	8082                	ret

000000008000163e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163e:	1141                	addi	sp,sp,-16
    80001640:	e406                	sd	ra,8(sp)
    80001642:	e022                	sd	s0,0(sp)
    80001644:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001646:	4601                	li	a2,0
    80001648:	00000097          	auipc	ra,0x0
    8000164c:	96e080e7          	jalr	-1682(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001650:	c901                	beqz	a0,80001660 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001652:	611c                	ld	a5,0(a0)
    80001654:	9bbd                	andi	a5,a5,-17
    80001656:	e11c                	sd	a5,0(a0)
}
    80001658:	60a2                	ld	ra,8(sp)
    8000165a:	6402                	ld	s0,0(sp)
    8000165c:	0141                	addi	sp,sp,16
    8000165e:	8082                	ret
    panic("uvmclear");
    80001660:	00007517          	auipc	a0,0x7
    80001664:	b6850513          	addi	a0,a0,-1176 # 800081c8 <digits+0x188>
    80001668:	fffff097          	auipc	ra,0xfffff
    8000166c:	ed6080e7          	jalr	-298(ra) # 8000053e <panic>

0000000080001670 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001670:	c6bd                	beqz	a3,800016de <copyout+0x6e>
{
    80001672:	715d                	addi	sp,sp,-80
    80001674:	e486                	sd	ra,72(sp)
    80001676:	e0a2                	sd	s0,64(sp)
    80001678:	fc26                	sd	s1,56(sp)
    8000167a:	f84a                	sd	s2,48(sp)
    8000167c:	f44e                	sd	s3,40(sp)
    8000167e:	f052                	sd	s4,32(sp)
    80001680:	ec56                	sd	s5,24(sp)
    80001682:	e85a                	sd	s6,16(sp)
    80001684:	e45e                	sd	s7,8(sp)
    80001686:	e062                	sd	s8,0(sp)
    80001688:	0880                	addi	s0,sp,80
    8000168a:	8b2a                	mv	s6,a0
    8000168c:	8c2e                	mv	s8,a1
    8000168e:	8a32                	mv	s4,a2
    80001690:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001692:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001694:	6a85                	lui	s5,0x1
    80001696:	a015                	j	800016ba <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001698:	9562                	add	a0,a0,s8
    8000169a:	0004861b          	sext.w	a2,s1
    8000169e:	85d2                	mv	a1,s4
    800016a0:	41250533          	sub	a0,a0,s2
    800016a4:	fffff097          	auipc	ra,0xfffff
    800016a8:	68a080e7          	jalr	1674(ra) # 80000d2e <memmove>

    len -= n;
    800016ac:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b6:	02098263          	beqz	s3,800016da <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ba:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016be:	85ca                	mv	a1,s2
    800016c0:	855a                	mv	a0,s6
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	99a080e7          	jalr	-1638(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016ca:	cd01                	beqz	a0,800016e2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016cc:	418904b3          	sub	s1,s2,s8
    800016d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d2:	fc99f3e3          	bgeu	s3,s1,80001698 <copyout+0x28>
    800016d6:	84ce                	mv	s1,s3
    800016d8:	b7c1                	j	80001698 <copyout+0x28>
  }
  return 0;
    800016da:	4501                	li	a0,0
    800016dc:	a021                	j	800016e4 <copyout+0x74>
    800016de:	4501                	li	a0,0
}
    800016e0:	8082                	ret
      return -1;
    800016e2:	557d                	li	a0,-1
}
    800016e4:	60a6                	ld	ra,72(sp)
    800016e6:	6406                	ld	s0,64(sp)
    800016e8:	74e2                	ld	s1,56(sp)
    800016ea:	7942                	ld	s2,48(sp)
    800016ec:	79a2                	ld	s3,40(sp)
    800016ee:	7a02                	ld	s4,32(sp)
    800016f0:	6ae2                	ld	s5,24(sp)
    800016f2:	6b42                	ld	s6,16(sp)
    800016f4:	6ba2                	ld	s7,8(sp)
    800016f6:	6c02                	ld	s8,0(sp)
    800016f8:	6161                	addi	sp,sp,80
    800016fa:	8082                	ret

00000000800016fc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fc:	caa5                	beqz	a3,8000176c <copyin+0x70>
{
    800016fe:	715d                	addi	sp,sp,-80
    80001700:	e486                	sd	ra,72(sp)
    80001702:	e0a2                	sd	s0,64(sp)
    80001704:	fc26                	sd	s1,56(sp)
    80001706:	f84a                	sd	s2,48(sp)
    80001708:	f44e                	sd	s3,40(sp)
    8000170a:	f052                	sd	s4,32(sp)
    8000170c:	ec56                	sd	s5,24(sp)
    8000170e:	e85a                	sd	s6,16(sp)
    80001710:	e45e                	sd	s7,8(sp)
    80001712:	e062                	sd	s8,0(sp)
    80001714:	0880                	addi	s0,sp,80
    80001716:	8b2a                	mv	s6,a0
    80001718:	8a2e                	mv	s4,a1
    8000171a:	8c32                	mv	s8,a2
    8000171c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001720:	6a85                	lui	s5,0x1
    80001722:	a01d                	j	80001748 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001724:	018505b3          	add	a1,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412585b3          	sub	a1,a1,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	5fc080e7          	jalr	1532(ra) # 80000d2e <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	90c080e7          	jalr	-1780(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f2e3          	bgeu	s3,s1,80001724 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	bf7d                	j	80001724 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x76>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	87a080e7          	jalr	-1926(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <find_index_in_memory>:

int find_index_in_memory(){
    8000183e:	1141                	addi	sp,sp,-16
    80001840:	e406                	sd	ra,8(sp)
    80001842:	e022                	sd	s0,0(sp)
    80001844:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80001846:	00000097          	auipc	ra,0x0
    8000184a:	6e2080e7          	jalr	1762(ra) # 80001f28 <myproc>
  struct page_data *pg;
  for(pg = p->memory_pages; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
    8000184e:	17050613          	addi	a2,a0,368
    80001852:	37050693          	addi	a3,a0,880
    80001856:	87b2                	mv	a5,a2
    if(!pg->used){
    80001858:	4798                	lw	a4,8(a5)
    8000185a:	cb11                	beqz	a4,8000186e <find_index_in_memory+0x30>
  for(pg = p->memory_pages; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
    8000185c:	02078793          	addi	a5,a5,32
    80001860:	fed79ce3          	bne	a5,a3,80001858 <find_index_in_memory+0x1a>
      return (int)(pg - p->memory_pages);
    }
  }
  return -1;
    80001864:	557d                	li	a0,-1
}
    80001866:	60a2                	ld	ra,8(sp)
    80001868:	6402                	ld	s0,0(sp)
    8000186a:	0141                	addi	sp,sp,16
    8000186c:	8082                	ret
      return (int)(pg - p->memory_pages);
    8000186e:	40c78533          	sub	a0,a5,a2
    80001872:	8515                	srai	a0,a0,0x5
    80001874:	2501                	sext.w	a0,a0
    80001876:	bfc5                	j	80001866 <find_index_in_memory+0x28>

0000000080001878 <choose_from_memory_by_LIFO>:
}


// task 2 - choose file 
int choose_from_memory_by_LIFO() 
{
    80001878:	1141                	addi	sp,sp,-16
    8000187a:	e406                	sd	ra,8(sp)
    8000187c:	e022                	sd	s0,0(sp)
    8000187e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80001880:	00000097          	auipc	ra,0x0
    80001884:	6a8080e7          	jalr	1704(ra) # 80001f28 <myproc>

  struct page_data *mg; 
  mg = p -> memory_pages; 
  return (int)(mg - p->memory_pages); 
}
    80001888:	4501                	li	a0,0
    8000188a:	60a2                	ld	ra,8(sp)
    8000188c:	6402                	ld	s0,0(sp)
    8000188e:	0141                	addi	sp,sp,16
    80001890:	8082                	ret

0000000080001892 <choose_from_swap_by_LIFO>:
// task 2 - choose file 
int choose_from_swap_by_LIFO() 
{
    80001892:	1141                	addi	sp,sp,-16
    80001894:	e422                	sd	s0,8(sp)
    80001896:	0800                	addi	s0,sp,16
      youngest = g-> time; 
      mg = g; 
     }
  }
  return (int)(mg - p->memory_pages); 
}
    80001898:	4505                	li	a0,1
    8000189a:	6422                	ld	s0,8(sp)
    8000189c:	0141                	addi	sp,sp,16
    8000189e:	8082                	ret

00000000800018a0 <update_age>:


void update_age(struct proc* p){
    800018a0:	7179                	addi	sp,sp,-48
    800018a2:	f406                	sd	ra,40(sp)
    800018a4:	f022                	sd	s0,32(sp)
    800018a6:	ec26                	sd	s1,24(sp)
    800018a8:	e84a                	sd	s2,16(sp)
    800018aa:	e44e                	sd	s3,8(sp)
    800018ac:	e052                	sd	s4,0(sp)
    800018ae:	1800                	addi	s0,sp,48
    800018b0:	89aa                	mv	s3,a0
  struct page_data *pg;
  pte_t* pte;
  for(pg = p->memory_pages; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
    800018b2:	17050493          	addi	s1,a0,368
    800018b6:	37050913          	addi	s2,a0,880
      if(*pte & PTE_A){
        //When a page got accessed (check the status of the PTE_A), 
        //the counter isshifted right by one bit, 
        //and then the digit 1 is added to the most significant bit
        pg->age = (pg->age >> 1);
        pg->age |= (0x8000000000000000);
    800018ba:	5a7d                	li	s4,-1
    800018bc:	1a7e                	slli	s4,s4,0x3f
    800018be:	a821                	j	800018d6 <update_age+0x36>
      }
      else{
        //shifted right by one bit if its unsed page
        pg->age = (pg->age >> 1); 
    800018c0:	689c                	ld	a5,16(s1)
    800018c2:	8385                	srli	a5,a5,0x1
    800018c4:	e89c                	sd	a5,16(s1)
      }

      *pte &= ~ PTE_A; //turn off PTE_A
    800018c6:	611c                	ld	a5,0(a0)
    800018c8:	fbf7f793          	andi	a5,a5,-65
    800018cc:	e11c                	sd	a5,0(a0)
  for(pg = p->memory_pages; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
    800018ce:	02048493          	addi	s1,s1,32
    800018d2:	02990563          	beq	s2,s1,800018fc <update_age+0x5c>
    if(pg->used){
    800018d6:	449c                	lw	a5,8(s1)
    800018d8:	dbfd                	beqz	a5,800018ce <update_age+0x2e>
      pte = walk(p->pagetable, pg->va, 0);
    800018da:	4601                	li	a2,0
    800018dc:	608c                	ld	a1,0(s1)
    800018de:	0509b503          	ld	a0,80(s3) # 1050 <_entry-0x7fffefb0>
    800018e2:	fffff097          	auipc	ra,0xfffff
    800018e6:	6d4080e7          	jalr	1748(ra) # 80000fb6 <walk>
      if(*pte & PTE_A){
    800018ea:	611c                	ld	a5,0(a0)
    800018ec:	0407f793          	andi	a5,a5,64
    800018f0:	dbe1                	beqz	a5,800018c0 <update_age+0x20>
        pg->age = (pg->age >> 1);
    800018f2:	689c                	ld	a5,16(s1)
    800018f4:	8385                	srli	a5,a5,0x1
        pg->age |= (0x8000000000000000);
    800018f6:	0147e7b3          	or	a5,a5,s4
    800018fa:	b7e9                	j	800018c4 <update_age+0x24>
    }
  }
}
    800018fc:	70a2                	ld	ra,40(sp)
    800018fe:	7402                	ld	s0,32(sp)
    80001900:	64e2                	ld	s1,24(sp)
    80001902:	6942                	ld	s2,16(sp)
    80001904:	69a2                	ld	s3,8(sp)
    80001906:	6a02                	ld	s4,0(sp)
    80001908:	6145                	addi	sp,sp,48
    8000190a:	8082                	ret

000000008000190c <nfua_algo>:

int nfua_algo(){
    8000190c:	1141                	addi	sp,sp,-16
    8000190e:	e406                	sd	ra,8(sp)
    80001910:	e022                	sd	s0,0(sp)
    80001912:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80001914:	00000097          	auipc	ra,0x0
    80001918:	614080e7          	jalr	1556(ra) # 80001f28 <myproc>
    8000191c:	85aa                	mv	a1,a0
  struct page_data *pg;
  uint64 min_age = ~0;
  int min_age_index = 1;
  for(pg = p->memory_pages+1; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
    8000191e:	19050793          	addi	a5,a0,400
    80001922:	37050693          	addi	a3,a0,880
  int min_age_index = 1;
    80001926:	4505                	li	a0,1
  uint64 min_age = ~0;
    80001928:	567d                	li	a2,-1
    if(pg->used && pg->age < min_age){
      min_age = pg->age;
      min_age_index = (int)(pg - p->memory_pages);
    8000192a:	17058593          	addi	a1,a1,368 # 4000170 <_entry-0x7bfffe90>
    8000192e:	a029                	j	80001938 <nfua_algo+0x2c>
  for(pg = p->memory_pages+1; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
    80001930:	02078793          	addi	a5,a5,32
    80001934:	00f68d63          	beq	a3,a5,8000194e <nfua_algo+0x42>
    if(pg->used && pg->age < min_age){
    80001938:	4798                	lw	a4,8(a5)
    8000193a:	db7d                	beqz	a4,80001930 <nfua_algo+0x24>
    8000193c:	6b98                	ld	a4,16(a5)
    8000193e:	fec779e3          	bgeu	a4,a2,80001930 <nfua_algo+0x24>
      min_age_index = (int)(pg - p->memory_pages);
    80001942:	40b78533          	sub	a0,a5,a1
    80001946:	8515                	srai	a0,a0,0x5
    80001948:	2501                	sext.w	a0,a0
      min_age = pg->age;
    8000194a:	863a                	mv	a2,a4
    8000194c:	b7d5                	j	80001930 <nfua_algo+0x24>
    }
  }
  return min_age_index;
}
    8000194e:	60a2                	ld	ra,8(sp)
    80001950:	6402                	ld	s0,0(sp)
    80001952:	0141                	addi	sp,sp,16
    80001954:	8082                	ret

0000000080001956 <scfifo_algo>:

int scfifo_algo(){
    80001956:	7139                	addi	sp,sp,-64
    80001958:	fc06                	sd	ra,56(sp)
    8000195a:	f822                	sd	s0,48(sp)
    8000195c:	f426                	sd	s1,40(sp)
    8000195e:	f04a                	sd	s2,32(sp)
    80001960:	ec4e                	sd	s3,24(sp)
    80001962:	e852                	sd	s4,16(sp)
    80001964:	e456                	sd	s5,8(sp)
    80001966:	e05a                	sd	s6,0(sp)
    80001968:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000196a:	00000097          	auipc	ra,0x0
    8000196e:	5be080e7          	jalr	1470(ra) # 80001f28 <myproc>
    80001972:	89aa                	mv	s3,a0

  again:
  min_creation_time = (uint64)~0;
  min_creation_index = 1;

  for(pg = p->memory_pages; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){ //min creation time for fifo 
    80001974:	17050a13          	addi	s4,a0,368
    80001978:	37050913          	addi	s2,a0,880
  min_creation_index = 1;
    8000197c:	4b05                	li	s6,1
  min_creation_time = (uint64)~0;
    8000197e:	5afd                	li	s5,-1
    80001980:	a085                	j	800019e0 <scfifo_algo+0x8a>
  for(pg = p->memory_pages; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){ //min creation time for fifo 
    80001982:	02078793          	addi	a5,a5,32
    80001986:	01278e63          	beq	a5,s2,800019a2 <scfifo_algo+0x4c>
    if(pg->used && pg->time<= min_creation_time){
    8000198a:	4798                	lw	a4,8(a5)
    8000198c:	db7d                	beqz	a4,80001982 <scfifo_algo+0x2c>
    8000198e:	6f98                	ld	a4,24(a5)
    80001990:	fee6e9e3          	bltu	a3,a4,80001982 <scfifo_algo+0x2c>
      min_creation_index=(int)(pg - p->memory_pages);
    80001994:	414786b3          	sub	a3,a5,s4
    80001998:	8695                	srai	a3,a3,0x5
    8000199a:	0006849b          	sext.w	s1,a3
      min_creation_time=pg->time;
    8000199e:	86ba                	mv	a3,a4
    800019a0:	b7cd                	j	80001982 <scfifo_algo+0x2c>
    }
  }
  pte_t* pte=walk(p->pagetable,p->memory_pages[min_creation_index].va,0); // return addr
    800019a2:	00549793          	slli	a5,s1,0x5
    800019a6:	97ce                	add	a5,a5,s3
    800019a8:	4601                	li	a2,0
    800019aa:	1707b583          	ld	a1,368(a5)
    800019ae:	0509b503          	ld	a0,80(s3)
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	604080e7          	jalr	1540(ra) # 80000fb6 <walk>
  if((*pte & PTE_A)!=0){ //second chance 
    800019ba:	611c                	ld	a5,0(a0)
    800019bc:	0407f713          	andi	a4,a5,64
    800019c0:	c705                	beqz	a4,800019e8 <scfifo_algo+0x92>
    *pte &=~ PTE_A; // trun off the access flag
    800019c2:	fbf7f793          	andi	a5,a5,-65
    800019c6:	e11c                	sd	a5,0(a0)
    p->memory_pages[min_creation_index].time= ++p->page_timer;  
    800019c8:	5789a783          	lw	a5,1400(s3)
    800019cc:	2785                	addiw	a5,a5,1
    800019ce:	0007871b          	sext.w	a4,a5
    800019d2:	56f9ac23          	sw	a5,1400(s3)
    800019d6:	00c48793          	addi	a5,s1,12
    800019da:	0796                	slli	a5,a5,0x5
    800019dc:	97ce                	add	a5,a5,s3
    800019de:	e798                	sd	a4,8(a5)
  for(pg = p->memory_pages; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){ //min creation time for fifo 
    800019e0:	87d2                	mv	a5,s4
  min_creation_index = 1;
    800019e2:	84da                	mv	s1,s6
  min_creation_time = (uint64)~0;
    800019e4:	86d6                	mv	a3,s5
    800019e6:	b755                	j	8000198a <scfifo_algo+0x34>
    goto again; // find again 
  }
  // if got here then we found pg with min time that PTE_A is turned off
  return min_creation_index;
}
    800019e8:	8526                	mv	a0,s1
    800019ea:	70e2                	ld	ra,56(sp)
    800019ec:	7442                	ld	s0,48(sp)
    800019ee:	74a2                	ld	s1,40(sp)
    800019f0:	7902                	ld	s2,32(sp)
    800019f2:	69e2                	ld	s3,24(sp)
    800019f4:	6a42                	ld	s4,16(sp)
    800019f6:	6aa2                	ld	s5,8(sp)
    800019f8:	6b02                	ld	s6,0(sp)
    800019fa:	6121                	addi	sp,sp,64
    800019fc:	8082                	ret

00000000800019fe <get_page_by_alg>:
int get_page_by_alg(){
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  return scfifo_algo();
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	f50080e7          	jalr	-176(ra) # 80001956 <scfifo_algo>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret

0000000080001a16 <swap_files>:
void swap_files(pagetable_t pagetable){
    80001a16:	7139                	addi	sp,sp,-64
    80001a18:	fc06                	sd	ra,56(sp)
    80001a1a:	f822                	sd	s0,48(sp)
    80001a1c:	f426                	sd	s1,40(sp)
    80001a1e:	f04a                	sd	s2,32(sp)
    80001a20:	ec4e                	sd	s3,24(sp)
    80001a22:	e852                	sd	s4,16(sp)
    80001a24:	e456                	sd	s5,8(sp)
    80001a26:	e05a                	sd	s6,0(sp)
    80001a28:	0080                	addi	s0,sp,64
    80001a2a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001a2c:	00000097          	auipc	ra,0x0
    80001a30:	4fc080e7          	jalr	1276(ra) # 80001f28 <myproc>
  if(p->memory_pages_count + p->swapped_pages_count > MAX_TOTAL_PAGES){
    80001a34:	57052783          	lw	a5,1392(a0)
    80001a38:	57452703          	lw	a4,1396(a0)
    80001a3c:	9fb9                	addw	a5,a5,a4
    80001a3e:	02000713          	li	a4,32
    80001a42:	02f74c63          	blt	a4,a5,80001a7a <swap_files+0x64>
    80001a46:	892a                	mv	s2,a0
  return scfifo_algo();
    80001a48:	00000097          	auipc	ra,0x0
    80001a4c:	f0e080e7          	jalr	-242(ra) # 80001956 <scfifo_algo>
  for(pg = p->swapped_pages; pg < &p->swapped_pages[MAX_PSYC_PAGES]; pg++){
    80001a50:	37090a93          	addi	s5,s2,880 # 1370 <_entry-0x7fffec90>
    80001a54:	57090713          	addi	a4,s2,1392
    80001a58:	84d6                	mv	s1,s5
    if(!pg->used){
    80001a5a:	449c                	lw	a5,8(s1)
    80001a5c:	c79d                	beqz	a5,80001a8a <swap_files+0x74>
  for(pg = p->swapped_pages; pg < &p->swapped_pages[MAX_PSYC_PAGES]; pg++){
    80001a5e:	02048493          	addi	s1,s1,32
    80001a62:	fee49ce3          	bne	s1,a4,80001a5a <swap_files+0x44>
}
    80001a66:	70e2                	ld	ra,56(sp)
    80001a68:	7442                	ld	s0,48(sp)
    80001a6a:	74a2                	ld	s1,40(sp)
    80001a6c:	7902                	ld	s2,32(sp)
    80001a6e:	69e2                	ld	s3,24(sp)
    80001a70:	6a42                	ld	s4,16(sp)
    80001a72:	6aa2                	ld	s5,8(sp)
    80001a74:	6b02                	ld	s6,0(sp)
    80001a76:	6121                	addi	sp,sp,64
    80001a78:	8082                	ret
    panic("more than 32 pages per proccess");
    80001a7a:	00006517          	auipc	a0,0x6
    80001a7e:	75e50513          	addi	a0,a0,1886 # 800081d8 <digits+0x198>
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	abc080e7          	jalr	-1348(ra) # 8000053e <panic>
      pg->used = 1;
    80001a8a:	4785                	li	a5,1
    80001a8c:	c49c                	sw	a5,8(s1)
      pg->va = pg_to_swap->va;
    80001a8e:	00551993          	slli	s3,a0,0x5
    80001a92:	99ca                	add	s3,s3,s2
    80001a94:	1709b583          	ld	a1,368(s3)
    80001a98:	e08c                	sd	a1,0(s1)
      pte_t* pte = walk(pagetable, pg->va, 0); //p->pagetable? or pagetable? 
    80001a9a:	4601                	li	a2,0
    80001a9c:	8552                	mv	a0,s4
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	518080e7          	jalr	1304(ra) # 80000fb6 <walk>
    80001aa6:	8b2a                	mv	s6,a0
      uint64 pa = PTE2PA(*pte);
    80001aa8:	00053a03          	ld	s4,0(a0)
    80001aac:	00aa5a13          	srli	s4,s4,0xa
    80001ab0:	0a32                	slli	s4,s4,0xc
      int offset = (pg - p->swapped_pages)*PGSIZE;
    80001ab2:	41548633          	sub	a2,s1,s5
      writeToSwapFile(p, (char*)pa, offset, PGSIZE); 
    80001ab6:	6685                	lui	a3,0x1
    80001ab8:	0076161b          	slliw	a2,a2,0x7
    80001abc:	85d2                	mv	a1,s4
    80001abe:	854a                	mv	a0,s2
    80001ac0:	00003097          	auipc	ra,0x3
    80001ac4:	bc8080e7          	jalr	-1080(ra) # 80004688 <writeToSwapFile>
      p->swapped_pages_count++;
    80001ac8:	57492783          	lw	a5,1396(s2)
    80001acc:	2785                	addiw	a5,a5,1
    80001ace:	56f92a23          	sw	a5,1396(s2)
      kfree((void*)pa); 
    80001ad2:	8552                	mv	a0,s4
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	f16080e7          	jalr	-234(ra) # 800009ea <kfree>
      *pte &= ~PTE_V;     //Whenever a page is moved to the paging file,
    80001adc:	000b3783          	ld	a5,0(s6)
    80001ae0:	9bf9                	andi	a5,a5,-2
    80001ae2:	2007e793          	ori	a5,a5,512
    80001ae6:	00fb3023          	sd	a5,0(s6)
      pg_to_swap->used = 0;
    80001aea:	1609ac23          	sw	zero,376(s3)
      pg_to_swap->va = 0;
    80001aee:	1609b823          	sd	zero,368(s3)
      p->memory_pages_count--;
    80001af2:	57092783          	lw	a5,1392(s2)
    80001af6:	37fd                	addiw	a5,a5,-1
    80001af8:	56f92823          	sw	a5,1392(s2)
    80001afc:	12000073          	sfence.vma
}
    80001b00:	b79d                	j	80001a66 <swap_files+0x50>

0000000080001b02 <update_proc_memory>:
void update_proc_memory(uint64 a, pagetable_t pagetable){
    80001b02:	7179                	addi	sp,sp,-48
    80001b04:	f406                	sd	ra,40(sp)
    80001b06:	f022                	sd	s0,32(sp)
    80001b08:	ec26                	sd	s1,24(sp)
    80001b0a:	e84a                	sd	s2,16(sp)
    80001b0c:	e44e                	sd	s3,8(sp)
    80001b0e:	e052                	sd	s4,0(sp)
    80001b10:	1800                	addi	s0,sp,48
    80001b12:	8a2a                	mv	s4,a0
    80001b14:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80001b16:	00000097          	auipc	ra,0x0
    80001b1a:	412080e7          	jalr	1042(ra) # 80001f28 <myproc>
    80001b1e:	892a                	mv	s2,a0
  if(p->memory_pages_count == MAX_PSYC_PAGES){
    80001b20:	57052703          	lw	a4,1392(a0)
    80001b24:	47c1                	li	a5,16
    80001b26:	08f70d63          	beq	a4,a5,80001bc0 <update_proc_memory+0xbe>
  int index_memory = find_index_in_memory();
    80001b2a:	00000097          	auipc	ra,0x0
    80001b2e:	d14080e7          	jalr	-748(ra) # 8000183e <find_index_in_memory>
  pg->used = 1;
    80001b32:	00551493          	slli	s1,a0,0x5
    80001b36:	94ca                	add	s1,s1,s2
    80001b38:	4785                	li	a5,1
    80001b3a:	16f4ac23          	sw	a5,376(s1)
  pg->va = a;
    80001b3e:	1744b823          	sd	s4,368(s1)
    printf("NFUA\n");
    80001b42:	00006517          	auipc	a0,0x6
    80001b46:	6b650513          	addi	a0,a0,1718 # 800081f8 <digits+0x1b8>
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	a3e080e7          	jalr	-1474(ra) # 80000588 <printf>
  pg->age = (uint64)~0;
    80001b52:	57fd                	li	a5,-1
    80001b54:	18f4b023          	sd	a5,384(s1)
  printf("LAPA\n");
    80001b58:	00006517          	auipc	a0,0x6
    80001b5c:	6a850513          	addi	a0,a0,1704 # 80008200 <digits+0x1c0>
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	a28080e7          	jalr	-1496(ra) # 80000588 <printf>
  pg->time=++p->page_timer;
    80001b68:	57892783          	lw	a5,1400(s2)
    80001b6c:	2785                	addiw	a5,a5,1
    80001b6e:	0007871b          	sext.w	a4,a5
    80001b72:	56f92c23          	sw	a5,1400(s2)
    80001b76:	18e4b423          	sd	a4,392(s1)
  printf("SCFIFO\n");
    80001b7a:	00006517          	auipc	a0,0x6
    80001b7e:	68e50513          	addi	a0,a0,1678 # 80008208 <digits+0x1c8>
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	a06080e7          	jalr	-1530(ra) # 80000588 <printf>
  p->memory_pages_count++;
    80001b8a:	57092783          	lw	a5,1392(s2)
    80001b8e:	2785                	addiw	a5,a5,1
    80001b90:	56f92823          	sw	a5,1392(s2)
  pte_t* pte = walk(pagetable, pg->va, 0);
    80001b94:	4601                	li	a2,0
    80001b96:	1704b583          	ld	a1,368(s1)
    80001b9a:	854e                	mv	a0,s3
    80001b9c:	fffff097          	auipc	ra,0xfffff
    80001ba0:	41a080e7          	jalr	1050(ra) # 80000fb6 <walk>
  *pte &= ~PTE_PG;     //paged in to memory - turn off bit 
    80001ba4:	611c                	ld	a5,0(a0)
    80001ba6:	dff7f793          	andi	a5,a5,-513
  *pte |= PTE_V;
    80001baa:	0017e793          	ori	a5,a5,1
    80001bae:	e11c                	sd	a5,0(a0)
}
    80001bb0:	70a2                	ld	ra,40(sp)
    80001bb2:	7402                	ld	s0,32(sp)
    80001bb4:	64e2                	ld	s1,24(sp)
    80001bb6:	6942                	ld	s2,16(sp)
    80001bb8:	69a2                	ld	s3,8(sp)
    80001bba:	6a02                	ld	s4,0(sp)
    80001bbc:	6145                	addi	sp,sp,48
    80001bbe:	8082                	ret
    swap_files(pagetable);
    80001bc0:	854e                	mv	a0,s3
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	e54080e7          	jalr	-428(ra) # 80001a16 <swap_files>
    80001bca:	b785                	j	80001b2a <update_proc_memory+0x28>

0000000080001bcc <page_fault_handler>:
int page_fault_handler(){
    80001bcc:	715d                	addi	sp,sp,-80
    80001bce:	e486                	sd	ra,72(sp)
    80001bd0:	e0a2                	sd	s0,64(sp)
    80001bd2:	fc26                	sd	s1,56(sp)
    80001bd4:	f84a                	sd	s2,48(sp)
    80001bd6:	f44e                	sd	s3,40(sp)
    80001bd8:	f052                	sd	s4,32(sp)
    80001bda:	ec56                	sd	s5,24(sp)
    80001bdc:	e85a                	sd	s6,16(sp)
    80001bde:	e45e                	sd	s7,8(sp)
    80001be0:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    80001be2:	00000097          	auipc	ra,0x0
    80001be6:	346080e7          	jalr	838(ra) # 80001f28 <myproc>
    80001bea:	892a                	mv	s2,a0
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001bec:	143029f3          	csrr	s3,stval
  pte_t* pte = walk(p->pagetable, va, 0);
    80001bf0:	4601                	li	a2,0
    80001bf2:	85ce                	mv	a1,s3
    80001bf4:	6928                	ld	a0,80(a0)
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	3c0080e7          	jalr	960(ra) # 80000fb6 <walk>
    80001bfe:	8a2a                	mv	s4,a0
  if(*pte & PTE_PG){
    80001c00:	611c                	ld	a5,0(a0)
    80001c02:	2007f793          	andi	a5,a5,512
    return 0; //this is segfault
    80001c06:	4501                	li	a0,0
  if(*pte & PTE_PG){
    80001c08:	ef81                	bnez	a5,80001c20 <page_fault_handler+0x54>
}
    80001c0a:	60a6                	ld	ra,72(sp)
    80001c0c:	6406                	ld	s0,64(sp)
    80001c0e:	74e2                	ld	s1,56(sp)
    80001c10:	7942                	ld	s2,48(sp)
    80001c12:	79a2                	ld	s3,40(sp)
    80001c14:	7a02                	ld	s4,32(sp)
    80001c16:	6ae2                	ld	s5,24(sp)
    80001c18:	6b42                	ld	s6,16(sp)
    80001c1a:	6ba2                	ld	s7,8(sp)
    80001c1c:	6161                	addi	sp,sp,80
    80001c1e:	8082                	ret
    if(p->memory_pages_count == MAX_PSYC_PAGES){
    80001c20:	57092703          	lw	a4,1392(s2)
    80001c24:	47c1                	li	a5,16
    80001c26:	02f70a63          	beq	a4,a5,80001c5a <page_fault_handler+0x8e>
    uint64 swap_va = PGROUNDDOWN(va);
    80001c2a:	77fd                	lui	a5,0xfffff
    80001c2c:	00f9f9b3          	and	s3,s3,a5
    char *mem = kalloc();
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	eb6080e7          	jalr	-330(ra) # 80000ae6 <kalloc>
    80001c38:	8aaa                	mv	s5,a0
    for(pg = p->swapped_pages; pg < &p->swapped_pages[MAX_PSYC_PAGES]; pg++){
    80001c3a:	37090b13          	addi	s6,s2,880
    80001c3e:	57090713          	addi	a4,s2,1392
    80001c42:	84da                	mv	s1,s6
      if(pg->va == swap_va){
    80001c44:	609c                	ld	a5,0(s1)
    80001c46:	03378163          	beq	a5,s3,80001c68 <page_fault_handler+0x9c>
    for(pg = p->swapped_pages; pg < &p->swapped_pages[MAX_PSYC_PAGES]; pg++){
    80001c4a:	02048493          	addi	s1,s1,32
    80001c4e:	fee49be3          	bne	s1,a4,80001c44 <page_fault_handler+0x78>
  asm volatile("sfence.vma zero, zero");
    80001c52:	12000073          	sfence.vma
    return 3;
    80001c56:	450d                	li	a0,3
    80001c58:	bf4d                	j	80001c0a <page_fault_handler+0x3e>
      swap_files(p->pagetable);
    80001c5a:	05093503          	ld	a0,80(s2)
    80001c5e:	00000097          	auipc	ra,0x0
    80001c62:	db8080e7          	jalr	-584(ra) # 80001a16 <swap_files>
    80001c66:	b7d1                	j	80001c2a <page_fault_handler+0x5e>
        pte_t* g_pte = walk(p->pagetable, swap_va, 0);
    80001c68:	4601                	li	a2,0
    80001c6a:	85ce                	mv	a1,s3
    80001c6c:	05093503          	ld	a0,80(s2)
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	346080e7          	jalr	838(ra) # 80000fb6 <walk>
    80001c78:	8baa                	mv	s7,a0
        int offset = (pg - p->swapped_pages);
    80001c7a:	41648633          	sub	a2,s1,s6
    80001c7e:	8615                	srai	a2,a2,0x5
        readFromSwapFile(p, mem, offset*PGSIZE, PGSIZE);
    80001c80:	6685                	lui	a3,0x1
    80001c82:	00c6161b          	slliw	a2,a2,0xc
    80001c86:	85d6                	mv	a1,s5
    80001c88:	854a                	mv	a0,s2
    80001c8a:	00003097          	auipc	ra,0x3
    80001c8e:	a22080e7          	jalr	-1502(ra) # 800046ac <readFromSwapFile>
        int index_memory = find_index_in_memory();
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	bac080e7          	jalr	-1108(ra) # 8000183e <find_index_in_memory>
        free_memory_page->used = 1;
    80001c9a:	00551993          	slli	s3,a0,0x5
    80001c9e:	99ca                	add	s3,s3,s2
    80001ca0:	4785                	li	a5,1
    80001ca2:	16f9ac23          	sw	a5,376(s3)
        free_memory_page->va = pg->va;
    80001ca6:	609c                	ld	a5,0(s1)
    80001ca8:	16f9b823          	sd	a5,368(s3)
        printf("NFUA\n");
    80001cac:	00006517          	auipc	a0,0x6
    80001cb0:	54c50513          	addi	a0,a0,1356 # 800081f8 <digits+0x1b8>
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	8d4080e7          	jalr	-1836(ra) # 80000588 <printf>
        free_memory_page->age = 0;
    80001cbc:	1809b023          	sd	zero,384(s3)
          printf("LAPA\n");
    80001cc0:	00006517          	auipc	a0,0x6
    80001cc4:	54050513          	addi	a0,a0,1344 # 80008200 <digits+0x1c0>
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	8c0080e7          	jalr	-1856(ra) # 80000588 <printf>
        free_memory_page->age = (uint64)~0;
    80001cd0:	57fd                	li	a5,-1
    80001cd2:	18f9b023          	sd	a5,384(s3)
          printf("SCFIFO\n");
    80001cd6:	00006517          	auipc	a0,0x6
    80001cda:	53250513          	addi	a0,a0,1330 # 80008208 <digits+0x1c8>
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	8aa080e7          	jalr	-1878(ra) # 80000588 <printf>
        free_memory_page->time=++p->page_timer;
    80001ce6:	57892783          	lw	a5,1400(s2)
    80001cea:	2785                	addiw	a5,a5,1
    80001cec:	0007871b          	sext.w	a4,a5
    80001cf0:	56f92c23          	sw	a5,1400(s2)
    80001cf4:	18e9b423          	sd	a4,392(s3)
        p->swapped_pages_count--;
    80001cf8:	57492783          	lw	a5,1396(s2)
    80001cfc:	37fd                	addiw	a5,a5,-1
    80001cfe:	56f92a23          	sw	a5,1396(s2)
        pg->used = 0;
    80001d02:	0004a423          	sw	zero,8(s1)
        pg->va = 0;
    80001d06:	0004b023          	sd	zero,0(s1)
        pg->age = 0;
    80001d0a:	0004b823          	sd	zero,16(s1)
        p->memory_pages_count++;
    80001d0e:	57092783          	lw	a5,1392(s2)
    80001d12:	2785                	addiw	a5,a5,1
    80001d14:	56f92823          	sw	a5,1392(s2)
        *g_pte = PA2PTE((uint64)mem) | PTE_FLAGS(*pte); //map new adress 
    80001d18:	00cada93          	srli	s5,s5,0xc
    80001d1c:	0aaa                	slli	s5,s5,0xa
    80001d1e:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0xffffffff7ffccc20>
    80001d22:	1ff7f793          	andi	a5,a5,511
        *g_pte &= ~PTE_PG;     //paged in to memory - turn off bit 
    80001d26:	0157eab3          	or	s5,a5,s5
        *g_pte |= PTE_V;
    80001d2a:	001aea93          	ori	s5,s5,1
    80001d2e:	015bb023          	sd	s5,0(s7) # fffffffffffff000 <end+0xffffffff7ffccc20>
        break;
    80001d32:	b705                	j	80001c52 <page_fault_handler+0x86>

0000000080001d34 <lapa_algo>:

int lapa_algo(){
    80001d34:	1141                	addi	sp,sp,-16
    80001d36:	e406                	sd	ra,8(sp)
    80001d38:	e022                	sd	s0,0(sp)
    80001d3a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	1ec080e7          	jalr	492(ra) # 80001f28 <myproc>
    80001d44:	87aa                	mv	a5,a0
  struct page_data *pg;
  int min_number_of_1=64;
  int index_with_min_1=-1;
  for(pg = p->memory_pages+1; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
    80001d46:	19050613          	addi	a2,a0,400
    80001d4a:	37050e13          	addi	t3,a0,880
  int index_with_min_1=-1;
    80001d4e:	557d                	li	a0,-1
  int min_number_of_1=64;
    80001d50:	04000593          	li	a1,64
    int counter=0,stoploop=0;
    if(pg->used){
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
    80001d54:	4f01                	li	t5,0
          uint64 mask = 1 << i;
    80001d56:	4885                	li	a7,1
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
    80001d58:	04000313          	li	t1,64
          if(counter>min_number_of_1) // in case count is bigger than current min 
            stoploop=1;           // stop counting and break from loop
        }
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
          min_number_of_1=counter;
          index_with_min_1=(int)(pg - p->memory_pages);
    80001d5c:	17078e93          	addi	t4,a5,368 # fffffffffffff170 <end+0xffffffff7ffccd90>
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
    80001d60:	5ffd                	li	t6,-1
    80001d62:	a805                	j	80001d92 <lapa_algo+0x5e>
          if(counter>min_number_of_1) // in case count is bigger than current min 
    80001d64:	02d5ce63          	blt	a1,a3,80001da0 <lapa_algo+0x6c>
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
    80001d68:	2705                	addiw	a4,a4,1
    80001d6a:	00670963          	beq	a4,t1,80001d7c <lapa_algo+0x48>
          uint64 mask = 1 << i;
    80001d6e:	00e897bb          	sllw	a5,a7,a4
          if((pg->age & mask)!=0)// if 1 is found 
    80001d72:	0107f7b3          	and	a5,a5,a6
    80001d76:	d7fd                	beqz	a5,80001d64 <lapa_algo+0x30>
              counter++;
    80001d78:	2685                	addiw	a3,a3,1
    80001d7a:	b7ed                	j	80001d64 <lapa_algo+0x30>
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
    80001d7c:	02b6d263          	bge	a3,a1,80001da0 <lapa_algo+0x6c>
          index_with_min_1=(int)(pg - p->memory_pages);
    80001d80:	41d60533          	sub	a0,a2,t4
    80001d84:	8515                	srai	a0,a0,0x5
    80001d86:	2501                	sext.w	a0,a0
    80001d88:	85b6                	mv	a1,a3
  for(pg = p->memory_pages+1; pg < &p->memory_pages[MAX_PSYC_PAGES]; pg++){
    80001d8a:	02060613          	addi	a2,a2,32 # 1020 <_entry-0x7fffefe0>
    80001d8e:	01c60e63          	beq	a2,t3,80001daa <lapa_algo+0x76>
    if(pg->used){
    80001d92:	461c                	lw	a5,8(a2)
    80001d94:	dbfd                	beqz	a5,80001d8a <lapa_algo+0x56>
          if((pg->age & mask)!=0)// if 1 is found 
    80001d96:	01063803          	ld	a6,16(a2)
        for(int i=0;i<64 && !stoploop;i++){ // do a mask for the 64 bits 
    80001d9a:	877a                	mv	a4,t5
    int counter=0,stoploop=0;
    80001d9c:	86fa                	mv	a3,t5
    80001d9e:	bfc1                	j	80001d6e <lapa_algo+0x3a>
        if(counter<min_number_of_1 || (index_with_min_1==-1 && counter<=min_number_of_1 )){
    80001da0:	fff515e3          	bne	a0,t6,80001d8a <lapa_algo+0x56>
    80001da4:	feb693e3          	bne	a3,a1,80001d8a <lapa_algo+0x56>
    80001da8:	bfe1                	j	80001d80 <lapa_algo+0x4c>
        }
      }
    }
    return index_with_min_1;
    80001daa:	60a2                	ld	ra,8(sp)
    80001dac:	6402                	ld	s0,0(sp)
    80001dae:	0141                	addi	sp,sp,16
    80001db0:	8082                	ret

0000000080001db2 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001db2:	7139                	addi	sp,sp,-64
    80001db4:	fc06                	sd	ra,56(sp)
    80001db6:	f822                	sd	s0,48(sp)
    80001db8:	f426                	sd	s1,40(sp)
    80001dba:	f04a                	sd	s2,32(sp)
    80001dbc:	ec4e                	sd	s3,24(sp)
    80001dbe:	e852                	sd	s4,16(sp)
    80001dc0:	e456                	sd	s5,8(sp)
    80001dc2:	e05a                	sd	s6,0(sp)
    80001dc4:	0080                	addi	s0,sp,64
    80001dc6:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dc8:	0000f497          	auipc	s1,0xf
    80001dcc:	23848493          	addi	s1,s1,568 # 80011000 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001dd0:	8b26                	mv	s6,s1
    80001dd2:	00006a97          	auipc	s5,0x6
    80001dd6:	22ea8a93          	addi	s5,s5,558 # 80008000 <etext>
    80001dda:	04000937          	lui	s2,0x4000
    80001dde:	197d                	addi	s2,s2,-1
    80001de0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de2:	00025a17          	auipc	s4,0x25
    80001de6:	21ea0a13          	addi	s4,s4,542 # 80027000 <tickslock>
    char *pa = kalloc();
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	cfc080e7          	jalr	-772(ra) # 80000ae6 <kalloc>
    80001df2:	862a                	mv	a2,a0
    if(pa == 0)
    80001df4:	c131                	beqz	a0,80001e38 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001df6:	416485b3          	sub	a1,s1,s6
    80001dfa:	859d                	srai	a1,a1,0x7
    80001dfc:	000ab783          	ld	a5,0(s5)
    80001e00:	02f585b3          	mul	a1,a1,a5
    80001e04:	2585                	addiw	a1,a1,1
    80001e06:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001e0a:	4719                	li	a4,6
    80001e0c:	6685                	lui	a3,0x1
    80001e0e:	40b905b3          	sub	a1,s2,a1
    80001e12:	854e                	mv	a0,s3
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	32a080e7          	jalr	810(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e1c:	58048493          	addi	s1,s1,1408
    80001e20:	fd4495e3          	bne	s1,s4,80001dea <proc_mapstacks+0x38>
  }
}
    80001e24:	70e2                	ld	ra,56(sp)
    80001e26:	7442                	ld	s0,48(sp)
    80001e28:	74a2                	ld	s1,40(sp)
    80001e2a:	7902                	ld	s2,32(sp)
    80001e2c:	69e2                	ld	s3,24(sp)
    80001e2e:	6a42                	ld	s4,16(sp)
    80001e30:	6aa2                	ld	s5,8(sp)
    80001e32:	6b02                	ld	s6,0(sp)
    80001e34:	6121                	addi	sp,sp,64
    80001e36:	8082                	ret
      panic("kalloc");
    80001e38:	00006517          	auipc	a0,0x6
    80001e3c:	3d850513          	addi	a0,a0,984 # 80008210 <digits+0x1d0>
    80001e40:	ffffe097          	auipc	ra,0xffffe
    80001e44:	6fe080e7          	jalr	1790(ra) # 8000053e <panic>

0000000080001e48 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001e48:	7139                	addi	sp,sp,-64
    80001e4a:	fc06                	sd	ra,56(sp)
    80001e4c:	f822                	sd	s0,48(sp)
    80001e4e:	f426                	sd	s1,40(sp)
    80001e50:	f04a                	sd	s2,32(sp)
    80001e52:	ec4e                	sd	s3,24(sp)
    80001e54:	e852                	sd	s4,16(sp)
    80001e56:	e456                	sd	s5,8(sp)
    80001e58:	e05a                	sd	s6,0(sp)
    80001e5a:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001e5c:	00006597          	auipc	a1,0x6
    80001e60:	3bc58593          	addi	a1,a1,956 # 80008218 <digits+0x1d8>
    80001e64:	0000f517          	auipc	a0,0xf
    80001e68:	d6c50513          	addi	a0,a0,-660 # 80010bd0 <pid_lock>
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	cda080e7          	jalr	-806(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001e74:	00006597          	auipc	a1,0x6
    80001e78:	3ac58593          	addi	a1,a1,940 # 80008220 <digits+0x1e0>
    80001e7c:	0000f517          	auipc	a0,0xf
    80001e80:	d6c50513          	addi	a0,a0,-660 # 80010be8 <wait_lock>
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	cc2080e7          	jalr	-830(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e8c:	0000f497          	auipc	s1,0xf
    80001e90:	17448493          	addi	s1,s1,372 # 80011000 <proc>
      initlock(&p->lock, "proc");
    80001e94:	00006b17          	auipc	s6,0x6
    80001e98:	39cb0b13          	addi	s6,s6,924 # 80008230 <digits+0x1f0>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001e9c:	8aa6                	mv	s5,s1
    80001e9e:	00006a17          	auipc	s4,0x6
    80001ea2:	162a0a13          	addi	s4,s4,354 # 80008000 <etext>
    80001ea6:	04000937          	lui	s2,0x4000
    80001eaa:	197d                	addi	s2,s2,-1
    80001eac:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001eae:	00025997          	auipc	s3,0x25
    80001eb2:	15298993          	addi	s3,s3,338 # 80027000 <tickslock>
      initlock(&p->lock, "proc");
    80001eb6:	85da                	mv	a1,s6
    80001eb8:	8526                	mv	a0,s1
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	c8c080e7          	jalr	-884(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001ec2:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001ec6:	415487b3          	sub	a5,s1,s5
    80001eca:	879d                	srai	a5,a5,0x7
    80001ecc:	000a3703          	ld	a4,0(s4)
    80001ed0:	02e787b3          	mul	a5,a5,a4
    80001ed4:	2785                	addiw	a5,a5,1
    80001ed6:	00d7979b          	slliw	a5,a5,0xd
    80001eda:	40f907b3          	sub	a5,s2,a5
    80001ede:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ee0:	58048493          	addi	s1,s1,1408
    80001ee4:	fd3499e3          	bne	s1,s3,80001eb6 <procinit+0x6e>
  }
}
    80001ee8:	70e2                	ld	ra,56(sp)
    80001eea:	7442                	ld	s0,48(sp)
    80001eec:	74a2                	ld	s1,40(sp)
    80001eee:	7902                	ld	s2,32(sp)
    80001ef0:	69e2                	ld	s3,24(sp)
    80001ef2:	6a42                	ld	s4,16(sp)
    80001ef4:	6aa2                	ld	s5,8(sp)
    80001ef6:	6b02                	ld	s6,0(sp)
    80001ef8:	6121                	addi	sp,sp,64
    80001efa:	8082                	ret

0000000080001efc <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001efc:	1141                	addi	sp,sp,-16
    80001efe:	e422                	sd	s0,8(sp)
    80001f00:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f02:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001f04:	2501                	sext.w	a0,a0
    80001f06:	6422                	ld	s0,8(sp)
    80001f08:	0141                	addi	sp,sp,16
    80001f0a:	8082                	ret

0000000080001f0c <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001f0c:	1141                	addi	sp,sp,-16
    80001f0e:	e422                	sd	s0,8(sp)
    80001f10:	0800                	addi	s0,sp,16
    80001f12:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001f14:	2781                	sext.w	a5,a5
    80001f16:	079e                	slli	a5,a5,0x7
  return c;
}
    80001f18:	0000f517          	auipc	a0,0xf
    80001f1c:	ce850513          	addi	a0,a0,-792 # 80010c00 <cpus>
    80001f20:	953e                	add	a0,a0,a5
    80001f22:	6422                	ld	s0,8(sp)
    80001f24:	0141                	addi	sp,sp,16
    80001f26:	8082                	ret

0000000080001f28 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001f28:	1101                	addi	sp,sp,-32
    80001f2a:	ec06                	sd	ra,24(sp)
    80001f2c:	e822                	sd	s0,16(sp)
    80001f2e:	e426                	sd	s1,8(sp)
    80001f30:	1000                	addi	s0,sp,32
  push_off();
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	c58080e7          	jalr	-936(ra) # 80000b8a <push_off>
    80001f3a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001f3c:	2781                	sext.w	a5,a5
    80001f3e:	079e                	slli	a5,a5,0x7
    80001f40:	0000f717          	auipc	a4,0xf
    80001f44:	c9070713          	addi	a4,a4,-880 # 80010bd0 <pid_lock>
    80001f48:	97ba                	add	a5,a5,a4
    80001f4a:	7b84                	ld	s1,48(a5)
  pop_off();
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	cde080e7          	jalr	-802(ra) # 80000c2a <pop_off>
  return p;
}
    80001f54:	8526                	mv	a0,s1
    80001f56:	60e2                	ld	ra,24(sp)
    80001f58:	6442                	ld	s0,16(sp)
    80001f5a:	64a2                	ld	s1,8(sp)
    80001f5c:	6105                	addi	sp,sp,32
    80001f5e:	8082                	ret

0000000080001f60 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001f60:	1141                	addi	sp,sp,-16
    80001f62:	e406                	sd	ra,8(sp)
    80001f64:	e022                	sd	s0,0(sp)
    80001f66:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001f68:	00000097          	auipc	ra,0x0
    80001f6c:	fc0080e7          	jalr	-64(ra) # 80001f28 <myproc>
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	d1a080e7          	jalr	-742(ra) # 80000c8a <release>

  if (first) {
    80001f78:	00007797          	auipc	a5,0x7
    80001f7c:	9487a783          	lw	a5,-1720(a5) # 800088c0 <first.1>
    80001f80:	eb89                	bnez	a5,80001f92 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001f82:	00001097          	auipc	ra,0x1
    80001f86:	c90080e7          	jalr	-880(ra) # 80002c12 <usertrapret>
}
    80001f8a:	60a2                	ld	ra,8(sp)
    80001f8c:	6402                	ld	s0,0(sp)
    80001f8e:	0141                	addi	sp,sp,16
    80001f90:	8082                	ret
    first = 0;
    80001f92:	00007797          	auipc	a5,0x7
    80001f96:	9207a723          	sw	zero,-1746(a5) # 800088c0 <first.1>
    fsinit(ROOTDEV);
    80001f9a:	4505                	li	a0,1
    80001f9c:	00002097          	auipc	ra,0x2
    80001fa0:	9c6080e7          	jalr	-1594(ra) # 80003962 <fsinit>
    80001fa4:	bff9                	j	80001f82 <forkret+0x22>

0000000080001fa6 <allocpid>:
{
    80001fa6:	1101                	addi	sp,sp,-32
    80001fa8:	ec06                	sd	ra,24(sp)
    80001faa:	e822                	sd	s0,16(sp)
    80001fac:	e426                	sd	s1,8(sp)
    80001fae:	e04a                	sd	s2,0(sp)
    80001fb0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001fb2:	0000f917          	auipc	s2,0xf
    80001fb6:	c1e90913          	addi	s2,s2,-994 # 80010bd0 <pid_lock>
    80001fba:	854a                	mv	a0,s2
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	c1a080e7          	jalr	-998(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001fc4:	00007797          	auipc	a5,0x7
    80001fc8:	90078793          	addi	a5,a5,-1792 # 800088c4 <nextpid>
    80001fcc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001fce:	0014871b          	addiw	a4,s1,1
    80001fd2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001fd4:	854a                	mv	a0,s2
    80001fd6:	fffff097          	auipc	ra,0xfffff
    80001fda:	cb4080e7          	jalr	-844(ra) # 80000c8a <release>
}
    80001fde:	8526                	mv	a0,s1
    80001fe0:	60e2                	ld	ra,24(sp)
    80001fe2:	6442                	ld	s0,16(sp)
    80001fe4:	64a2                	ld	s1,8(sp)
    80001fe6:	6902                	ld	s2,0(sp)
    80001fe8:	6105                	addi	sp,sp,32
    80001fea:	8082                	ret

0000000080001fec <proc_pagetable>:
{
    80001fec:	1101                	addi	sp,sp,-32
    80001fee:	ec06                	sd	ra,24(sp)
    80001ff0:	e822                	sd	s0,16(sp)
    80001ff2:	e426                	sd	s1,8(sp)
    80001ff4:	e04a                	sd	s2,0(sp)
    80001ff6:	1000                	addi	s0,sp,32
    80001ff8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ffa:	fffff097          	auipc	ra,0xfffff
    80001ffe:	336080e7          	jalr	822(ra) # 80001330 <uvmcreate>
    80002002:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80002004:	c121                	beqz	a0,80002044 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80002006:	4729                	li	a4,10
    80002008:	00005697          	auipc	a3,0x5
    8000200c:	ff868693          	addi	a3,a3,-8 # 80007000 <_trampoline>
    80002010:	6605                	lui	a2,0x1
    80002012:	040005b7          	lui	a1,0x4000
    80002016:	15fd                	addi	a1,a1,-1
    80002018:	05b2                	slli	a1,a1,0xc
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	084080e7          	jalr	132(ra) # 8000109e <mappages>
    80002022:	02054863          	bltz	a0,80002052 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80002026:	4719                	li	a4,6
    80002028:	05893683          	ld	a3,88(s2)
    8000202c:	6605                	lui	a2,0x1
    8000202e:	020005b7          	lui	a1,0x2000
    80002032:	15fd                	addi	a1,a1,-1
    80002034:	05b6                	slli	a1,a1,0xd
    80002036:	8526                	mv	a0,s1
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	066080e7          	jalr	102(ra) # 8000109e <mappages>
    80002040:	02054163          	bltz	a0,80002062 <proc_pagetable+0x76>
}
    80002044:	8526                	mv	a0,s1
    80002046:	60e2                	ld	ra,24(sp)
    80002048:	6442                	ld	s0,16(sp)
    8000204a:	64a2                	ld	s1,8(sp)
    8000204c:	6902                	ld	s2,0(sp)
    8000204e:	6105                	addi	sp,sp,32
    80002050:	8082                	ret
    uvmfree(pagetable, 0);
    80002052:	4581                	li	a1,0
    80002054:	8526                	mv	a0,s1
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	4de080e7          	jalr	1246(ra) # 80001534 <uvmfree>
    return 0;
    8000205e:	4481                	li	s1,0
    80002060:	b7d5                	j	80002044 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002062:	4681                	li	a3,0
    80002064:	4605                	li	a2,1
    80002066:	040005b7          	lui	a1,0x4000
    8000206a:	15fd                	addi	a1,a1,-1
    8000206c:	05b2                	slli	a1,a1,0xc
    8000206e:	8526                	mv	a0,s1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	1f4080e7          	jalr	500(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80002078:	4581                	li	a1,0
    8000207a:	8526                	mv	a0,s1
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	4b8080e7          	jalr	1208(ra) # 80001534 <uvmfree>
    return 0;
    80002084:	4481                	li	s1,0
    80002086:	bf7d                	j	80002044 <proc_pagetable+0x58>

0000000080002088 <proc_freepagetable>:
{
    80002088:	1101                	addi	sp,sp,-32
    8000208a:	ec06                	sd	ra,24(sp)
    8000208c:	e822                	sd	s0,16(sp)
    8000208e:	e426                	sd	s1,8(sp)
    80002090:	e04a                	sd	s2,0(sp)
    80002092:	1000                	addi	s0,sp,32
    80002094:	84aa                	mv	s1,a0
    80002096:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002098:	4681                	li	a3,0
    8000209a:	4605                	li	a2,1
    8000209c:	040005b7          	lui	a1,0x4000
    800020a0:	15fd                	addi	a1,a1,-1
    800020a2:	05b2                	slli	a1,a1,0xc
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	1c0080e7          	jalr	448(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800020ac:	4681                	li	a3,0
    800020ae:	4605                	li	a2,1
    800020b0:	020005b7          	lui	a1,0x2000
    800020b4:	15fd                	addi	a1,a1,-1
    800020b6:	05b6                	slli	a1,a1,0xd
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	1aa080e7          	jalr	426(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    800020c2:	85ca                	mv	a1,s2
    800020c4:	8526                	mv	a0,s1
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	46e080e7          	jalr	1134(ra) # 80001534 <uvmfree>
}
    800020ce:	60e2                	ld	ra,24(sp)
    800020d0:	6442                	ld	s0,16(sp)
    800020d2:	64a2                	ld	s1,8(sp)
    800020d4:	6902                	ld	s2,0(sp)
    800020d6:	6105                	addi	sp,sp,32
    800020d8:	8082                	ret

00000000800020da <freeproc>:
{
    800020da:	1101                	addi	sp,sp,-32
    800020dc:	ec06                	sd	ra,24(sp)
    800020de:	e822                	sd	s0,16(sp)
    800020e0:	e426                	sd	s1,8(sp)
    800020e2:	1000                	addi	s0,sp,32
    800020e4:	84aa                	mv	s1,a0
  if(p->trapframe)
    800020e6:	6d28                	ld	a0,88(a0)
    800020e8:	c509                	beqz	a0,800020f2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	900080e7          	jalr	-1792(ra) # 800009ea <kfree>
  p->trapframe = 0;
    800020f2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    800020f6:	68a8                	ld	a0,80(s1)
    800020f8:	c511                	beqz	a0,80002104 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800020fa:	64ac                	ld	a1,72(s1)
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	f8c080e7          	jalr	-116(ra) # 80002088 <proc_freepagetable>
  printf("NONE\n");
    80002104:	00006517          	auipc	a0,0x6
    80002108:	13450513          	addi	a0,a0,308 # 80008238 <digits+0x1f8>
    8000210c:	ffffe097          	auipc	ra,0xffffe
    80002110:	47c080e7          	jalr	1148(ra) # 80000588 <printf>
  p -> memory_pages_count = 0; 
    80002114:	5604a823          	sw	zero,1392(s1)
  p -> swapped_pages_count = 0;
    80002118:	5604aa23          	sw	zero,1396(s1)
  p -> page_timer = 0; 
    8000211c:	5604ac23          	sw	zero,1400(s1)
  p->pagetable = 0;
    80002120:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80002124:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80002128:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    8000212c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80002130:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80002134:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002138:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    8000213c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80002140:	0004ac23          	sw	zero,24(s1)
}
    80002144:	60e2                	ld	ra,24(sp)
    80002146:	6442                	ld	s0,16(sp)
    80002148:	64a2                	ld	s1,8(sp)
    8000214a:	6105                	addi	sp,sp,32
    8000214c:	8082                	ret

000000008000214e <allocproc>:
{
    8000214e:	1101                	addi	sp,sp,-32
    80002150:	ec06                	sd	ra,24(sp)
    80002152:	e822                	sd	s0,16(sp)
    80002154:	e426                	sd	s1,8(sp)
    80002156:	e04a                	sd	s2,0(sp)
    80002158:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    8000215a:	0000f497          	auipc	s1,0xf
    8000215e:	ea648493          	addi	s1,s1,-346 # 80011000 <proc>
    80002162:	00025917          	auipc	s2,0x25
    80002166:	e9e90913          	addi	s2,s2,-354 # 80027000 <tickslock>
    acquire(&p->lock);
    8000216a:	8526                	mv	a0,s1
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	a6a080e7          	jalr	-1430(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80002174:	4c9c                	lw	a5,24(s1)
    80002176:	cf81                	beqz	a5,8000218e <allocproc+0x40>
      release(&p->lock);
    80002178:	8526                	mv	a0,s1
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	b10080e7          	jalr	-1264(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002182:	58048493          	addi	s1,s1,1408
    80002186:	ff2492e3          	bne	s1,s2,8000216a <allocproc+0x1c>
  return 0;
    8000218a:	4481                	li	s1,0
    8000218c:	a899                	j	800021e2 <allocproc+0x94>
  p->pid = allocpid();
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	e18080e7          	jalr	-488(ra) # 80001fa6 <allocpid>
    80002196:	d888                	sw	a0,48(s1)
  p->state = USED;
    80002198:	4785                	li	a5,1
    8000219a:	cc9c                	sw	a5,24(s1)
  p->page_timer = 0; 
    8000219c:	5604ac23          	sw	zero,1400(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	946080e7          	jalr	-1722(ra) # 80000ae6 <kalloc>
    800021a8:	892a                	mv	s2,a0
    800021aa:	eca8                	sd	a0,88(s1)
    800021ac:	c131                	beqz	a0,800021f0 <allocproc+0xa2>
  p->pagetable = proc_pagetable(p);
    800021ae:	8526                	mv	a0,s1
    800021b0:	00000097          	auipc	ra,0x0
    800021b4:	e3c080e7          	jalr	-452(ra) # 80001fec <proc_pagetable>
    800021b8:	892a                	mv	s2,a0
    800021ba:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    800021bc:	c531                	beqz	a0,80002208 <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    800021be:	07000613          	li	a2,112
    800021c2:	4581                	li	a1,0
    800021c4:	06048513          	addi	a0,s1,96
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	b0a080e7          	jalr	-1270(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    800021d0:	00000797          	auipc	a5,0x0
    800021d4:	d9078793          	addi	a5,a5,-624 # 80001f60 <forkret>
    800021d8:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    800021da:	60bc                	ld	a5,64(s1)
    800021dc:	6705                	lui	a4,0x1
    800021de:	97ba                	add	a5,a5,a4
    800021e0:	f4bc                	sd	a5,104(s1)
}
    800021e2:	8526                	mv	a0,s1
    800021e4:	60e2                	ld	ra,24(sp)
    800021e6:	6442                	ld	s0,16(sp)
    800021e8:	64a2                	ld	s1,8(sp)
    800021ea:	6902                	ld	s2,0(sp)
    800021ec:	6105                	addi	sp,sp,32
    800021ee:	8082                	ret
    freeproc(p);
    800021f0:	8526                	mv	a0,s1
    800021f2:	00000097          	auipc	ra,0x0
    800021f6:	ee8080e7          	jalr	-280(ra) # 800020da <freeproc>
    release(&p->lock);
    800021fa:	8526                	mv	a0,s1
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	a8e080e7          	jalr	-1394(ra) # 80000c8a <release>
    return 0;
    80002204:	84ca                	mv	s1,s2
    80002206:	bff1                	j	800021e2 <allocproc+0x94>
    freeproc(p);
    80002208:	8526                	mv	a0,s1
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	ed0080e7          	jalr	-304(ra) # 800020da <freeproc>
    release(&p->lock);
    80002212:	8526                	mv	a0,s1
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	a76080e7          	jalr	-1418(ra) # 80000c8a <release>
    return 0;
    8000221c:	84ca                	mv	s1,s2
    8000221e:	b7d1                	j	800021e2 <allocproc+0x94>

0000000080002220 <userinit>:
{
    80002220:	1101                	addi	sp,sp,-32
    80002222:	ec06                	sd	ra,24(sp)
    80002224:	e822                	sd	s0,16(sp)
    80002226:	e426                	sd	s1,8(sp)
    80002228:	1000                	addi	s0,sp,32
  p = allocproc();
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	f24080e7          	jalr	-220(ra) # 8000214e <allocproc>
    80002232:	84aa                	mv	s1,a0
  initproc = p;
    80002234:	00006797          	auipc	a5,0x6
    80002238:	72a7b223          	sd	a0,1828(a5) # 80008958 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    8000223c:	03400613          	li	a2,52
    80002240:	00006597          	auipc	a1,0x6
    80002244:	69058593          	addi	a1,a1,1680 # 800088d0 <initcode>
    80002248:	6928                	ld	a0,80(a0)
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	114080e7          	jalr	276(ra) # 8000135e <uvmfirst>
  p->sz = PGSIZE;
    80002252:	6785                	lui	a5,0x1
    80002254:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80002256:	6cb8                	ld	a4,88(s1)
    80002258:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000225c:	6cb8                	ld	a4,88(s1)
    8000225e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002260:	4641                	li	a2,16
    80002262:	00006597          	auipc	a1,0x6
    80002266:	fde58593          	addi	a1,a1,-34 # 80008240 <digits+0x200>
    8000226a:	15848513          	addi	a0,s1,344
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	bae080e7          	jalr	-1106(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80002276:	00006517          	auipc	a0,0x6
    8000227a:	fda50513          	addi	a0,a0,-38 # 80008250 <digits+0x210>
    8000227e:	00002097          	auipc	ra,0x2
    80002282:	106080e7          	jalr	262(ra) # 80004384 <namei>
    80002286:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    8000228a:	478d                	li	a5,3
    8000228c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
}
    80002298:	60e2                	ld	ra,24(sp)
    8000229a:	6442                	ld	s0,16(sp)
    8000229c:	64a2                	ld	s1,8(sp)
    8000229e:	6105                	addi	sp,sp,32
    800022a0:	8082                	ret

00000000800022a2 <growproc>:
{
    800022a2:	1101                	addi	sp,sp,-32
    800022a4:	ec06                	sd	ra,24(sp)
    800022a6:	e822                	sd	s0,16(sp)
    800022a8:	e426                	sd	s1,8(sp)
    800022aa:	e04a                	sd	s2,0(sp)
    800022ac:	1000                	addi	s0,sp,32
    800022ae:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	c78080e7          	jalr	-904(ra) # 80001f28 <myproc>
    800022b8:	84aa                	mv	s1,a0
  sz = p->sz;
    800022ba:	652c                	ld	a1,72(a0)
  if(n > 0){
    800022bc:	01204c63          	bgtz	s2,800022d4 <growproc+0x32>
  } else if(n < 0){
    800022c0:	02094663          	bltz	s2,800022ec <growproc+0x4a>
  p->sz = sz;
    800022c4:	e4ac                	sd	a1,72(s1)
  return 0;
    800022c6:	4501                	li	a0,0
}
    800022c8:	60e2                	ld	ra,24(sp)
    800022ca:	6442                	ld	s0,16(sp)
    800022cc:	64a2                	ld	s1,8(sp)
    800022ce:	6902                	ld	s2,0(sp)
    800022d0:	6105                	addi	sp,sp,32
    800022d2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    800022d4:	4691                	li	a3,4
    800022d6:	00b90633          	add	a2,s2,a1
    800022da:	6928                	ld	a0,80(a0)
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	13c080e7          	jalr	316(ra) # 80001418 <uvmalloc>
    800022e4:	85aa                	mv	a1,a0
    800022e6:	fd79                	bnez	a0,800022c4 <growproc+0x22>
      return -1;
    800022e8:	557d                	li	a0,-1
    800022ea:	bff9                	j	800022c8 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800022ec:	00b90633          	add	a2,s2,a1
    800022f0:	6928                	ld	a0,80(a0)
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	0de080e7          	jalr	222(ra) # 800013d0 <uvmdealloc>
    800022fa:	85aa                	mv	a1,a0
    800022fc:	b7e1                	j	800022c4 <growproc+0x22>

00000000800022fe <fork>:
{
    800022fe:	7139                	addi	sp,sp,-64
    80002300:	fc06                	sd	ra,56(sp)
    80002302:	f822                	sd	s0,48(sp)
    80002304:	f426                	sd	s1,40(sp)
    80002306:	f04a                	sd	s2,32(sp)
    80002308:	ec4e                	sd	s3,24(sp)
    8000230a:	e852                	sd	s4,16(sp)
    8000230c:	e456                	sd	s5,8(sp)
    8000230e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002310:	00000097          	auipc	ra,0x0
    80002314:	c18080e7          	jalr	-1000(ra) # 80001f28 <myproc>
    80002318:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    8000231a:	00000097          	auipc	ra,0x0
    8000231e:	e34080e7          	jalr	-460(ra) # 8000214e <allocproc>
    80002322:	10050c63          	beqz	a0,8000243a <fork+0x13c>
    80002326:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002328:	048ab603          	ld	a2,72(s5)
    8000232c:	692c                	ld	a1,80(a0)
    8000232e:	050ab503          	ld	a0,80(s5)
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	23a080e7          	jalr	570(ra) # 8000156c <uvmcopy>
    8000233a:	04054863          	bltz	a0,8000238a <fork+0x8c>
  np->sz = p->sz;
    8000233e:	048ab783          	ld	a5,72(s5)
    80002342:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80002346:	058ab683          	ld	a3,88(s5)
    8000234a:	87b6                	mv	a5,a3
    8000234c:	058a3703          	ld	a4,88(s4)
    80002350:	12068693          	addi	a3,a3,288
    80002354:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002358:	6788                	ld	a0,8(a5)
    8000235a:	6b8c                	ld	a1,16(a5)
    8000235c:	6f90                	ld	a2,24(a5)
    8000235e:	01073023          	sd	a6,0(a4)
    80002362:	e708                	sd	a0,8(a4)
    80002364:	eb0c                	sd	a1,16(a4)
    80002366:	ef10                	sd	a2,24(a4)
    80002368:	02078793          	addi	a5,a5,32
    8000236c:	02070713          	addi	a4,a4,32
    80002370:	fed792e3          	bne	a5,a3,80002354 <fork+0x56>
  np->trapframe->a0 = 0;
    80002374:	058a3783          	ld	a5,88(s4)
    80002378:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000237c:	0d0a8493          	addi	s1,s5,208
    80002380:	0d0a0913          	addi	s2,s4,208
    80002384:	150a8993          	addi	s3,s5,336
    80002388:	a00d                	j	800023aa <fork+0xac>
    freeproc(np);
    8000238a:	8552                	mv	a0,s4
    8000238c:	00000097          	auipc	ra,0x0
    80002390:	d4e080e7          	jalr	-690(ra) # 800020da <freeproc>
    release(&np->lock);
    80002394:	8552                	mv	a0,s4
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	8f4080e7          	jalr	-1804(ra) # 80000c8a <release>
    return -1;
    8000239e:	597d                	li	s2,-1
    800023a0:	a059                	j	80002426 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    800023a2:	04a1                	addi	s1,s1,8
    800023a4:	0921                	addi	s2,s2,8
    800023a6:	01348b63          	beq	s1,s3,800023bc <fork+0xbe>
    if(p->ofile[i])
    800023aa:	6088                	ld	a0,0(s1)
    800023ac:	d97d                	beqz	a0,800023a2 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    800023ae:	00003097          	auipc	ra,0x3
    800023b2:	97e080e7          	jalr	-1666(ra) # 80004d2c <filedup>
    800023b6:	00a93023          	sd	a0,0(s2)
    800023ba:	b7e5                	j	800023a2 <fork+0xa4>
  np->cwd = idup(p->cwd);
    800023bc:	150ab503          	ld	a0,336(s5)
    800023c0:	00001097          	auipc	ra,0x1
    800023c4:	7e0080e7          	jalr	2016(ra) # 80003ba0 <idup>
    800023c8:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800023cc:	4641                	li	a2,16
    800023ce:	158a8593          	addi	a1,s5,344
    800023d2:	158a0513          	addi	a0,s4,344
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	a46080e7          	jalr	-1466(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    800023de:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    800023e2:	8552                	mv	a0,s4
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	8a6080e7          	jalr	-1882(ra) # 80000c8a <release>
  acquire(&wait_lock);
    800023ec:	0000e497          	auipc	s1,0xe
    800023f0:	7fc48493          	addi	s1,s1,2044 # 80010be8 <wait_lock>
    800023f4:	8526                	mv	a0,s1
    800023f6:	ffffe097          	auipc	ra,0xffffe
    800023fa:	7e0080e7          	jalr	2016(ra) # 80000bd6 <acquire>
  np->parent = p;
    800023fe:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80002402:	8526                	mv	a0,s1
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	886080e7          	jalr	-1914(ra) # 80000c8a <release>
  acquire(&np->lock);
    8000240c:	8552                	mv	a0,s4
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	7c8080e7          	jalr	1992(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80002416:	478d                	li	a5,3
    80002418:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    8000241c:	8552                	mv	a0,s4
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	86c080e7          	jalr	-1940(ra) # 80000c8a <release>
}
    80002426:	854a                	mv	a0,s2
    80002428:	70e2                	ld	ra,56(sp)
    8000242a:	7442                	ld	s0,48(sp)
    8000242c:	74a2                	ld	s1,40(sp)
    8000242e:	7902                	ld	s2,32(sp)
    80002430:	69e2                	ld	s3,24(sp)
    80002432:	6a42                	ld	s4,16(sp)
    80002434:	6aa2                	ld	s5,8(sp)
    80002436:	6121                	addi	sp,sp,64
    80002438:	8082                	ret
    return -1;
    8000243a:	597d                	li	s2,-1
    8000243c:	b7ed                	j	80002426 <fork+0x128>

000000008000243e <scheduler>:
{
    8000243e:	7139                	addi	sp,sp,-64
    80002440:	fc06                	sd	ra,56(sp)
    80002442:	f822                	sd	s0,48(sp)
    80002444:	f426                	sd	s1,40(sp)
    80002446:	f04a                	sd	s2,32(sp)
    80002448:	ec4e                	sd	s3,24(sp)
    8000244a:	e852                	sd	s4,16(sp)
    8000244c:	e456                	sd	s5,8(sp)
    8000244e:	e05a                	sd	s6,0(sp)
    80002450:	0080                	addi	s0,sp,64
    80002452:	8792                	mv	a5,tp
  int id = r_tp();
    80002454:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002456:	00779a93          	slli	s5,a5,0x7
    8000245a:	0000e717          	auipc	a4,0xe
    8000245e:	77670713          	addi	a4,a4,1910 # 80010bd0 <pid_lock>
    80002462:	9756                	add	a4,a4,s5
    80002464:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002468:	0000e717          	auipc	a4,0xe
    8000246c:	7a070713          	addi	a4,a4,1952 # 80010c08 <cpus+0x8>
    80002470:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002472:	498d                	li	s3,3
        p->state = RUNNING;
    80002474:	4b11                	li	s6,4
        c->proc = p;
    80002476:	079e                	slli	a5,a5,0x7
    80002478:	0000ea17          	auipc	s4,0xe
    8000247c:	758a0a13          	addi	s4,s4,1880 # 80010bd0 <pid_lock>
    80002480:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002482:	00025917          	auipc	s2,0x25
    80002486:	b7e90913          	addi	s2,s2,-1154 # 80027000 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000248a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000248e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002492:	10079073          	csrw	sstatus,a5
    80002496:	0000f497          	auipc	s1,0xf
    8000249a:	b6a48493          	addi	s1,s1,-1174 # 80011000 <proc>
    8000249e:	a811                	j	800024b2 <scheduler+0x74>
      release(&p->lock);
    800024a0:	8526                	mv	a0,s1
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	7e8080e7          	jalr	2024(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800024aa:	58048493          	addi	s1,s1,1408
    800024ae:	fd248ee3          	beq	s1,s2,8000248a <scheduler+0x4c>
      acquire(&p->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	722080e7          	jalr	1826(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    800024bc:	4c9c                	lw	a5,24(s1)
    800024be:	ff3791e3          	bne	a5,s3,800024a0 <scheduler+0x62>
        p->state = RUNNING;
    800024c2:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800024c6:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800024ca:	06048593          	addi	a1,s1,96
    800024ce:	8556                	mv	a0,s5
    800024d0:	00000097          	auipc	ra,0x0
    800024d4:	698080e7          	jalr	1688(ra) # 80002b68 <swtch>
        c->proc = 0;
    800024d8:	020a3823          	sd	zero,48(s4)
    800024dc:	b7d1                	j	800024a0 <scheduler+0x62>

00000000800024de <sched>:
{
    800024de:	7179                	addi	sp,sp,-48
    800024e0:	f406                	sd	ra,40(sp)
    800024e2:	f022                	sd	s0,32(sp)
    800024e4:	ec26                	sd	s1,24(sp)
    800024e6:	e84a                	sd	s2,16(sp)
    800024e8:	e44e                	sd	s3,8(sp)
    800024ea:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800024ec:	00000097          	auipc	ra,0x0
    800024f0:	a3c080e7          	jalr	-1476(ra) # 80001f28 <myproc>
    800024f4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	666080e7          	jalr	1638(ra) # 80000b5c <holding>
    800024fe:	c93d                	beqz	a0,80002574 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002500:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002502:	2781                	sext.w	a5,a5
    80002504:	079e                	slli	a5,a5,0x7
    80002506:	0000e717          	auipc	a4,0xe
    8000250a:	6ca70713          	addi	a4,a4,1738 # 80010bd0 <pid_lock>
    8000250e:	97ba                	add	a5,a5,a4
    80002510:	0a87a703          	lw	a4,168(a5)
    80002514:	4785                	li	a5,1
    80002516:	06f71763          	bne	a4,a5,80002584 <sched+0xa6>
  if(p->state == RUNNING)
    8000251a:	4c98                	lw	a4,24(s1)
    8000251c:	4791                	li	a5,4
    8000251e:	06f70b63          	beq	a4,a5,80002594 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002522:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002526:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002528:	efb5                	bnez	a5,800025a4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000252a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000252c:	0000e917          	auipc	s2,0xe
    80002530:	6a490913          	addi	s2,s2,1700 # 80010bd0 <pid_lock>
    80002534:	2781                	sext.w	a5,a5
    80002536:	079e                	slli	a5,a5,0x7
    80002538:	97ca                	add	a5,a5,s2
    8000253a:	0ac7a983          	lw	s3,172(a5)
    8000253e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002540:	2781                	sext.w	a5,a5
    80002542:	079e                	slli	a5,a5,0x7
    80002544:	0000e597          	auipc	a1,0xe
    80002548:	6c458593          	addi	a1,a1,1732 # 80010c08 <cpus+0x8>
    8000254c:	95be                	add	a1,a1,a5
    8000254e:	06048513          	addi	a0,s1,96
    80002552:	00000097          	auipc	ra,0x0
    80002556:	616080e7          	jalr	1558(ra) # 80002b68 <swtch>
    8000255a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000255c:	2781                	sext.w	a5,a5
    8000255e:	079e                	slli	a5,a5,0x7
    80002560:	97ca                	add	a5,a5,s2
    80002562:	0b37a623          	sw	s3,172(a5)
}
    80002566:	70a2                	ld	ra,40(sp)
    80002568:	7402                	ld	s0,32(sp)
    8000256a:	64e2                	ld	s1,24(sp)
    8000256c:	6942                	ld	s2,16(sp)
    8000256e:	69a2                	ld	s3,8(sp)
    80002570:	6145                	addi	sp,sp,48
    80002572:	8082                	ret
    panic("sched p->lock");
    80002574:	00006517          	auipc	a0,0x6
    80002578:	ce450513          	addi	a0,a0,-796 # 80008258 <digits+0x218>
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	fc2080e7          	jalr	-62(ra) # 8000053e <panic>
    panic("sched locks");
    80002584:	00006517          	auipc	a0,0x6
    80002588:	ce450513          	addi	a0,a0,-796 # 80008268 <digits+0x228>
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	fb2080e7          	jalr	-78(ra) # 8000053e <panic>
    panic("sched running");
    80002594:	00006517          	auipc	a0,0x6
    80002598:	ce450513          	addi	a0,a0,-796 # 80008278 <digits+0x238>
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	fa2080e7          	jalr	-94(ra) # 8000053e <panic>
    panic("sched interruptible");
    800025a4:	00006517          	auipc	a0,0x6
    800025a8:	ce450513          	addi	a0,a0,-796 # 80008288 <digits+0x248>
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	f92080e7          	jalr	-110(ra) # 8000053e <panic>

00000000800025b4 <yield>:
{
    800025b4:	1101                	addi	sp,sp,-32
    800025b6:	ec06                	sd	ra,24(sp)
    800025b8:	e822                	sd	s0,16(sp)
    800025ba:	e426                	sd	s1,8(sp)
    800025bc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800025be:	00000097          	auipc	ra,0x0
    800025c2:	96a080e7          	jalr	-1686(ra) # 80001f28 <myproc>
    800025c6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	60e080e7          	jalr	1550(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800025d0:	478d                	li	a5,3
    800025d2:	cc9c                	sw	a5,24(s1)
  sched();
    800025d4:	00000097          	auipc	ra,0x0
    800025d8:	f0a080e7          	jalr	-246(ra) # 800024de <sched>
  release(&p->lock);
    800025dc:	8526                	mv	a0,s1
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	6ac080e7          	jalr	1708(ra) # 80000c8a <release>
}
    800025e6:	60e2                	ld	ra,24(sp)
    800025e8:	6442                	ld	s0,16(sp)
    800025ea:	64a2                	ld	s1,8(sp)
    800025ec:	6105                	addi	sp,sp,32
    800025ee:	8082                	ret

00000000800025f0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800025f0:	7179                	addi	sp,sp,-48
    800025f2:	f406                	sd	ra,40(sp)
    800025f4:	f022                	sd	s0,32(sp)
    800025f6:	ec26                	sd	s1,24(sp)
    800025f8:	e84a                	sd	s2,16(sp)
    800025fa:	e44e                	sd	s3,8(sp)
    800025fc:	1800                	addi	s0,sp,48
    800025fe:	89aa                	mv	s3,a0
    80002600:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002602:	00000097          	auipc	ra,0x0
    80002606:	926080e7          	jalr	-1754(ra) # 80001f28 <myproc>
    8000260a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	5ca080e7          	jalr	1482(ra) # 80000bd6 <acquire>
  release(lk);
    80002614:	854a                	mv	a0,s2
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	674080e7          	jalr	1652(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000261e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002622:	4789                	li	a5,2
    80002624:	cc9c                	sw	a5,24(s1)

  sched();
    80002626:	00000097          	auipc	ra,0x0
    8000262a:	eb8080e7          	jalr	-328(ra) # 800024de <sched>

  // Tidy up.
  p->chan = 0;
    8000262e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002632:	8526                	mv	a0,s1
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	656080e7          	jalr	1622(ra) # 80000c8a <release>
  acquire(lk);
    8000263c:	854a                	mv	a0,s2
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	598080e7          	jalr	1432(ra) # 80000bd6 <acquire>
}
    80002646:	70a2                	ld	ra,40(sp)
    80002648:	7402                	ld	s0,32(sp)
    8000264a:	64e2                	ld	s1,24(sp)
    8000264c:	6942                	ld	s2,16(sp)
    8000264e:	69a2                	ld	s3,8(sp)
    80002650:	6145                	addi	sp,sp,48
    80002652:	8082                	ret

0000000080002654 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002654:	7139                	addi	sp,sp,-64
    80002656:	fc06                	sd	ra,56(sp)
    80002658:	f822                	sd	s0,48(sp)
    8000265a:	f426                	sd	s1,40(sp)
    8000265c:	f04a                	sd	s2,32(sp)
    8000265e:	ec4e                	sd	s3,24(sp)
    80002660:	e852                	sd	s4,16(sp)
    80002662:	e456                	sd	s5,8(sp)
    80002664:	0080                	addi	s0,sp,64
    80002666:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002668:	0000f497          	auipc	s1,0xf
    8000266c:	99848493          	addi	s1,s1,-1640 # 80011000 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002670:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002672:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002674:	00025917          	auipc	s2,0x25
    80002678:	98c90913          	addi	s2,s2,-1652 # 80027000 <tickslock>
    8000267c:	a811                	j	80002690 <wakeup+0x3c>
      }
      release(&p->lock);
    8000267e:	8526                	mv	a0,s1
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	60a080e7          	jalr	1546(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002688:	58048493          	addi	s1,s1,1408
    8000268c:	03248663          	beq	s1,s2,800026b8 <wakeup+0x64>
    if(p != myproc()){
    80002690:	00000097          	auipc	ra,0x0
    80002694:	898080e7          	jalr	-1896(ra) # 80001f28 <myproc>
    80002698:	fea488e3          	beq	s1,a0,80002688 <wakeup+0x34>
      acquire(&p->lock);
    8000269c:	8526                	mv	a0,s1
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	538080e7          	jalr	1336(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800026a6:	4c9c                	lw	a5,24(s1)
    800026a8:	fd379be3          	bne	a5,s3,8000267e <wakeup+0x2a>
    800026ac:	709c                	ld	a5,32(s1)
    800026ae:	fd4798e3          	bne	a5,s4,8000267e <wakeup+0x2a>
        p->state = RUNNABLE;
    800026b2:	0154ac23          	sw	s5,24(s1)
    800026b6:	b7e1                	j	8000267e <wakeup+0x2a>
    }
  }
}
    800026b8:	70e2                	ld	ra,56(sp)
    800026ba:	7442                	ld	s0,48(sp)
    800026bc:	74a2                	ld	s1,40(sp)
    800026be:	7902                	ld	s2,32(sp)
    800026c0:	69e2                	ld	s3,24(sp)
    800026c2:	6a42                	ld	s4,16(sp)
    800026c4:	6aa2                	ld	s5,8(sp)
    800026c6:	6121                	addi	sp,sp,64
    800026c8:	8082                	ret

00000000800026ca <reparent>:
{
    800026ca:	7179                	addi	sp,sp,-48
    800026cc:	f406                	sd	ra,40(sp)
    800026ce:	f022                	sd	s0,32(sp)
    800026d0:	ec26                	sd	s1,24(sp)
    800026d2:	e84a                	sd	s2,16(sp)
    800026d4:	e44e                	sd	s3,8(sp)
    800026d6:	e052                	sd	s4,0(sp)
    800026d8:	1800                	addi	s0,sp,48
    800026da:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800026dc:	0000f497          	auipc	s1,0xf
    800026e0:	92448493          	addi	s1,s1,-1756 # 80011000 <proc>
      pp->parent = initproc;
    800026e4:	00006a17          	auipc	s4,0x6
    800026e8:	274a0a13          	addi	s4,s4,628 # 80008958 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800026ec:	00025997          	auipc	s3,0x25
    800026f0:	91498993          	addi	s3,s3,-1772 # 80027000 <tickslock>
    800026f4:	a029                	j	800026fe <reparent+0x34>
    800026f6:	58048493          	addi	s1,s1,1408
    800026fa:	01348d63          	beq	s1,s3,80002714 <reparent+0x4a>
    if(pp->parent == p){
    800026fe:	7c9c                	ld	a5,56(s1)
    80002700:	ff279be3          	bne	a5,s2,800026f6 <reparent+0x2c>
      pp->parent = initproc;
    80002704:	000a3503          	ld	a0,0(s4)
    80002708:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000270a:	00000097          	auipc	ra,0x0
    8000270e:	f4a080e7          	jalr	-182(ra) # 80002654 <wakeup>
    80002712:	b7d5                	j	800026f6 <reparent+0x2c>
}
    80002714:	70a2                	ld	ra,40(sp)
    80002716:	7402                	ld	s0,32(sp)
    80002718:	64e2                	ld	s1,24(sp)
    8000271a:	6942                	ld	s2,16(sp)
    8000271c:	69a2                	ld	s3,8(sp)
    8000271e:	6a02                	ld	s4,0(sp)
    80002720:	6145                	addi	sp,sp,48
    80002722:	8082                	ret

0000000080002724 <exit>:
{
    80002724:	7179                	addi	sp,sp,-48
    80002726:	f406                	sd	ra,40(sp)
    80002728:	f022                	sd	s0,32(sp)
    8000272a:	ec26                	sd	s1,24(sp)
    8000272c:	e84a                	sd	s2,16(sp)
    8000272e:	e44e                	sd	s3,8(sp)
    80002730:	e052                	sd	s4,0(sp)
    80002732:	1800                	addi	s0,sp,48
    80002734:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002736:	fffff097          	auipc	ra,0xfffff
    8000273a:	7f2080e7          	jalr	2034(ra) # 80001f28 <myproc>
    8000273e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002740:	00006797          	auipc	a5,0x6
    80002744:	2187b783          	ld	a5,536(a5) # 80008958 <initproc>
    80002748:	0d050493          	addi	s1,a0,208
    8000274c:	15050913          	addi	s2,a0,336
    80002750:	02a79363          	bne	a5,a0,80002776 <exit+0x52>
    panic("init exiting");
    80002754:	00006517          	auipc	a0,0x6
    80002758:	b4c50513          	addi	a0,a0,-1204 # 800082a0 <digits+0x260>
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	de2080e7          	jalr	-542(ra) # 8000053e <panic>
      fileclose(f);
    80002764:	00002097          	auipc	ra,0x2
    80002768:	61a080e7          	jalr	1562(ra) # 80004d7e <fileclose>
      p->ofile[fd] = 0;
    8000276c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002770:	04a1                	addi	s1,s1,8
    80002772:	01248563          	beq	s1,s2,8000277c <exit+0x58>
    if(p->ofile[fd]){
    80002776:	6088                	ld	a0,0(s1)
    80002778:	f575                	bnez	a0,80002764 <exit+0x40>
    8000277a:	bfdd                	j	80002770 <exit+0x4c>
  if ( p -> pid > 2 )
    8000277c:	0309a703          	lw	a4,48(s3)
    80002780:	4789                	li	a5,2
    80002782:	08e7c163          	blt	a5,a4,80002804 <exit+0xe0>
  begin_op();
    80002786:	00002097          	auipc	ra,0x2
    8000278a:	12c080e7          	jalr	300(ra) # 800048b2 <begin_op>
  iput(p->cwd);
    8000278e:	1509b503          	ld	a0,336(s3)
    80002792:	00001097          	auipc	ra,0x1
    80002796:	606080e7          	jalr	1542(ra) # 80003d98 <iput>
  end_op();
    8000279a:	00002097          	auipc	ra,0x2
    8000279e:	198080e7          	jalr	408(ra) # 80004932 <end_op>
  p->cwd = 0;
    800027a2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800027a6:	0000e497          	auipc	s1,0xe
    800027aa:	44248493          	addi	s1,s1,1090 # 80010be8 <wait_lock>
    800027ae:	8526                	mv	a0,s1
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	426080e7          	jalr	1062(ra) # 80000bd6 <acquire>
  reparent(p);
    800027b8:	854e                	mv	a0,s3
    800027ba:	00000097          	auipc	ra,0x0
    800027be:	f10080e7          	jalr	-240(ra) # 800026ca <reparent>
  wakeup(p->parent);
    800027c2:	0389b503          	ld	a0,56(s3)
    800027c6:	00000097          	auipc	ra,0x0
    800027ca:	e8e080e7          	jalr	-370(ra) # 80002654 <wakeup>
  acquire(&p->lock);
    800027ce:	854e                	mv	a0,s3
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	406080e7          	jalr	1030(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800027d8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800027dc:	4795                	li	a5,5
    800027de:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800027e2:	8526                	mv	a0,s1
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	4a6080e7          	jalr	1190(ra) # 80000c8a <release>
  sched();
    800027ec:	00000097          	auipc	ra,0x0
    800027f0:	cf2080e7          	jalr	-782(ra) # 800024de <sched>
  panic("zombie exit");
    800027f4:	00006517          	auipc	a0,0x6
    800027f8:	abc50513          	addi	a0,a0,-1348 # 800082b0 <digits+0x270>
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	d42080e7          	jalr	-702(ra) # 8000053e <panic>
    removeSwapFile(p); 
    80002804:	854e                	mv	a0,s3
    80002806:	00002097          	auipc	ra,0x2
    8000280a:	c2a080e7          	jalr	-982(ra) # 80004430 <removeSwapFile>
    8000280e:	bfa5                	j	80002786 <exit+0x62>

0000000080002810 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002810:	7179                	addi	sp,sp,-48
    80002812:	f406                	sd	ra,40(sp)
    80002814:	f022                	sd	s0,32(sp)
    80002816:	ec26                	sd	s1,24(sp)
    80002818:	e84a                	sd	s2,16(sp)
    8000281a:	e44e                	sd	s3,8(sp)
    8000281c:	1800                	addi	s0,sp,48
    8000281e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002820:	0000e497          	auipc	s1,0xe
    80002824:	7e048493          	addi	s1,s1,2016 # 80011000 <proc>
    80002828:	00024997          	auipc	s3,0x24
    8000282c:	7d898993          	addi	s3,s3,2008 # 80027000 <tickslock>
    acquire(&p->lock);
    80002830:	8526                	mv	a0,s1
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	3a4080e7          	jalr	932(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    8000283a:	589c                	lw	a5,48(s1)
    8000283c:	01278d63          	beq	a5,s2,80002856 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002840:	8526                	mv	a0,s1
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	448080e7          	jalr	1096(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000284a:	58048493          	addi	s1,s1,1408
    8000284e:	ff3491e3          	bne	s1,s3,80002830 <kill+0x20>
  }
  return -1;
    80002852:	557d                	li	a0,-1
    80002854:	a829                	j	8000286e <kill+0x5e>
      p->killed = 1;
    80002856:	4785                	li	a5,1
    80002858:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000285a:	4c98                	lw	a4,24(s1)
    8000285c:	4789                	li	a5,2
    8000285e:	00f70f63          	beq	a4,a5,8000287c <kill+0x6c>
      release(&p->lock);
    80002862:	8526                	mv	a0,s1
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	426080e7          	jalr	1062(ra) # 80000c8a <release>
      return 0;
    8000286c:	4501                	li	a0,0
}
    8000286e:	70a2                	ld	ra,40(sp)
    80002870:	7402                	ld	s0,32(sp)
    80002872:	64e2                	ld	s1,24(sp)
    80002874:	6942                	ld	s2,16(sp)
    80002876:	69a2                	ld	s3,8(sp)
    80002878:	6145                	addi	sp,sp,48
    8000287a:	8082                	ret
        p->state = RUNNABLE;
    8000287c:	478d                	li	a5,3
    8000287e:	cc9c                	sw	a5,24(s1)
    80002880:	b7cd                	j	80002862 <kill+0x52>

0000000080002882 <setkilled>:

void
setkilled(struct proc *p)
{
    80002882:	1101                	addi	sp,sp,-32
    80002884:	ec06                	sd	ra,24(sp)
    80002886:	e822                	sd	s0,16(sp)
    80002888:	e426                	sd	s1,8(sp)
    8000288a:	1000                	addi	s0,sp,32
    8000288c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	348080e7          	jalr	840(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002896:	4785                	li	a5,1
    80002898:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000289a:	8526                	mv	a0,s1
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	3ee080e7          	jalr	1006(ra) # 80000c8a <release>
}
    800028a4:	60e2                	ld	ra,24(sp)
    800028a6:	6442                	ld	s0,16(sp)
    800028a8:	64a2                	ld	s1,8(sp)
    800028aa:	6105                	addi	sp,sp,32
    800028ac:	8082                	ret

00000000800028ae <killed>:

int
killed(struct proc *p)
{
    800028ae:	1101                	addi	sp,sp,-32
    800028b0:	ec06                	sd	ra,24(sp)
    800028b2:	e822                	sd	s0,16(sp)
    800028b4:	e426                	sd	s1,8(sp)
    800028b6:	e04a                	sd	s2,0(sp)
    800028b8:	1000                	addi	s0,sp,32
    800028ba:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	31a080e7          	jalr	794(ra) # 80000bd6 <acquire>
  k = p->killed;
    800028c4:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800028c8:	8526                	mv	a0,s1
    800028ca:	ffffe097          	auipc	ra,0xffffe
    800028ce:	3c0080e7          	jalr	960(ra) # 80000c8a <release>
  return k;
}
    800028d2:	854a                	mv	a0,s2
    800028d4:	60e2                	ld	ra,24(sp)
    800028d6:	6442                	ld	s0,16(sp)
    800028d8:	64a2                	ld	s1,8(sp)
    800028da:	6902                	ld	s2,0(sp)
    800028dc:	6105                	addi	sp,sp,32
    800028de:	8082                	ret

00000000800028e0 <wait>:
{
    800028e0:	715d                	addi	sp,sp,-80
    800028e2:	e486                	sd	ra,72(sp)
    800028e4:	e0a2                	sd	s0,64(sp)
    800028e6:	fc26                	sd	s1,56(sp)
    800028e8:	f84a                	sd	s2,48(sp)
    800028ea:	f44e                	sd	s3,40(sp)
    800028ec:	f052                	sd	s4,32(sp)
    800028ee:	ec56                	sd	s5,24(sp)
    800028f0:	e85a                	sd	s6,16(sp)
    800028f2:	e45e                	sd	s7,8(sp)
    800028f4:	e062                	sd	s8,0(sp)
    800028f6:	0880                	addi	s0,sp,80
    800028f8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800028fa:	fffff097          	auipc	ra,0xfffff
    800028fe:	62e080e7          	jalr	1582(ra) # 80001f28 <myproc>
    80002902:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002904:	0000e517          	auipc	a0,0xe
    80002908:	2e450513          	addi	a0,a0,740 # 80010be8 <wait_lock>
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	2ca080e7          	jalr	714(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002914:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002916:	4a15                	li	s4,5
        havekids = 1;
    80002918:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000291a:	00024997          	auipc	s3,0x24
    8000291e:	6e698993          	addi	s3,s3,1766 # 80027000 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002922:	0000ec17          	auipc	s8,0xe
    80002926:	2c6c0c13          	addi	s8,s8,710 # 80010be8 <wait_lock>
    havekids = 0;
    8000292a:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000292c:	0000e497          	auipc	s1,0xe
    80002930:	6d448493          	addi	s1,s1,1748 # 80011000 <proc>
    80002934:	a0bd                	j	800029a2 <wait+0xc2>
          pid = pp->pid;
    80002936:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000293a:	000b0e63          	beqz	s6,80002956 <wait+0x76>
    8000293e:	4691                	li	a3,4
    80002940:	02c48613          	addi	a2,s1,44
    80002944:	85da                	mv	a1,s6
    80002946:	05093503          	ld	a0,80(s2)
    8000294a:	fffff097          	auipc	ra,0xfffff
    8000294e:	d26080e7          	jalr	-730(ra) # 80001670 <copyout>
    80002952:	02054563          	bltz	a0,8000297c <wait+0x9c>
          freeproc(pp);
    80002956:	8526                	mv	a0,s1
    80002958:	fffff097          	auipc	ra,0xfffff
    8000295c:	782080e7          	jalr	1922(ra) # 800020da <freeproc>
          release(&pp->lock);
    80002960:	8526                	mv	a0,s1
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	328080e7          	jalr	808(ra) # 80000c8a <release>
          release(&wait_lock);
    8000296a:	0000e517          	auipc	a0,0xe
    8000296e:	27e50513          	addi	a0,a0,638 # 80010be8 <wait_lock>
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	318080e7          	jalr	792(ra) # 80000c8a <release>
          return pid;
    8000297a:	a0b5                	j	800029e6 <wait+0x106>
            release(&pp->lock);
    8000297c:	8526                	mv	a0,s1
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	30c080e7          	jalr	780(ra) # 80000c8a <release>
            release(&wait_lock);
    80002986:	0000e517          	auipc	a0,0xe
    8000298a:	26250513          	addi	a0,a0,610 # 80010be8 <wait_lock>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	2fc080e7          	jalr	764(ra) # 80000c8a <release>
            return -1;
    80002996:	59fd                	li	s3,-1
    80002998:	a0b9                	j	800029e6 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000299a:	58048493          	addi	s1,s1,1408
    8000299e:	03348463          	beq	s1,s3,800029c6 <wait+0xe6>
      if(pp->parent == p){
    800029a2:	7c9c                	ld	a5,56(s1)
    800029a4:	ff279be3          	bne	a5,s2,8000299a <wait+0xba>
        acquire(&pp->lock);
    800029a8:	8526                	mv	a0,s1
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	22c080e7          	jalr	556(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    800029b2:	4c9c                	lw	a5,24(s1)
    800029b4:	f94781e3          	beq	a5,s4,80002936 <wait+0x56>
        release(&pp->lock);
    800029b8:	8526                	mv	a0,s1
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	2d0080e7          	jalr	720(ra) # 80000c8a <release>
        havekids = 1;
    800029c2:	8756                	mv	a4,s5
    800029c4:	bfd9                	j	8000299a <wait+0xba>
    if(!havekids || killed(p)){
    800029c6:	c719                	beqz	a4,800029d4 <wait+0xf4>
    800029c8:	854a                	mv	a0,s2
    800029ca:	00000097          	auipc	ra,0x0
    800029ce:	ee4080e7          	jalr	-284(ra) # 800028ae <killed>
    800029d2:	c51d                	beqz	a0,80002a00 <wait+0x120>
      release(&wait_lock);
    800029d4:	0000e517          	auipc	a0,0xe
    800029d8:	21450513          	addi	a0,a0,532 # 80010be8 <wait_lock>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	2ae080e7          	jalr	686(ra) # 80000c8a <release>
      return -1;
    800029e4:	59fd                	li	s3,-1
}
    800029e6:	854e                	mv	a0,s3
    800029e8:	60a6                	ld	ra,72(sp)
    800029ea:	6406                	ld	s0,64(sp)
    800029ec:	74e2                	ld	s1,56(sp)
    800029ee:	7942                	ld	s2,48(sp)
    800029f0:	79a2                	ld	s3,40(sp)
    800029f2:	7a02                	ld	s4,32(sp)
    800029f4:	6ae2                	ld	s5,24(sp)
    800029f6:	6b42                	ld	s6,16(sp)
    800029f8:	6ba2                	ld	s7,8(sp)
    800029fa:	6c02                	ld	s8,0(sp)
    800029fc:	6161                	addi	sp,sp,80
    800029fe:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002a00:	85e2                	mv	a1,s8
    80002a02:	854a                	mv	a0,s2
    80002a04:	00000097          	auipc	ra,0x0
    80002a08:	bec080e7          	jalr	-1044(ra) # 800025f0 <sleep>
    havekids = 0;
    80002a0c:	bf39                	j	8000292a <wait+0x4a>

0000000080002a0e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002a0e:	7179                	addi	sp,sp,-48
    80002a10:	f406                	sd	ra,40(sp)
    80002a12:	f022                	sd	s0,32(sp)
    80002a14:	ec26                	sd	s1,24(sp)
    80002a16:	e84a                	sd	s2,16(sp)
    80002a18:	e44e                	sd	s3,8(sp)
    80002a1a:	e052                	sd	s4,0(sp)
    80002a1c:	1800                	addi	s0,sp,48
    80002a1e:	84aa                	mv	s1,a0
    80002a20:	892e                	mv	s2,a1
    80002a22:	89b2                	mv	s3,a2
    80002a24:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a26:	fffff097          	auipc	ra,0xfffff
    80002a2a:	502080e7          	jalr	1282(ra) # 80001f28 <myproc>
  if(user_dst){
    80002a2e:	c08d                	beqz	s1,80002a50 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002a30:	86d2                	mv	a3,s4
    80002a32:	864e                	mv	a2,s3
    80002a34:	85ca                	mv	a1,s2
    80002a36:	6928                	ld	a0,80(a0)
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	c38080e7          	jalr	-968(ra) # 80001670 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a40:	70a2                	ld	ra,40(sp)
    80002a42:	7402                	ld	s0,32(sp)
    80002a44:	64e2                	ld	s1,24(sp)
    80002a46:	6942                	ld	s2,16(sp)
    80002a48:	69a2                	ld	s3,8(sp)
    80002a4a:	6a02                	ld	s4,0(sp)
    80002a4c:	6145                	addi	sp,sp,48
    80002a4e:	8082                	ret
    memmove((char *)dst, src, len);
    80002a50:	000a061b          	sext.w	a2,s4
    80002a54:	85ce                	mv	a1,s3
    80002a56:	854a                	mv	a0,s2
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	2d6080e7          	jalr	726(ra) # 80000d2e <memmove>
    return 0;
    80002a60:	8526                	mv	a0,s1
    80002a62:	bff9                	j	80002a40 <either_copyout+0x32>

0000000080002a64 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a64:	7179                	addi	sp,sp,-48
    80002a66:	f406                	sd	ra,40(sp)
    80002a68:	f022                	sd	s0,32(sp)
    80002a6a:	ec26                	sd	s1,24(sp)
    80002a6c:	e84a                	sd	s2,16(sp)
    80002a6e:	e44e                	sd	s3,8(sp)
    80002a70:	e052                	sd	s4,0(sp)
    80002a72:	1800                	addi	s0,sp,48
    80002a74:	892a                	mv	s2,a0
    80002a76:	84ae                	mv	s1,a1
    80002a78:	89b2                	mv	s3,a2
    80002a7a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	4ac080e7          	jalr	1196(ra) # 80001f28 <myproc>
  if(user_src){
    80002a84:	c08d                	beqz	s1,80002aa6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a86:	86d2                	mv	a3,s4
    80002a88:	864e                	mv	a2,s3
    80002a8a:	85ca                	mv	a1,s2
    80002a8c:	6928                	ld	a0,80(a0)
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	c6e080e7          	jalr	-914(ra) # 800016fc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a96:	70a2                	ld	ra,40(sp)
    80002a98:	7402                	ld	s0,32(sp)
    80002a9a:	64e2                	ld	s1,24(sp)
    80002a9c:	6942                	ld	s2,16(sp)
    80002a9e:	69a2                	ld	s3,8(sp)
    80002aa0:	6a02                	ld	s4,0(sp)
    80002aa2:	6145                	addi	sp,sp,48
    80002aa4:	8082                	ret
    memmove(dst, (char*)src, len);
    80002aa6:	000a061b          	sext.w	a2,s4
    80002aaa:	85ce                	mv	a1,s3
    80002aac:	854a                	mv	a0,s2
    80002aae:	ffffe097          	auipc	ra,0xffffe
    80002ab2:	280080e7          	jalr	640(ra) # 80000d2e <memmove>
    return 0;
    80002ab6:	8526                	mv	a0,s1
    80002ab8:	bff9                	j	80002a96 <either_copyin+0x32>

0000000080002aba <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002aba:	715d                	addi	sp,sp,-80
    80002abc:	e486                	sd	ra,72(sp)
    80002abe:	e0a2                	sd	s0,64(sp)
    80002ac0:	fc26                	sd	s1,56(sp)
    80002ac2:	f84a                	sd	s2,48(sp)
    80002ac4:	f44e                	sd	s3,40(sp)
    80002ac6:	f052                	sd	s4,32(sp)
    80002ac8:	ec56                	sd	s5,24(sp)
    80002aca:	e85a                	sd	s6,16(sp)
    80002acc:	e45e                	sd	s7,8(sp)
    80002ace:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002ad0:	00005517          	auipc	a0,0x5
    80002ad4:	5f850513          	addi	a0,a0,1528 # 800080c8 <digits+0x88>
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	ab0080e7          	jalr	-1360(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ae0:	0000e497          	auipc	s1,0xe
    80002ae4:	67848493          	addi	s1,s1,1656 # 80011158 <proc+0x158>
    80002ae8:	00024917          	auipc	s2,0x24
    80002aec:	67090913          	addi	s2,s2,1648 # 80027158 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002af0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002af2:	00005997          	auipc	s3,0x5
    80002af6:	7ce98993          	addi	s3,s3,1998 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    80002afa:	00005a97          	auipc	s5,0x5
    80002afe:	7cea8a93          	addi	s5,s5,1998 # 800082c8 <digits+0x288>
    printf("\n");
    80002b02:	00005a17          	auipc	s4,0x5
    80002b06:	5c6a0a13          	addi	s4,s4,1478 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b0a:	00005b97          	auipc	s7,0x5
    80002b0e:	7feb8b93          	addi	s7,s7,2046 # 80008308 <states.0>
    80002b12:	a00d                	j	80002b34 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002b14:	ed86a583          	lw	a1,-296(a3)
    80002b18:	8556                	mv	a0,s5
    80002b1a:	ffffe097          	auipc	ra,0xffffe
    80002b1e:	a6e080e7          	jalr	-1426(ra) # 80000588 <printf>
    printf("\n");
    80002b22:	8552                	mv	a0,s4
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	a64080e7          	jalr	-1436(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b2c:	58048493          	addi	s1,s1,1408
    80002b30:	03248163          	beq	s1,s2,80002b52 <procdump+0x98>
    if(p->state == UNUSED)
    80002b34:	86a6                	mv	a3,s1
    80002b36:	ec04a783          	lw	a5,-320(s1)
    80002b3a:	dbed                	beqz	a5,80002b2c <procdump+0x72>
      state = "???";
    80002b3c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b3e:	fcfb6be3          	bltu	s6,a5,80002b14 <procdump+0x5a>
    80002b42:	1782                	slli	a5,a5,0x20
    80002b44:	9381                	srli	a5,a5,0x20
    80002b46:	078e                	slli	a5,a5,0x3
    80002b48:	97de                	add	a5,a5,s7
    80002b4a:	6390                	ld	a2,0(a5)
    80002b4c:	f661                	bnez	a2,80002b14 <procdump+0x5a>
      state = "???";
    80002b4e:	864e                	mv	a2,s3
    80002b50:	b7d1                	j	80002b14 <procdump+0x5a>
  }
}
    80002b52:	60a6                	ld	ra,72(sp)
    80002b54:	6406                	ld	s0,64(sp)
    80002b56:	74e2                	ld	s1,56(sp)
    80002b58:	7942                	ld	s2,48(sp)
    80002b5a:	79a2                	ld	s3,40(sp)
    80002b5c:	7a02                	ld	s4,32(sp)
    80002b5e:	6ae2                	ld	s5,24(sp)
    80002b60:	6b42                	ld	s6,16(sp)
    80002b62:	6ba2                	ld	s7,8(sp)
    80002b64:	6161                	addi	sp,sp,80
    80002b66:	8082                	ret

0000000080002b68 <swtch>:
    80002b68:	00153023          	sd	ra,0(a0)
    80002b6c:	00253423          	sd	sp,8(a0)
    80002b70:	e900                	sd	s0,16(a0)
    80002b72:	ed04                	sd	s1,24(a0)
    80002b74:	03253023          	sd	s2,32(a0)
    80002b78:	03353423          	sd	s3,40(a0)
    80002b7c:	03453823          	sd	s4,48(a0)
    80002b80:	03553c23          	sd	s5,56(a0)
    80002b84:	05653023          	sd	s6,64(a0)
    80002b88:	05753423          	sd	s7,72(a0)
    80002b8c:	05853823          	sd	s8,80(a0)
    80002b90:	05953c23          	sd	s9,88(a0)
    80002b94:	07a53023          	sd	s10,96(a0)
    80002b98:	07b53423          	sd	s11,104(a0)
    80002b9c:	0005b083          	ld	ra,0(a1)
    80002ba0:	0085b103          	ld	sp,8(a1)
    80002ba4:	6980                	ld	s0,16(a1)
    80002ba6:	6d84                	ld	s1,24(a1)
    80002ba8:	0205b903          	ld	s2,32(a1)
    80002bac:	0285b983          	ld	s3,40(a1)
    80002bb0:	0305ba03          	ld	s4,48(a1)
    80002bb4:	0385ba83          	ld	s5,56(a1)
    80002bb8:	0405bb03          	ld	s6,64(a1)
    80002bbc:	0485bb83          	ld	s7,72(a1)
    80002bc0:	0505bc03          	ld	s8,80(a1)
    80002bc4:	0585bc83          	ld	s9,88(a1)
    80002bc8:	0605bd03          	ld	s10,96(a1)
    80002bcc:	0685bd83          	ld	s11,104(a1)
    80002bd0:	8082                	ret

0000000080002bd2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002bd2:	1141                	addi	sp,sp,-16
    80002bd4:	e406                	sd	ra,8(sp)
    80002bd6:	e022                	sd	s0,0(sp)
    80002bd8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bda:	00005597          	auipc	a1,0x5
    80002bde:	75e58593          	addi	a1,a1,1886 # 80008338 <states.0+0x30>
    80002be2:	00024517          	auipc	a0,0x24
    80002be6:	41e50513          	addi	a0,a0,1054 # 80027000 <tickslock>
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	f5c080e7          	jalr	-164(ra) # 80000b46 <initlock>
}
    80002bf2:	60a2                	ld	ra,8(sp)
    80002bf4:	6402                	ld	s0,0(sp)
    80002bf6:	0141                	addi	sp,sp,16
    80002bf8:	8082                	ret

0000000080002bfa <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002bfa:	1141                	addi	sp,sp,-16
    80002bfc:	e422                	sd	s0,8(sp)
    80002bfe:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c00:	00004797          	auipc	a5,0x4
    80002c04:	9e078793          	addi	a5,a5,-1568 # 800065e0 <kernelvec>
    80002c08:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c0c:	6422                	ld	s0,8(sp)
    80002c0e:	0141                	addi	sp,sp,16
    80002c10:	8082                	ret

0000000080002c12 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c12:	1141                	addi	sp,sp,-16
    80002c14:	e406                	sd	ra,8(sp)
    80002c16:	e022                	sd	s0,0(sp)
    80002c18:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	30e080e7          	jalr	782(ra) # 80001f28 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c22:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c26:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c28:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c2c:	00004617          	auipc	a2,0x4
    80002c30:	3d460613          	addi	a2,a2,980 # 80007000 <_trampoline>
    80002c34:	00004697          	auipc	a3,0x4
    80002c38:	3cc68693          	addi	a3,a3,972 # 80007000 <_trampoline>
    80002c3c:	8e91                	sub	a3,a3,a2
    80002c3e:	040007b7          	lui	a5,0x4000
    80002c42:	17fd                	addi	a5,a5,-1
    80002c44:	07b2                	slli	a5,a5,0xc
    80002c46:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c48:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c4c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c4e:	180026f3          	csrr	a3,satp
    80002c52:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c54:	6d38                	ld	a4,88(a0)
    80002c56:	6134                	ld	a3,64(a0)
    80002c58:	6585                	lui	a1,0x1
    80002c5a:	96ae                	add	a3,a3,a1
    80002c5c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c5e:	6d38                	ld	a4,88(a0)
    80002c60:	00000697          	auipc	a3,0x0
    80002c64:	13068693          	addi	a3,a3,304 # 80002d90 <usertrap>
    80002c68:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c6a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c6c:	8692                	mv	a3,tp
    80002c6e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c70:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c74:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c78:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c7c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c80:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c82:	6f18                	ld	a4,24(a4)
    80002c84:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c88:	6928                	ld	a0,80(a0)
    80002c8a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c8c:	00004717          	auipc	a4,0x4
    80002c90:	41070713          	addi	a4,a4,1040 # 8000709c <userret>
    80002c94:	8f11                	sub	a4,a4,a2
    80002c96:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c98:	577d                	li	a4,-1
    80002c9a:	177e                	slli	a4,a4,0x3f
    80002c9c:	8d59                	or	a0,a0,a4
    80002c9e:	9782                	jalr	a5
}
    80002ca0:	60a2                	ld	ra,8(sp)
    80002ca2:	6402                	ld	s0,0(sp)
    80002ca4:	0141                	addi	sp,sp,16
    80002ca6:	8082                	ret

0000000080002ca8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ca8:	1101                	addi	sp,sp,-32
    80002caa:	ec06                	sd	ra,24(sp)
    80002cac:	e822                	sd	s0,16(sp)
    80002cae:	e426                	sd	s1,8(sp)
    80002cb0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002cb2:	00024497          	auipc	s1,0x24
    80002cb6:	34e48493          	addi	s1,s1,846 # 80027000 <tickslock>
    80002cba:	8526                	mv	a0,s1
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	f1a080e7          	jalr	-230(ra) # 80000bd6 <acquire>
  ticks++;
    80002cc4:	00006517          	auipc	a0,0x6
    80002cc8:	c9c50513          	addi	a0,a0,-868 # 80008960 <ticks>
    80002ccc:	411c                	lw	a5,0(a0)
    80002cce:	2785                	addiw	a5,a5,1
    80002cd0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002cd2:	00000097          	auipc	ra,0x0
    80002cd6:	982080e7          	jalr	-1662(ra) # 80002654 <wakeup>
  release(&tickslock);
    80002cda:	8526                	mv	a0,s1
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	fae080e7          	jalr	-82(ra) # 80000c8a <release>
}
    80002ce4:	60e2                	ld	ra,24(sp)
    80002ce6:	6442                	ld	s0,16(sp)
    80002ce8:	64a2                	ld	s1,8(sp)
    80002cea:	6105                	addi	sp,sp,32
    80002cec:	8082                	ret

0000000080002cee <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002cee:	1101                	addi	sp,sp,-32
    80002cf0:	ec06                	sd	ra,24(sp)
    80002cf2:	e822                	sd	s0,16(sp)
    80002cf4:	e426                	sd	s1,8(sp)
    80002cf6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cf8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002cfc:	00074d63          	bltz	a4,80002d16 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d00:	57fd                	li	a5,-1
    80002d02:	17fe                	slli	a5,a5,0x3f
    80002d04:	0785                	addi	a5,a5,1
  {
    return page_fault_handler(); 
  }
  #endif
  else {
    return 0;
    80002d06:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d08:	06f70363          	beq	a4,a5,80002d6e <devintr+0x80>
  }
}
    80002d0c:	60e2                	ld	ra,24(sp)
    80002d0e:	6442                	ld	s0,16(sp)
    80002d10:	64a2                	ld	s1,8(sp)
    80002d12:	6105                	addi	sp,sp,32
    80002d14:	8082                	ret
     (scause & 0xff) == 9){
    80002d16:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d1a:	46a5                	li	a3,9
    80002d1c:	fed792e3          	bne	a5,a3,80002d00 <devintr+0x12>
    int irq = plic_claim();
    80002d20:	00004097          	auipc	ra,0x4
    80002d24:	9c8080e7          	jalr	-1592(ra) # 800066e8 <plic_claim>
    80002d28:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d2a:	47a9                	li	a5,10
    80002d2c:	02f50763          	beq	a0,a5,80002d5a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d30:	4785                	li	a5,1
    80002d32:	02f50963          	beq	a0,a5,80002d64 <devintr+0x76>
    return 1;
    80002d36:	4505                	li	a0,1
    } else if(irq){
    80002d38:	d8f1                	beqz	s1,80002d0c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d3a:	85a6                	mv	a1,s1
    80002d3c:	00005517          	auipc	a0,0x5
    80002d40:	60450513          	addi	a0,a0,1540 # 80008340 <states.0+0x38>
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	844080e7          	jalr	-1980(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d4c:	8526                	mv	a0,s1
    80002d4e:	00004097          	auipc	ra,0x4
    80002d52:	9be080e7          	jalr	-1602(ra) # 8000670c <plic_complete>
    return 1;
    80002d56:	4505                	li	a0,1
    80002d58:	bf55                	j	80002d0c <devintr+0x1e>
      uartintr();
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	c40080e7          	jalr	-960(ra) # 8000099a <uartintr>
    80002d62:	b7ed                	j	80002d4c <devintr+0x5e>
      virtio_disk_intr();
    80002d64:	00004097          	auipc	ra,0x4
    80002d68:	e74080e7          	jalr	-396(ra) # 80006bd8 <virtio_disk_intr>
    80002d6c:	b7c5                	j	80002d4c <devintr+0x5e>
    if(cpuid() == 0){
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	18e080e7          	jalr	398(ra) # 80001efc <cpuid>
    80002d76:	c901                	beqz	a0,80002d86 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d78:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d7c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d7e:	14479073          	csrw	sip,a5
    return 2;
    80002d82:	4509                	li	a0,2
    80002d84:	b761                	j	80002d0c <devintr+0x1e>
      clockintr();
    80002d86:	00000097          	auipc	ra,0x0
    80002d8a:	f22080e7          	jalr	-222(ra) # 80002ca8 <clockintr>
    80002d8e:	b7ed                	j	80002d78 <devintr+0x8a>

0000000080002d90 <usertrap>:
{
    80002d90:	1101                	addi	sp,sp,-32
    80002d92:	ec06                	sd	ra,24(sp)
    80002d94:	e822                	sd	s0,16(sp)
    80002d96:	e426                	sd	s1,8(sp)
    80002d98:	e04a                	sd	s2,0(sp)
    80002d9a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d9c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002da0:	1007f793          	andi	a5,a5,256
    80002da4:	e3b1                	bnez	a5,80002de8 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002da6:	00004797          	auipc	a5,0x4
    80002daa:	83a78793          	addi	a5,a5,-1990 # 800065e0 <kernelvec>
    80002dae:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	176080e7          	jalr	374(ra) # 80001f28 <myproc>
    80002dba:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002dbc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dbe:	14102773          	csrr	a4,sepc
    80002dc2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dc4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002dc8:	47a1                	li	a5,8
    80002dca:	02f70763          	beq	a4,a5,80002df8 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002dce:	00000097          	auipc	ra,0x0
    80002dd2:	f20080e7          	jalr	-224(ra) # 80002cee <devintr>
    80002dd6:	892a                	mv	s2,a0
    80002dd8:	c151                	beqz	a0,80002e5c <usertrap+0xcc>
  if(killed(p))
    80002dda:	8526                	mv	a0,s1
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	ad2080e7          	jalr	-1326(ra) # 800028ae <killed>
    80002de4:	c929                	beqz	a0,80002e36 <usertrap+0xa6>
    80002de6:	a099                	j	80002e2c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002de8:	00005517          	auipc	a0,0x5
    80002dec:	57850513          	addi	a0,a0,1400 # 80008360 <states.0+0x58>
    80002df0:	ffffd097          	auipc	ra,0xffffd
    80002df4:	74e080e7          	jalr	1870(ra) # 8000053e <panic>
    if(killed(p))
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	ab6080e7          	jalr	-1354(ra) # 800028ae <killed>
    80002e00:	e921                	bnez	a0,80002e50 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002e02:	6cb8                	ld	a4,88(s1)
    80002e04:	6f1c                	ld	a5,24(a4)
    80002e06:	0791                	addi	a5,a5,4
    80002e08:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e0e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e12:	10079073          	csrw	sstatus,a5
    syscall();
    80002e16:	00000097          	auipc	ra,0x0
    80002e1a:	2d4080e7          	jalr	724(ra) # 800030ea <syscall>
  if(killed(p))
    80002e1e:	8526                	mv	a0,s1
    80002e20:	00000097          	auipc	ra,0x0
    80002e24:	a8e080e7          	jalr	-1394(ra) # 800028ae <killed>
    80002e28:	c911                	beqz	a0,80002e3c <usertrap+0xac>
    80002e2a:	4901                	li	s2,0
    exit(-1);
    80002e2c:	557d                	li	a0,-1
    80002e2e:	00000097          	auipc	ra,0x0
    80002e32:	8f6080e7          	jalr	-1802(ra) # 80002724 <exit>
  if(which_dev == 2)
    80002e36:	4789                	li	a5,2
    80002e38:	04f90f63          	beq	s2,a5,80002e96 <usertrap+0x106>
  usertrapret();
    80002e3c:	00000097          	auipc	ra,0x0
    80002e40:	dd6080e7          	jalr	-554(ra) # 80002c12 <usertrapret>
}
    80002e44:	60e2                	ld	ra,24(sp)
    80002e46:	6442                	ld	s0,16(sp)
    80002e48:	64a2                	ld	s1,8(sp)
    80002e4a:	6902                	ld	s2,0(sp)
    80002e4c:	6105                	addi	sp,sp,32
    80002e4e:	8082                	ret
      exit(-1);
    80002e50:	557d                	li	a0,-1
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	8d2080e7          	jalr	-1838(ra) # 80002724 <exit>
    80002e5a:	b765                	j	80002e02 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e5c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e60:	5890                	lw	a2,48(s1)
    80002e62:	00005517          	auipc	a0,0x5
    80002e66:	51e50513          	addi	a0,a0,1310 # 80008380 <states.0+0x78>
    80002e6a:	ffffd097          	auipc	ra,0xffffd
    80002e6e:	71e080e7          	jalr	1822(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e72:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e76:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e7a:	00005517          	auipc	a0,0x5
    80002e7e:	53650513          	addi	a0,a0,1334 # 800083b0 <states.0+0xa8>
    80002e82:	ffffd097          	auipc	ra,0xffffd
    80002e86:	706080e7          	jalr	1798(ra) # 80000588 <printf>
    setkilled(p);
    80002e8a:	8526                	mv	a0,s1
    80002e8c:	00000097          	auipc	ra,0x0
    80002e90:	9f6080e7          	jalr	-1546(ra) # 80002882 <setkilled>
    80002e94:	b769                	j	80002e1e <usertrap+0x8e>
    yield();
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	71e080e7          	jalr	1822(ra) # 800025b4 <yield>
    80002e9e:	bf79                	j	80002e3c <usertrap+0xac>

0000000080002ea0 <kerneltrap>:
{
    80002ea0:	7179                	addi	sp,sp,-48
    80002ea2:	f406                	sd	ra,40(sp)
    80002ea4:	f022                	sd	s0,32(sp)
    80002ea6:	ec26                	sd	s1,24(sp)
    80002ea8:	e84a                	sd	s2,16(sp)
    80002eaa:	e44e                	sd	s3,8(sp)
    80002eac:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eae:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eb2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eb6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002eba:	1004f793          	andi	a5,s1,256
    80002ebe:	cb85                	beqz	a5,80002eee <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ec0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ec4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ec6:	ef85                	bnez	a5,80002efe <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ec8:	00000097          	auipc	ra,0x0
    80002ecc:	e26080e7          	jalr	-474(ra) # 80002cee <devintr>
    80002ed0:	cd1d                	beqz	a0,80002f0e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ed2:	4789                	li	a5,2
    80002ed4:	06f50a63          	beq	a0,a5,80002f48 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ed8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002edc:	10049073          	csrw	sstatus,s1
}
    80002ee0:	70a2                	ld	ra,40(sp)
    80002ee2:	7402                	ld	s0,32(sp)
    80002ee4:	64e2                	ld	s1,24(sp)
    80002ee6:	6942                	ld	s2,16(sp)
    80002ee8:	69a2                	ld	s3,8(sp)
    80002eea:	6145                	addi	sp,sp,48
    80002eec:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002eee:	00005517          	auipc	a0,0x5
    80002ef2:	4e250513          	addi	a0,a0,1250 # 800083d0 <states.0+0xc8>
    80002ef6:	ffffd097          	auipc	ra,0xffffd
    80002efa:	648080e7          	jalr	1608(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002efe:	00005517          	auipc	a0,0x5
    80002f02:	4fa50513          	addi	a0,a0,1274 # 800083f8 <states.0+0xf0>
    80002f06:	ffffd097          	auipc	ra,0xffffd
    80002f0a:	638080e7          	jalr	1592(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002f0e:	85ce                	mv	a1,s3
    80002f10:	00005517          	auipc	a0,0x5
    80002f14:	50850513          	addi	a0,a0,1288 # 80008418 <states.0+0x110>
    80002f18:	ffffd097          	auipc	ra,0xffffd
    80002f1c:	670080e7          	jalr	1648(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f20:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f24:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f28:	00005517          	auipc	a0,0x5
    80002f2c:	50050513          	addi	a0,a0,1280 # 80008428 <states.0+0x120>
    80002f30:	ffffd097          	auipc	ra,0xffffd
    80002f34:	658080e7          	jalr	1624(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f38:	00005517          	auipc	a0,0x5
    80002f3c:	50850513          	addi	a0,a0,1288 # 80008440 <states.0+0x138>
    80002f40:	ffffd097          	auipc	ra,0xffffd
    80002f44:	5fe080e7          	jalr	1534(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	fe0080e7          	jalr	-32(ra) # 80001f28 <myproc>
    80002f50:	d541                	beqz	a0,80002ed8 <kerneltrap+0x38>
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	fd6080e7          	jalr	-42(ra) # 80001f28 <myproc>
    80002f5a:	4d18                	lw	a4,24(a0)
    80002f5c:	4791                	li	a5,4
    80002f5e:	f6f71de3          	bne	a4,a5,80002ed8 <kerneltrap+0x38>
    yield();
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	652080e7          	jalr	1618(ra) # 800025b4 <yield>
    80002f6a:	b7bd                	j	80002ed8 <kerneltrap+0x38>

0000000080002f6c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f6c:	1101                	addi	sp,sp,-32
    80002f6e:	ec06                	sd	ra,24(sp)
    80002f70:	e822                	sd	s0,16(sp)
    80002f72:	e426                	sd	s1,8(sp)
    80002f74:	1000                	addi	s0,sp,32
    80002f76:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f78:	fffff097          	auipc	ra,0xfffff
    80002f7c:	fb0080e7          	jalr	-80(ra) # 80001f28 <myproc>
  switch (n) {
    80002f80:	4795                	li	a5,5
    80002f82:	0497e163          	bltu	a5,s1,80002fc4 <argraw+0x58>
    80002f86:	048a                	slli	s1,s1,0x2
    80002f88:	00005717          	auipc	a4,0x5
    80002f8c:	4f070713          	addi	a4,a4,1264 # 80008478 <states.0+0x170>
    80002f90:	94ba                	add	s1,s1,a4
    80002f92:	409c                	lw	a5,0(s1)
    80002f94:	97ba                	add	a5,a5,a4
    80002f96:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f98:	6d3c                	ld	a5,88(a0)
    80002f9a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f9c:	60e2                	ld	ra,24(sp)
    80002f9e:	6442                	ld	s0,16(sp)
    80002fa0:	64a2                	ld	s1,8(sp)
    80002fa2:	6105                	addi	sp,sp,32
    80002fa4:	8082                	ret
    return p->trapframe->a1;
    80002fa6:	6d3c                	ld	a5,88(a0)
    80002fa8:	7fa8                	ld	a0,120(a5)
    80002faa:	bfcd                	j	80002f9c <argraw+0x30>
    return p->trapframe->a2;
    80002fac:	6d3c                	ld	a5,88(a0)
    80002fae:	63c8                	ld	a0,128(a5)
    80002fb0:	b7f5                	j	80002f9c <argraw+0x30>
    return p->trapframe->a3;
    80002fb2:	6d3c                	ld	a5,88(a0)
    80002fb4:	67c8                	ld	a0,136(a5)
    80002fb6:	b7dd                	j	80002f9c <argraw+0x30>
    return p->trapframe->a4;
    80002fb8:	6d3c                	ld	a5,88(a0)
    80002fba:	6bc8                	ld	a0,144(a5)
    80002fbc:	b7c5                	j	80002f9c <argraw+0x30>
    return p->trapframe->a5;
    80002fbe:	6d3c                	ld	a5,88(a0)
    80002fc0:	6fc8                	ld	a0,152(a5)
    80002fc2:	bfe9                	j	80002f9c <argraw+0x30>
  panic("argraw");
    80002fc4:	00005517          	auipc	a0,0x5
    80002fc8:	48c50513          	addi	a0,a0,1164 # 80008450 <states.0+0x148>
    80002fcc:	ffffd097          	auipc	ra,0xffffd
    80002fd0:	572080e7          	jalr	1394(ra) # 8000053e <panic>

0000000080002fd4 <fetchaddr>:
{
    80002fd4:	1101                	addi	sp,sp,-32
    80002fd6:	ec06                	sd	ra,24(sp)
    80002fd8:	e822                	sd	s0,16(sp)
    80002fda:	e426                	sd	s1,8(sp)
    80002fdc:	e04a                	sd	s2,0(sp)
    80002fde:	1000                	addi	s0,sp,32
    80002fe0:	84aa                	mv	s1,a0
    80002fe2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002fe4:	fffff097          	auipc	ra,0xfffff
    80002fe8:	f44080e7          	jalr	-188(ra) # 80001f28 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002fec:	653c                	ld	a5,72(a0)
    80002fee:	02f4f863          	bgeu	s1,a5,8000301e <fetchaddr+0x4a>
    80002ff2:	00848713          	addi	a4,s1,8
    80002ff6:	02e7e663          	bltu	a5,a4,80003022 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ffa:	46a1                	li	a3,8
    80002ffc:	8626                	mv	a2,s1
    80002ffe:	85ca                	mv	a1,s2
    80003000:	6928                	ld	a0,80(a0)
    80003002:	ffffe097          	auipc	ra,0xffffe
    80003006:	6fa080e7          	jalr	1786(ra) # 800016fc <copyin>
    8000300a:	00a03533          	snez	a0,a0
    8000300e:	40a00533          	neg	a0,a0
}
    80003012:	60e2                	ld	ra,24(sp)
    80003014:	6442                	ld	s0,16(sp)
    80003016:	64a2                	ld	s1,8(sp)
    80003018:	6902                	ld	s2,0(sp)
    8000301a:	6105                	addi	sp,sp,32
    8000301c:	8082                	ret
    return -1;
    8000301e:	557d                	li	a0,-1
    80003020:	bfcd                	j	80003012 <fetchaddr+0x3e>
    80003022:	557d                	li	a0,-1
    80003024:	b7fd                	j	80003012 <fetchaddr+0x3e>

0000000080003026 <fetchstr>:
{
    80003026:	7179                	addi	sp,sp,-48
    80003028:	f406                	sd	ra,40(sp)
    8000302a:	f022                	sd	s0,32(sp)
    8000302c:	ec26                	sd	s1,24(sp)
    8000302e:	e84a                	sd	s2,16(sp)
    80003030:	e44e                	sd	s3,8(sp)
    80003032:	1800                	addi	s0,sp,48
    80003034:	892a                	mv	s2,a0
    80003036:	84ae                	mv	s1,a1
    80003038:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000303a:	fffff097          	auipc	ra,0xfffff
    8000303e:	eee080e7          	jalr	-274(ra) # 80001f28 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003042:	86ce                	mv	a3,s3
    80003044:	864a                	mv	a2,s2
    80003046:	85a6                	mv	a1,s1
    80003048:	6928                	ld	a0,80(a0)
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	740080e7          	jalr	1856(ra) # 8000178a <copyinstr>
    80003052:	00054e63          	bltz	a0,8000306e <fetchstr+0x48>
  return strlen(buf);
    80003056:	8526                	mv	a0,s1
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	df6080e7          	jalr	-522(ra) # 80000e4e <strlen>
}
    80003060:	70a2                	ld	ra,40(sp)
    80003062:	7402                	ld	s0,32(sp)
    80003064:	64e2                	ld	s1,24(sp)
    80003066:	6942                	ld	s2,16(sp)
    80003068:	69a2                	ld	s3,8(sp)
    8000306a:	6145                	addi	sp,sp,48
    8000306c:	8082                	ret
    return -1;
    8000306e:	557d                	li	a0,-1
    80003070:	bfc5                	j	80003060 <fetchstr+0x3a>

0000000080003072 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003072:	1101                	addi	sp,sp,-32
    80003074:	ec06                	sd	ra,24(sp)
    80003076:	e822                	sd	s0,16(sp)
    80003078:	e426                	sd	s1,8(sp)
    8000307a:	1000                	addi	s0,sp,32
    8000307c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000307e:	00000097          	auipc	ra,0x0
    80003082:	eee080e7          	jalr	-274(ra) # 80002f6c <argraw>
    80003086:	c088                	sw	a0,0(s1)
}
    80003088:	60e2                	ld	ra,24(sp)
    8000308a:	6442                	ld	s0,16(sp)
    8000308c:	64a2                	ld	s1,8(sp)
    8000308e:	6105                	addi	sp,sp,32
    80003090:	8082                	ret

0000000080003092 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003092:	1101                	addi	sp,sp,-32
    80003094:	ec06                	sd	ra,24(sp)
    80003096:	e822                	sd	s0,16(sp)
    80003098:	e426                	sd	s1,8(sp)
    8000309a:	1000                	addi	s0,sp,32
    8000309c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000309e:	00000097          	auipc	ra,0x0
    800030a2:	ece080e7          	jalr	-306(ra) # 80002f6c <argraw>
    800030a6:	e088                	sd	a0,0(s1)
}
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	64a2                	ld	s1,8(sp)
    800030ae:	6105                	addi	sp,sp,32
    800030b0:	8082                	ret

00000000800030b2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800030b2:	7179                	addi	sp,sp,-48
    800030b4:	f406                	sd	ra,40(sp)
    800030b6:	f022                	sd	s0,32(sp)
    800030b8:	ec26                	sd	s1,24(sp)
    800030ba:	e84a                	sd	s2,16(sp)
    800030bc:	1800                	addi	s0,sp,48
    800030be:	84ae                	mv	s1,a1
    800030c0:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800030c2:	fd840593          	addi	a1,s0,-40
    800030c6:	00000097          	auipc	ra,0x0
    800030ca:	fcc080e7          	jalr	-52(ra) # 80003092 <argaddr>
  return fetchstr(addr, buf, max);
    800030ce:	864a                	mv	a2,s2
    800030d0:	85a6                	mv	a1,s1
    800030d2:	fd843503          	ld	a0,-40(s0)
    800030d6:	00000097          	auipc	ra,0x0
    800030da:	f50080e7          	jalr	-176(ra) # 80003026 <fetchstr>
}
    800030de:	70a2                	ld	ra,40(sp)
    800030e0:	7402                	ld	s0,32(sp)
    800030e2:	64e2                	ld	s1,24(sp)
    800030e4:	6942                	ld	s2,16(sp)
    800030e6:	6145                	addi	sp,sp,48
    800030e8:	8082                	ret

00000000800030ea <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800030ea:	1101                	addi	sp,sp,-32
    800030ec:	ec06                	sd	ra,24(sp)
    800030ee:	e822                	sd	s0,16(sp)
    800030f0:	e426                	sd	s1,8(sp)
    800030f2:	e04a                	sd	s2,0(sp)
    800030f4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	e32080e7          	jalr	-462(ra) # 80001f28 <myproc>
    800030fe:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003100:	05853903          	ld	s2,88(a0)
    80003104:	0a893783          	ld	a5,168(s2)
    80003108:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000310c:	37fd                	addiw	a5,a5,-1
    8000310e:	4751                	li	a4,20
    80003110:	00f76f63          	bltu	a4,a5,8000312e <syscall+0x44>
    80003114:	00369713          	slli	a4,a3,0x3
    80003118:	00005797          	auipc	a5,0x5
    8000311c:	37878793          	addi	a5,a5,888 # 80008490 <syscalls>
    80003120:	97ba                	add	a5,a5,a4
    80003122:	639c                	ld	a5,0(a5)
    80003124:	c789                	beqz	a5,8000312e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003126:	9782                	jalr	a5
    80003128:	06a93823          	sd	a0,112(s2)
    8000312c:	a839                	j	8000314a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000312e:	15848613          	addi	a2,s1,344
    80003132:	588c                	lw	a1,48(s1)
    80003134:	00005517          	auipc	a0,0x5
    80003138:	32450513          	addi	a0,a0,804 # 80008458 <states.0+0x150>
    8000313c:	ffffd097          	auipc	ra,0xffffd
    80003140:	44c080e7          	jalr	1100(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003144:	6cbc                	ld	a5,88(s1)
    80003146:	577d                	li	a4,-1
    80003148:	fbb8                	sd	a4,112(a5)
  }
}
    8000314a:	60e2                	ld	ra,24(sp)
    8000314c:	6442                	ld	s0,16(sp)
    8000314e:	64a2                	ld	s1,8(sp)
    80003150:	6902                	ld	s2,0(sp)
    80003152:	6105                	addi	sp,sp,32
    80003154:	8082                	ret

0000000080003156 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003156:	1101                	addi	sp,sp,-32
    80003158:	ec06                	sd	ra,24(sp)
    8000315a:	e822                	sd	s0,16(sp)
    8000315c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000315e:	fec40593          	addi	a1,s0,-20
    80003162:	4501                	li	a0,0
    80003164:	00000097          	auipc	ra,0x0
    80003168:	f0e080e7          	jalr	-242(ra) # 80003072 <argint>
  exit(n);
    8000316c:	fec42503          	lw	a0,-20(s0)
    80003170:	fffff097          	auipc	ra,0xfffff
    80003174:	5b4080e7          	jalr	1460(ra) # 80002724 <exit>
  return 0;  // not reached
}
    80003178:	4501                	li	a0,0
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	6105                	addi	sp,sp,32
    80003180:	8082                	ret

0000000080003182 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003182:	1141                	addi	sp,sp,-16
    80003184:	e406                	sd	ra,8(sp)
    80003186:	e022                	sd	s0,0(sp)
    80003188:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000318a:	fffff097          	auipc	ra,0xfffff
    8000318e:	d9e080e7          	jalr	-610(ra) # 80001f28 <myproc>
}
    80003192:	5908                	lw	a0,48(a0)
    80003194:	60a2                	ld	ra,8(sp)
    80003196:	6402                	ld	s0,0(sp)
    80003198:	0141                	addi	sp,sp,16
    8000319a:	8082                	ret

000000008000319c <sys_fork>:

uint64
sys_fork(void)
{
    8000319c:	1141                	addi	sp,sp,-16
    8000319e:	e406                	sd	ra,8(sp)
    800031a0:	e022                	sd	s0,0(sp)
    800031a2:	0800                	addi	s0,sp,16
  return fork();
    800031a4:	fffff097          	auipc	ra,0xfffff
    800031a8:	15a080e7          	jalr	346(ra) # 800022fe <fork>
}
    800031ac:	60a2                	ld	ra,8(sp)
    800031ae:	6402                	ld	s0,0(sp)
    800031b0:	0141                	addi	sp,sp,16
    800031b2:	8082                	ret

00000000800031b4 <sys_wait>:

uint64
sys_wait(void)
{
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800031bc:	fe840593          	addi	a1,s0,-24
    800031c0:	4501                	li	a0,0
    800031c2:	00000097          	auipc	ra,0x0
    800031c6:	ed0080e7          	jalr	-304(ra) # 80003092 <argaddr>
  return wait(p);
    800031ca:	fe843503          	ld	a0,-24(s0)
    800031ce:	fffff097          	auipc	ra,0xfffff
    800031d2:	712080e7          	jalr	1810(ra) # 800028e0 <wait>
}
    800031d6:	60e2                	ld	ra,24(sp)
    800031d8:	6442                	ld	s0,16(sp)
    800031da:	6105                	addi	sp,sp,32
    800031dc:	8082                	ret

00000000800031de <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031de:	7179                	addi	sp,sp,-48
    800031e0:	f406                	sd	ra,40(sp)
    800031e2:	f022                	sd	s0,32(sp)
    800031e4:	ec26                	sd	s1,24(sp)
    800031e6:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800031e8:	fdc40593          	addi	a1,s0,-36
    800031ec:	4501                	li	a0,0
    800031ee:	00000097          	auipc	ra,0x0
    800031f2:	e84080e7          	jalr	-380(ra) # 80003072 <argint>
  addr = myproc()->sz;
    800031f6:	fffff097          	auipc	ra,0xfffff
    800031fa:	d32080e7          	jalr	-718(ra) # 80001f28 <myproc>
    800031fe:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80003200:	fdc42503          	lw	a0,-36(s0)
    80003204:	fffff097          	auipc	ra,0xfffff
    80003208:	09e080e7          	jalr	158(ra) # 800022a2 <growproc>
    8000320c:	00054863          	bltz	a0,8000321c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003210:	8526                	mv	a0,s1
    80003212:	70a2                	ld	ra,40(sp)
    80003214:	7402                	ld	s0,32(sp)
    80003216:	64e2                	ld	s1,24(sp)
    80003218:	6145                	addi	sp,sp,48
    8000321a:	8082                	ret
    return -1;
    8000321c:	54fd                	li	s1,-1
    8000321e:	bfcd                	j	80003210 <sys_sbrk+0x32>

0000000080003220 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003220:	7139                	addi	sp,sp,-64
    80003222:	fc06                	sd	ra,56(sp)
    80003224:	f822                	sd	s0,48(sp)
    80003226:	f426                	sd	s1,40(sp)
    80003228:	f04a                	sd	s2,32(sp)
    8000322a:	ec4e                	sd	s3,24(sp)
    8000322c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000322e:	fcc40593          	addi	a1,s0,-52
    80003232:	4501                	li	a0,0
    80003234:	00000097          	auipc	ra,0x0
    80003238:	e3e080e7          	jalr	-450(ra) # 80003072 <argint>
  acquire(&tickslock);
    8000323c:	00024517          	auipc	a0,0x24
    80003240:	dc450513          	addi	a0,a0,-572 # 80027000 <tickslock>
    80003244:	ffffe097          	auipc	ra,0xffffe
    80003248:	992080e7          	jalr	-1646(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    8000324c:	00005917          	auipc	s2,0x5
    80003250:	71492903          	lw	s2,1812(s2) # 80008960 <ticks>
  while(ticks - ticks0 < n){
    80003254:	fcc42783          	lw	a5,-52(s0)
    80003258:	cf9d                	beqz	a5,80003296 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000325a:	00024997          	auipc	s3,0x24
    8000325e:	da698993          	addi	s3,s3,-602 # 80027000 <tickslock>
    80003262:	00005497          	auipc	s1,0x5
    80003266:	6fe48493          	addi	s1,s1,1790 # 80008960 <ticks>
    if(killed(myproc())){
    8000326a:	fffff097          	auipc	ra,0xfffff
    8000326e:	cbe080e7          	jalr	-834(ra) # 80001f28 <myproc>
    80003272:	fffff097          	auipc	ra,0xfffff
    80003276:	63c080e7          	jalr	1596(ra) # 800028ae <killed>
    8000327a:	ed15                	bnez	a0,800032b6 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000327c:	85ce                	mv	a1,s3
    8000327e:	8526                	mv	a0,s1
    80003280:	fffff097          	auipc	ra,0xfffff
    80003284:	370080e7          	jalr	880(ra) # 800025f0 <sleep>
  while(ticks - ticks0 < n){
    80003288:	409c                	lw	a5,0(s1)
    8000328a:	412787bb          	subw	a5,a5,s2
    8000328e:	fcc42703          	lw	a4,-52(s0)
    80003292:	fce7ece3          	bltu	a5,a4,8000326a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003296:	00024517          	auipc	a0,0x24
    8000329a:	d6a50513          	addi	a0,a0,-662 # 80027000 <tickslock>
    8000329e:	ffffe097          	auipc	ra,0xffffe
    800032a2:	9ec080e7          	jalr	-1556(ra) # 80000c8a <release>
  return 0;
    800032a6:	4501                	li	a0,0
}
    800032a8:	70e2                	ld	ra,56(sp)
    800032aa:	7442                	ld	s0,48(sp)
    800032ac:	74a2                	ld	s1,40(sp)
    800032ae:	7902                	ld	s2,32(sp)
    800032b0:	69e2                	ld	s3,24(sp)
    800032b2:	6121                	addi	sp,sp,64
    800032b4:	8082                	ret
      release(&tickslock);
    800032b6:	00024517          	auipc	a0,0x24
    800032ba:	d4a50513          	addi	a0,a0,-694 # 80027000 <tickslock>
    800032be:	ffffe097          	auipc	ra,0xffffe
    800032c2:	9cc080e7          	jalr	-1588(ra) # 80000c8a <release>
      return -1;
    800032c6:	557d                	li	a0,-1
    800032c8:	b7c5                	j	800032a8 <sys_sleep+0x88>

00000000800032ca <sys_kill>:

uint64
sys_kill(void)
{
    800032ca:	1101                	addi	sp,sp,-32
    800032cc:	ec06                	sd	ra,24(sp)
    800032ce:	e822                	sd	s0,16(sp)
    800032d0:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800032d2:	fec40593          	addi	a1,s0,-20
    800032d6:	4501                	li	a0,0
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	d9a080e7          	jalr	-614(ra) # 80003072 <argint>
  return kill(pid);
    800032e0:	fec42503          	lw	a0,-20(s0)
    800032e4:	fffff097          	auipc	ra,0xfffff
    800032e8:	52c080e7          	jalr	1324(ra) # 80002810 <kill>
}
    800032ec:	60e2                	ld	ra,24(sp)
    800032ee:	6442                	ld	s0,16(sp)
    800032f0:	6105                	addi	sp,sp,32
    800032f2:	8082                	ret

00000000800032f4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032f4:	1101                	addi	sp,sp,-32
    800032f6:	ec06                	sd	ra,24(sp)
    800032f8:	e822                	sd	s0,16(sp)
    800032fa:	e426                	sd	s1,8(sp)
    800032fc:	1000                	addi	s0,sp,32
  uint xticks; 
  acquire(&tickslock);
    800032fe:	00024517          	auipc	a0,0x24
    80003302:	d0250513          	addi	a0,a0,-766 # 80027000 <tickslock>
    80003306:	ffffe097          	auipc	ra,0xffffe
    8000330a:	8d0080e7          	jalr	-1840(ra) # 80000bd6 <acquire>
  xticks = ticks;
    8000330e:	00005497          	auipc	s1,0x5
    80003312:	6524a483          	lw	s1,1618(s1) # 80008960 <ticks>
  release(&tickslock);
    80003316:	00024517          	auipc	a0,0x24
    8000331a:	cea50513          	addi	a0,a0,-790 # 80027000 <tickslock>
    8000331e:	ffffe097          	auipc	ra,0xffffe
    80003322:	96c080e7          	jalr	-1684(ra) # 80000c8a <release>
  return xticks;
}
    80003326:	02049513          	slli	a0,s1,0x20
    8000332a:	9101                	srli	a0,a0,0x20
    8000332c:	60e2                	ld	ra,24(sp)
    8000332e:	6442                	ld	s0,16(sp)
    80003330:	64a2                	ld	s1,8(sp)
    80003332:	6105                	addi	sp,sp,32
    80003334:	8082                	ret

0000000080003336 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003336:	7179                	addi	sp,sp,-48
    80003338:	f406                	sd	ra,40(sp)
    8000333a:	f022                	sd	s0,32(sp)
    8000333c:	ec26                	sd	s1,24(sp)
    8000333e:	e84a                	sd	s2,16(sp)
    80003340:	e44e                	sd	s3,8(sp)
    80003342:	e052                	sd	s4,0(sp)
    80003344:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003346:	00005597          	auipc	a1,0x5
    8000334a:	1fa58593          	addi	a1,a1,506 # 80008540 <syscalls+0xb0>
    8000334e:	00024517          	auipc	a0,0x24
    80003352:	cca50513          	addi	a0,a0,-822 # 80027018 <bcache>
    80003356:	ffffd097          	auipc	ra,0xffffd
    8000335a:	7f0080e7          	jalr	2032(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000335e:	0002c797          	auipc	a5,0x2c
    80003362:	cba78793          	addi	a5,a5,-838 # 8002f018 <bcache+0x8000>
    80003366:	0002c717          	auipc	a4,0x2c
    8000336a:	f1a70713          	addi	a4,a4,-230 # 8002f280 <bcache+0x8268>
    8000336e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003372:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003376:	00024497          	auipc	s1,0x24
    8000337a:	cba48493          	addi	s1,s1,-838 # 80027030 <bcache+0x18>
    b->next = bcache.head.next;
    8000337e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003380:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003382:	00005a17          	auipc	s4,0x5
    80003386:	1c6a0a13          	addi	s4,s4,454 # 80008548 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000338a:	2b893783          	ld	a5,696(s2)
    8000338e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003390:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003394:	85d2                	mv	a1,s4
    80003396:	01048513          	addi	a0,s1,16
    8000339a:	00001097          	auipc	ra,0x1
    8000339e:	7d6080e7          	jalr	2006(ra) # 80004b70 <initsleeplock>
    bcache.head.next->prev = b;
    800033a2:	2b893783          	ld	a5,696(s2)
    800033a6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033a8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033ac:	45848493          	addi	s1,s1,1112
    800033b0:	fd349de3          	bne	s1,s3,8000338a <binit+0x54>
  }
}
    800033b4:	70a2                	ld	ra,40(sp)
    800033b6:	7402                	ld	s0,32(sp)
    800033b8:	64e2                	ld	s1,24(sp)
    800033ba:	6942                	ld	s2,16(sp)
    800033bc:	69a2                	ld	s3,8(sp)
    800033be:	6a02                	ld	s4,0(sp)
    800033c0:	6145                	addi	sp,sp,48
    800033c2:	8082                	ret

00000000800033c4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033c4:	7179                	addi	sp,sp,-48
    800033c6:	f406                	sd	ra,40(sp)
    800033c8:	f022                	sd	s0,32(sp)
    800033ca:	ec26                	sd	s1,24(sp)
    800033cc:	e84a                	sd	s2,16(sp)
    800033ce:	e44e                	sd	s3,8(sp)
    800033d0:	1800                	addi	s0,sp,48
    800033d2:	892a                	mv	s2,a0
    800033d4:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800033d6:	00024517          	auipc	a0,0x24
    800033da:	c4250513          	addi	a0,a0,-958 # 80027018 <bcache>
    800033de:	ffffd097          	auipc	ra,0xffffd
    800033e2:	7f8080e7          	jalr	2040(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033e6:	0002c497          	auipc	s1,0x2c
    800033ea:	eea4b483          	ld	s1,-278(s1) # 8002f2d0 <bcache+0x82b8>
    800033ee:	0002c797          	auipc	a5,0x2c
    800033f2:	e9278793          	addi	a5,a5,-366 # 8002f280 <bcache+0x8268>
    800033f6:	02f48f63          	beq	s1,a5,80003434 <bread+0x70>
    800033fa:	873e                	mv	a4,a5
    800033fc:	a021                	j	80003404 <bread+0x40>
    800033fe:	68a4                	ld	s1,80(s1)
    80003400:	02e48a63          	beq	s1,a4,80003434 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003404:	449c                	lw	a5,8(s1)
    80003406:	ff279ce3          	bne	a5,s2,800033fe <bread+0x3a>
    8000340a:	44dc                	lw	a5,12(s1)
    8000340c:	ff3799e3          	bne	a5,s3,800033fe <bread+0x3a>
      b->refcnt++;
    80003410:	40bc                	lw	a5,64(s1)
    80003412:	2785                	addiw	a5,a5,1
    80003414:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003416:	00024517          	auipc	a0,0x24
    8000341a:	c0250513          	addi	a0,a0,-1022 # 80027018 <bcache>
    8000341e:	ffffe097          	auipc	ra,0xffffe
    80003422:	86c080e7          	jalr	-1940(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003426:	01048513          	addi	a0,s1,16
    8000342a:	00001097          	auipc	ra,0x1
    8000342e:	780080e7          	jalr	1920(ra) # 80004baa <acquiresleep>
      return b;
    80003432:	a8b9                	j	80003490 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003434:	0002c497          	auipc	s1,0x2c
    80003438:	e944b483          	ld	s1,-364(s1) # 8002f2c8 <bcache+0x82b0>
    8000343c:	0002c797          	auipc	a5,0x2c
    80003440:	e4478793          	addi	a5,a5,-444 # 8002f280 <bcache+0x8268>
    80003444:	00f48863          	beq	s1,a5,80003454 <bread+0x90>
    80003448:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000344a:	40bc                	lw	a5,64(s1)
    8000344c:	cf81                	beqz	a5,80003464 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000344e:	64a4                	ld	s1,72(s1)
    80003450:	fee49de3          	bne	s1,a4,8000344a <bread+0x86>
  panic("bget: no buffers");
    80003454:	00005517          	auipc	a0,0x5
    80003458:	0fc50513          	addi	a0,a0,252 # 80008550 <syscalls+0xc0>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	0e2080e7          	jalr	226(ra) # 8000053e <panic>
      b->dev = dev;
    80003464:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003468:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000346c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003470:	4785                	li	a5,1
    80003472:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003474:	00024517          	auipc	a0,0x24
    80003478:	ba450513          	addi	a0,a0,-1116 # 80027018 <bcache>
    8000347c:	ffffe097          	auipc	ra,0xffffe
    80003480:	80e080e7          	jalr	-2034(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003484:	01048513          	addi	a0,s1,16
    80003488:	00001097          	auipc	ra,0x1
    8000348c:	722080e7          	jalr	1826(ra) # 80004baa <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003490:	409c                	lw	a5,0(s1)
    80003492:	cb89                	beqz	a5,800034a4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003494:	8526                	mv	a0,s1
    80003496:	70a2                	ld	ra,40(sp)
    80003498:	7402                	ld	s0,32(sp)
    8000349a:	64e2                	ld	s1,24(sp)
    8000349c:	6942                	ld	s2,16(sp)
    8000349e:	69a2                	ld	s3,8(sp)
    800034a0:	6145                	addi	sp,sp,48
    800034a2:	8082                	ret
    virtio_disk_rw(b, 0);
    800034a4:	4581                	li	a1,0
    800034a6:	8526                	mv	a0,s1
    800034a8:	00003097          	auipc	ra,0x3
    800034ac:	4fc080e7          	jalr	1276(ra) # 800069a4 <virtio_disk_rw>
    b->valid = 1;
    800034b0:	4785                	li	a5,1
    800034b2:	c09c                	sw	a5,0(s1)
  return b;
    800034b4:	b7c5                	j	80003494 <bread+0xd0>

00000000800034b6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034b6:	1101                	addi	sp,sp,-32
    800034b8:	ec06                	sd	ra,24(sp)
    800034ba:	e822                	sd	s0,16(sp)
    800034bc:	e426                	sd	s1,8(sp)
    800034be:	1000                	addi	s0,sp,32
    800034c0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034c2:	0541                	addi	a0,a0,16
    800034c4:	00001097          	auipc	ra,0x1
    800034c8:	780080e7          	jalr	1920(ra) # 80004c44 <holdingsleep>
    800034cc:	cd01                	beqz	a0,800034e4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034ce:	4585                	li	a1,1
    800034d0:	8526                	mv	a0,s1
    800034d2:	00003097          	auipc	ra,0x3
    800034d6:	4d2080e7          	jalr	1234(ra) # 800069a4 <virtio_disk_rw>
}
    800034da:	60e2                	ld	ra,24(sp)
    800034dc:	6442                	ld	s0,16(sp)
    800034de:	64a2                	ld	s1,8(sp)
    800034e0:	6105                	addi	sp,sp,32
    800034e2:	8082                	ret
    panic("bwrite");
    800034e4:	00005517          	auipc	a0,0x5
    800034e8:	08450513          	addi	a0,a0,132 # 80008568 <syscalls+0xd8>
    800034ec:	ffffd097          	auipc	ra,0xffffd
    800034f0:	052080e7          	jalr	82(ra) # 8000053e <panic>

00000000800034f4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034f4:	1101                	addi	sp,sp,-32
    800034f6:	ec06                	sd	ra,24(sp)
    800034f8:	e822                	sd	s0,16(sp)
    800034fa:	e426                	sd	s1,8(sp)
    800034fc:	e04a                	sd	s2,0(sp)
    800034fe:	1000                	addi	s0,sp,32
    80003500:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003502:	01050913          	addi	s2,a0,16
    80003506:	854a                	mv	a0,s2
    80003508:	00001097          	auipc	ra,0x1
    8000350c:	73c080e7          	jalr	1852(ra) # 80004c44 <holdingsleep>
    80003510:	c92d                	beqz	a0,80003582 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003512:	854a                	mv	a0,s2
    80003514:	00001097          	auipc	ra,0x1
    80003518:	6ec080e7          	jalr	1772(ra) # 80004c00 <releasesleep>

  acquire(&bcache.lock);
    8000351c:	00024517          	auipc	a0,0x24
    80003520:	afc50513          	addi	a0,a0,-1284 # 80027018 <bcache>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	6b2080e7          	jalr	1714(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000352c:	40bc                	lw	a5,64(s1)
    8000352e:	37fd                	addiw	a5,a5,-1
    80003530:	0007871b          	sext.w	a4,a5
    80003534:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003536:	eb05                	bnez	a4,80003566 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003538:	68bc                	ld	a5,80(s1)
    8000353a:	64b8                	ld	a4,72(s1)
    8000353c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000353e:	64bc                	ld	a5,72(s1)
    80003540:	68b8                	ld	a4,80(s1)
    80003542:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003544:	0002c797          	auipc	a5,0x2c
    80003548:	ad478793          	addi	a5,a5,-1324 # 8002f018 <bcache+0x8000>
    8000354c:	2b87b703          	ld	a4,696(a5)
    80003550:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003552:	0002c717          	auipc	a4,0x2c
    80003556:	d2e70713          	addi	a4,a4,-722 # 8002f280 <bcache+0x8268>
    8000355a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000355c:	2b87b703          	ld	a4,696(a5)
    80003560:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003562:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003566:	00024517          	auipc	a0,0x24
    8000356a:	ab250513          	addi	a0,a0,-1358 # 80027018 <bcache>
    8000356e:	ffffd097          	auipc	ra,0xffffd
    80003572:	71c080e7          	jalr	1820(ra) # 80000c8a <release>
}
    80003576:	60e2                	ld	ra,24(sp)
    80003578:	6442                	ld	s0,16(sp)
    8000357a:	64a2                	ld	s1,8(sp)
    8000357c:	6902                	ld	s2,0(sp)
    8000357e:	6105                	addi	sp,sp,32
    80003580:	8082                	ret
    panic("brelse");
    80003582:	00005517          	auipc	a0,0x5
    80003586:	fee50513          	addi	a0,a0,-18 # 80008570 <syscalls+0xe0>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	fb4080e7          	jalr	-76(ra) # 8000053e <panic>

0000000080003592 <bpin>:

void
bpin(struct buf *b) {
    80003592:	1101                	addi	sp,sp,-32
    80003594:	ec06                	sd	ra,24(sp)
    80003596:	e822                	sd	s0,16(sp)
    80003598:	e426                	sd	s1,8(sp)
    8000359a:	1000                	addi	s0,sp,32
    8000359c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000359e:	00024517          	auipc	a0,0x24
    800035a2:	a7a50513          	addi	a0,a0,-1414 # 80027018 <bcache>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	630080e7          	jalr	1584(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800035ae:	40bc                	lw	a5,64(s1)
    800035b0:	2785                	addiw	a5,a5,1
    800035b2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035b4:	00024517          	auipc	a0,0x24
    800035b8:	a6450513          	addi	a0,a0,-1436 # 80027018 <bcache>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	6ce080e7          	jalr	1742(ra) # 80000c8a <release>
}
    800035c4:	60e2                	ld	ra,24(sp)
    800035c6:	6442                	ld	s0,16(sp)
    800035c8:	64a2                	ld	s1,8(sp)
    800035ca:	6105                	addi	sp,sp,32
    800035cc:	8082                	ret

00000000800035ce <bunpin>:

void
bunpin(struct buf *b) {
    800035ce:	1101                	addi	sp,sp,-32
    800035d0:	ec06                	sd	ra,24(sp)
    800035d2:	e822                	sd	s0,16(sp)
    800035d4:	e426                	sd	s1,8(sp)
    800035d6:	1000                	addi	s0,sp,32
    800035d8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035da:	00024517          	auipc	a0,0x24
    800035de:	a3e50513          	addi	a0,a0,-1474 # 80027018 <bcache>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	5f4080e7          	jalr	1524(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800035ea:	40bc                	lw	a5,64(s1)
    800035ec:	37fd                	addiw	a5,a5,-1
    800035ee:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035f0:	00024517          	auipc	a0,0x24
    800035f4:	a2850513          	addi	a0,a0,-1496 # 80027018 <bcache>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	692080e7          	jalr	1682(ra) # 80000c8a <release>
}
    80003600:	60e2                	ld	ra,24(sp)
    80003602:	6442                	ld	s0,16(sp)
    80003604:	64a2                	ld	s1,8(sp)
    80003606:	6105                	addi	sp,sp,32
    80003608:	8082                	ret

000000008000360a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000360a:	1101                	addi	sp,sp,-32
    8000360c:	ec06                	sd	ra,24(sp)
    8000360e:	e822                	sd	s0,16(sp)
    80003610:	e426                	sd	s1,8(sp)
    80003612:	e04a                	sd	s2,0(sp)
    80003614:	1000                	addi	s0,sp,32
    80003616:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003618:	00d5d59b          	srliw	a1,a1,0xd
    8000361c:	0002c797          	auipc	a5,0x2c
    80003620:	0d87a783          	lw	a5,216(a5) # 8002f6f4 <sb+0x1c>
    80003624:	9dbd                	addw	a1,a1,a5
    80003626:	00000097          	auipc	ra,0x0
    8000362a:	d9e080e7          	jalr	-610(ra) # 800033c4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000362e:	0074f713          	andi	a4,s1,7
    80003632:	4785                	li	a5,1
    80003634:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003638:	14ce                	slli	s1,s1,0x33
    8000363a:	90d9                	srli	s1,s1,0x36
    8000363c:	00950733          	add	a4,a0,s1
    80003640:	05874703          	lbu	a4,88(a4)
    80003644:	00e7f6b3          	and	a3,a5,a4
    80003648:	c69d                	beqz	a3,80003676 <bfree+0x6c>
    8000364a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000364c:	94aa                	add	s1,s1,a0
    8000364e:	fff7c793          	not	a5,a5
    80003652:	8ff9                	and	a5,a5,a4
    80003654:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003658:	00001097          	auipc	ra,0x1
    8000365c:	432080e7          	jalr	1074(ra) # 80004a8a <log_write>
  brelse(bp);
    80003660:	854a                	mv	a0,s2
    80003662:	00000097          	auipc	ra,0x0
    80003666:	e92080e7          	jalr	-366(ra) # 800034f4 <brelse>
}
    8000366a:	60e2                	ld	ra,24(sp)
    8000366c:	6442                	ld	s0,16(sp)
    8000366e:	64a2                	ld	s1,8(sp)
    80003670:	6902                	ld	s2,0(sp)
    80003672:	6105                	addi	sp,sp,32
    80003674:	8082                	ret
    panic("freeing free block");
    80003676:	00005517          	auipc	a0,0x5
    8000367a:	f0250513          	addi	a0,a0,-254 # 80008578 <syscalls+0xe8>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	ec0080e7          	jalr	-320(ra) # 8000053e <panic>

0000000080003686 <balloc>:
{
    80003686:	711d                	addi	sp,sp,-96
    80003688:	ec86                	sd	ra,88(sp)
    8000368a:	e8a2                	sd	s0,80(sp)
    8000368c:	e4a6                	sd	s1,72(sp)
    8000368e:	e0ca                	sd	s2,64(sp)
    80003690:	fc4e                	sd	s3,56(sp)
    80003692:	f852                	sd	s4,48(sp)
    80003694:	f456                	sd	s5,40(sp)
    80003696:	f05a                	sd	s6,32(sp)
    80003698:	ec5e                	sd	s7,24(sp)
    8000369a:	e862                	sd	s8,16(sp)
    8000369c:	e466                	sd	s9,8(sp)
    8000369e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036a0:	0002c797          	auipc	a5,0x2c
    800036a4:	03c7a783          	lw	a5,60(a5) # 8002f6dc <sb+0x4>
    800036a8:	10078163          	beqz	a5,800037aa <balloc+0x124>
    800036ac:	8baa                	mv	s7,a0
    800036ae:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036b0:	0002cb17          	auipc	s6,0x2c
    800036b4:	028b0b13          	addi	s6,s6,40 # 8002f6d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036ba:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036bc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036be:	6c89                	lui	s9,0x2
    800036c0:	a061                	j	80003748 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036c2:	974a                	add	a4,a4,s2
    800036c4:	8fd5                	or	a5,a5,a3
    800036c6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800036ca:	854a                	mv	a0,s2
    800036cc:	00001097          	auipc	ra,0x1
    800036d0:	3be080e7          	jalr	958(ra) # 80004a8a <log_write>
        brelse(bp);
    800036d4:	854a                	mv	a0,s2
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	e1e080e7          	jalr	-482(ra) # 800034f4 <brelse>
  bp = bread(dev, bno);
    800036de:	85a6                	mv	a1,s1
    800036e0:	855e                	mv	a0,s7
    800036e2:	00000097          	auipc	ra,0x0
    800036e6:	ce2080e7          	jalr	-798(ra) # 800033c4 <bread>
    800036ea:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036ec:	40000613          	li	a2,1024
    800036f0:	4581                	li	a1,0
    800036f2:	05850513          	addi	a0,a0,88
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	5dc080e7          	jalr	1500(ra) # 80000cd2 <memset>
  log_write(bp);
    800036fe:	854a                	mv	a0,s2
    80003700:	00001097          	auipc	ra,0x1
    80003704:	38a080e7          	jalr	906(ra) # 80004a8a <log_write>
  brelse(bp);
    80003708:	854a                	mv	a0,s2
    8000370a:	00000097          	auipc	ra,0x0
    8000370e:	dea080e7          	jalr	-534(ra) # 800034f4 <brelse>
}
    80003712:	8526                	mv	a0,s1
    80003714:	60e6                	ld	ra,88(sp)
    80003716:	6446                	ld	s0,80(sp)
    80003718:	64a6                	ld	s1,72(sp)
    8000371a:	6906                	ld	s2,64(sp)
    8000371c:	79e2                	ld	s3,56(sp)
    8000371e:	7a42                	ld	s4,48(sp)
    80003720:	7aa2                	ld	s5,40(sp)
    80003722:	7b02                	ld	s6,32(sp)
    80003724:	6be2                	ld	s7,24(sp)
    80003726:	6c42                	ld	s8,16(sp)
    80003728:	6ca2                	ld	s9,8(sp)
    8000372a:	6125                	addi	sp,sp,96
    8000372c:	8082                	ret
    brelse(bp);
    8000372e:	854a                	mv	a0,s2
    80003730:	00000097          	auipc	ra,0x0
    80003734:	dc4080e7          	jalr	-572(ra) # 800034f4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003738:	015c87bb          	addw	a5,s9,s5
    8000373c:	00078a9b          	sext.w	s5,a5
    80003740:	004b2703          	lw	a4,4(s6)
    80003744:	06eaf363          	bgeu	s5,a4,800037aa <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003748:	41fad79b          	sraiw	a5,s5,0x1f
    8000374c:	0137d79b          	srliw	a5,a5,0x13
    80003750:	015787bb          	addw	a5,a5,s5
    80003754:	40d7d79b          	sraiw	a5,a5,0xd
    80003758:	01cb2583          	lw	a1,28(s6)
    8000375c:	9dbd                	addw	a1,a1,a5
    8000375e:	855e                	mv	a0,s7
    80003760:	00000097          	auipc	ra,0x0
    80003764:	c64080e7          	jalr	-924(ra) # 800033c4 <bread>
    80003768:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000376a:	004b2503          	lw	a0,4(s6)
    8000376e:	000a849b          	sext.w	s1,s5
    80003772:	8662                	mv	a2,s8
    80003774:	faa4fde3          	bgeu	s1,a0,8000372e <balloc+0xa8>
      m = 1 << (bi % 8);
    80003778:	41f6579b          	sraiw	a5,a2,0x1f
    8000377c:	01d7d69b          	srliw	a3,a5,0x1d
    80003780:	00c6873b          	addw	a4,a3,a2
    80003784:	00777793          	andi	a5,a4,7
    80003788:	9f95                	subw	a5,a5,a3
    8000378a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000378e:	4037571b          	sraiw	a4,a4,0x3
    80003792:	00e906b3          	add	a3,s2,a4
    80003796:	0586c683          	lbu	a3,88(a3)
    8000379a:	00d7f5b3          	and	a1,a5,a3
    8000379e:	d195                	beqz	a1,800036c2 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037a0:	2605                	addiw	a2,a2,1
    800037a2:	2485                	addiw	s1,s1,1
    800037a4:	fd4618e3          	bne	a2,s4,80003774 <balloc+0xee>
    800037a8:	b759                	j	8000372e <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800037aa:	00005517          	auipc	a0,0x5
    800037ae:	de650513          	addi	a0,a0,-538 # 80008590 <syscalls+0x100>
    800037b2:	ffffd097          	auipc	ra,0xffffd
    800037b6:	dd6080e7          	jalr	-554(ra) # 80000588 <printf>
  return 0;
    800037ba:	4481                	li	s1,0
    800037bc:	bf99                	j	80003712 <balloc+0x8c>

00000000800037be <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800037be:	7179                	addi	sp,sp,-48
    800037c0:	f406                	sd	ra,40(sp)
    800037c2:	f022                	sd	s0,32(sp)
    800037c4:	ec26                	sd	s1,24(sp)
    800037c6:	e84a                	sd	s2,16(sp)
    800037c8:	e44e                	sd	s3,8(sp)
    800037ca:	e052                	sd	s4,0(sp)
    800037cc:	1800                	addi	s0,sp,48
    800037ce:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037d0:	47ad                	li	a5,11
    800037d2:	02b7e763          	bltu	a5,a1,80003800 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800037d6:	02059493          	slli	s1,a1,0x20
    800037da:	9081                	srli	s1,s1,0x20
    800037dc:	048a                	slli	s1,s1,0x2
    800037de:	94aa                	add	s1,s1,a0
    800037e0:	0504a903          	lw	s2,80(s1)
    800037e4:	06091e63          	bnez	s2,80003860 <bmap+0xa2>
      addr = balloc(ip->dev);
    800037e8:	4108                	lw	a0,0(a0)
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	e9c080e7          	jalr	-356(ra) # 80003686 <balloc>
    800037f2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037f6:	06090563          	beqz	s2,80003860 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800037fa:	0524a823          	sw	s2,80(s1)
    800037fe:	a08d                	j	80003860 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003800:	ff45849b          	addiw	s1,a1,-12
    80003804:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003808:	0ff00793          	li	a5,255
    8000380c:	08e7e563          	bltu	a5,a4,80003896 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003810:	08052903          	lw	s2,128(a0)
    80003814:	00091d63          	bnez	s2,8000382e <bmap+0x70>
      addr = balloc(ip->dev);
    80003818:	4108                	lw	a0,0(a0)
    8000381a:	00000097          	auipc	ra,0x0
    8000381e:	e6c080e7          	jalr	-404(ra) # 80003686 <balloc>
    80003822:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003826:	02090d63          	beqz	s2,80003860 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000382a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000382e:	85ca                	mv	a1,s2
    80003830:	0009a503          	lw	a0,0(s3)
    80003834:	00000097          	auipc	ra,0x0
    80003838:	b90080e7          	jalr	-1136(ra) # 800033c4 <bread>
    8000383c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000383e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003842:	02049593          	slli	a1,s1,0x20
    80003846:	9181                	srli	a1,a1,0x20
    80003848:	058a                	slli	a1,a1,0x2
    8000384a:	00b784b3          	add	s1,a5,a1
    8000384e:	0004a903          	lw	s2,0(s1)
    80003852:	02090063          	beqz	s2,80003872 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003856:	8552                	mv	a0,s4
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	c9c080e7          	jalr	-868(ra) # 800034f4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003860:	854a                	mv	a0,s2
    80003862:	70a2                	ld	ra,40(sp)
    80003864:	7402                	ld	s0,32(sp)
    80003866:	64e2                	ld	s1,24(sp)
    80003868:	6942                	ld	s2,16(sp)
    8000386a:	69a2                	ld	s3,8(sp)
    8000386c:	6a02                	ld	s4,0(sp)
    8000386e:	6145                	addi	sp,sp,48
    80003870:	8082                	ret
      addr = balloc(ip->dev);
    80003872:	0009a503          	lw	a0,0(s3)
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	e10080e7          	jalr	-496(ra) # 80003686 <balloc>
    8000387e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003882:	fc090ae3          	beqz	s2,80003856 <bmap+0x98>
        a[bn] = addr;
    80003886:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000388a:	8552                	mv	a0,s4
    8000388c:	00001097          	auipc	ra,0x1
    80003890:	1fe080e7          	jalr	510(ra) # 80004a8a <log_write>
    80003894:	b7c9                	j	80003856 <bmap+0x98>
  panic("bmap: out of range");
    80003896:	00005517          	auipc	a0,0x5
    8000389a:	d1250513          	addi	a0,a0,-750 # 800085a8 <syscalls+0x118>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	ca0080e7          	jalr	-864(ra) # 8000053e <panic>

00000000800038a6 <iget>:
{
    800038a6:	7179                	addi	sp,sp,-48
    800038a8:	f406                	sd	ra,40(sp)
    800038aa:	f022                	sd	s0,32(sp)
    800038ac:	ec26                	sd	s1,24(sp)
    800038ae:	e84a                	sd	s2,16(sp)
    800038b0:	e44e                	sd	s3,8(sp)
    800038b2:	e052                	sd	s4,0(sp)
    800038b4:	1800                	addi	s0,sp,48
    800038b6:	89aa                	mv	s3,a0
    800038b8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038ba:	0002c517          	auipc	a0,0x2c
    800038be:	e3e50513          	addi	a0,a0,-450 # 8002f6f8 <itable>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	314080e7          	jalr	788(ra) # 80000bd6 <acquire>
  empty = 0;
    800038ca:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038cc:	0002c497          	auipc	s1,0x2c
    800038d0:	e4448493          	addi	s1,s1,-444 # 8002f710 <itable+0x18>
    800038d4:	0002e697          	auipc	a3,0x2e
    800038d8:	8cc68693          	addi	a3,a3,-1844 # 800311a0 <log>
    800038dc:	a039                	j	800038ea <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038de:	02090b63          	beqz	s2,80003914 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038e2:	08848493          	addi	s1,s1,136
    800038e6:	02d48a63          	beq	s1,a3,8000391a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038ea:	449c                	lw	a5,8(s1)
    800038ec:	fef059e3          	blez	a5,800038de <iget+0x38>
    800038f0:	4098                	lw	a4,0(s1)
    800038f2:	ff3716e3          	bne	a4,s3,800038de <iget+0x38>
    800038f6:	40d8                	lw	a4,4(s1)
    800038f8:	ff4713e3          	bne	a4,s4,800038de <iget+0x38>
      ip->ref++;
    800038fc:	2785                	addiw	a5,a5,1
    800038fe:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003900:	0002c517          	auipc	a0,0x2c
    80003904:	df850513          	addi	a0,a0,-520 # 8002f6f8 <itable>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	382080e7          	jalr	898(ra) # 80000c8a <release>
      return ip;
    80003910:	8926                	mv	s2,s1
    80003912:	a03d                	j	80003940 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003914:	f7f9                	bnez	a5,800038e2 <iget+0x3c>
    80003916:	8926                	mv	s2,s1
    80003918:	b7e9                	j	800038e2 <iget+0x3c>
  if(empty == 0)
    8000391a:	02090c63          	beqz	s2,80003952 <iget+0xac>
  ip->dev = dev;
    8000391e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003922:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003926:	4785                	li	a5,1
    80003928:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000392c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003930:	0002c517          	auipc	a0,0x2c
    80003934:	dc850513          	addi	a0,a0,-568 # 8002f6f8 <itable>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	352080e7          	jalr	850(ra) # 80000c8a <release>
}
    80003940:	854a                	mv	a0,s2
    80003942:	70a2                	ld	ra,40(sp)
    80003944:	7402                	ld	s0,32(sp)
    80003946:	64e2                	ld	s1,24(sp)
    80003948:	6942                	ld	s2,16(sp)
    8000394a:	69a2                	ld	s3,8(sp)
    8000394c:	6a02                	ld	s4,0(sp)
    8000394e:	6145                	addi	sp,sp,48
    80003950:	8082                	ret
    panic("iget: no inodes");
    80003952:	00005517          	auipc	a0,0x5
    80003956:	c6e50513          	addi	a0,a0,-914 # 800085c0 <syscalls+0x130>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	be4080e7          	jalr	-1052(ra) # 8000053e <panic>

0000000080003962 <fsinit>:
fsinit(int dev) {
    80003962:	7179                	addi	sp,sp,-48
    80003964:	f406                	sd	ra,40(sp)
    80003966:	f022                	sd	s0,32(sp)
    80003968:	ec26                	sd	s1,24(sp)
    8000396a:	e84a                	sd	s2,16(sp)
    8000396c:	e44e                	sd	s3,8(sp)
    8000396e:	1800                	addi	s0,sp,48
    80003970:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003972:	4585                	li	a1,1
    80003974:	00000097          	auipc	ra,0x0
    80003978:	a50080e7          	jalr	-1456(ra) # 800033c4 <bread>
    8000397c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000397e:	0002c997          	auipc	s3,0x2c
    80003982:	d5a98993          	addi	s3,s3,-678 # 8002f6d8 <sb>
    80003986:	02000613          	li	a2,32
    8000398a:	05850593          	addi	a1,a0,88
    8000398e:	854e                	mv	a0,s3
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	39e080e7          	jalr	926(ra) # 80000d2e <memmove>
  brelse(bp);
    80003998:	8526                	mv	a0,s1
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	b5a080e7          	jalr	-1190(ra) # 800034f4 <brelse>
  if(sb.magic != FSMAGIC)
    800039a2:	0009a703          	lw	a4,0(s3)
    800039a6:	102037b7          	lui	a5,0x10203
    800039aa:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039ae:	02f71263          	bne	a4,a5,800039d2 <fsinit+0x70>
  initlog(dev, &sb);
    800039b2:	0002c597          	auipc	a1,0x2c
    800039b6:	d2658593          	addi	a1,a1,-730 # 8002f6d8 <sb>
    800039ba:	854a                	mv	a0,s2
    800039bc:	00001097          	auipc	ra,0x1
    800039c0:	e52080e7          	jalr	-430(ra) # 8000480e <initlog>
}
    800039c4:	70a2                	ld	ra,40(sp)
    800039c6:	7402                	ld	s0,32(sp)
    800039c8:	64e2                	ld	s1,24(sp)
    800039ca:	6942                	ld	s2,16(sp)
    800039cc:	69a2                	ld	s3,8(sp)
    800039ce:	6145                	addi	sp,sp,48
    800039d0:	8082                	ret
    panic("invalid file system");
    800039d2:	00005517          	auipc	a0,0x5
    800039d6:	bfe50513          	addi	a0,a0,-1026 # 800085d0 <syscalls+0x140>
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	b64080e7          	jalr	-1180(ra) # 8000053e <panic>

00000000800039e2 <iinit>:
{
    800039e2:	7179                	addi	sp,sp,-48
    800039e4:	f406                	sd	ra,40(sp)
    800039e6:	f022                	sd	s0,32(sp)
    800039e8:	ec26                	sd	s1,24(sp)
    800039ea:	e84a                	sd	s2,16(sp)
    800039ec:	e44e                	sd	s3,8(sp)
    800039ee:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039f0:	00005597          	auipc	a1,0x5
    800039f4:	bf858593          	addi	a1,a1,-1032 # 800085e8 <syscalls+0x158>
    800039f8:	0002c517          	auipc	a0,0x2c
    800039fc:	d0050513          	addi	a0,a0,-768 # 8002f6f8 <itable>
    80003a00:	ffffd097          	auipc	ra,0xffffd
    80003a04:	146080e7          	jalr	326(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a08:	0002c497          	auipc	s1,0x2c
    80003a0c:	d1848493          	addi	s1,s1,-744 # 8002f720 <itable+0x28>
    80003a10:	0002d997          	auipc	s3,0x2d
    80003a14:	7a098993          	addi	s3,s3,1952 # 800311b0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a18:	00005917          	auipc	s2,0x5
    80003a1c:	bd890913          	addi	s2,s2,-1064 # 800085f0 <syscalls+0x160>
    80003a20:	85ca                	mv	a1,s2
    80003a22:	8526                	mv	a0,s1
    80003a24:	00001097          	auipc	ra,0x1
    80003a28:	14c080e7          	jalr	332(ra) # 80004b70 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a2c:	08848493          	addi	s1,s1,136
    80003a30:	ff3498e3          	bne	s1,s3,80003a20 <iinit+0x3e>
}
    80003a34:	70a2                	ld	ra,40(sp)
    80003a36:	7402                	ld	s0,32(sp)
    80003a38:	64e2                	ld	s1,24(sp)
    80003a3a:	6942                	ld	s2,16(sp)
    80003a3c:	69a2                	ld	s3,8(sp)
    80003a3e:	6145                	addi	sp,sp,48
    80003a40:	8082                	ret

0000000080003a42 <ialloc>:
{
    80003a42:	715d                	addi	sp,sp,-80
    80003a44:	e486                	sd	ra,72(sp)
    80003a46:	e0a2                	sd	s0,64(sp)
    80003a48:	fc26                	sd	s1,56(sp)
    80003a4a:	f84a                	sd	s2,48(sp)
    80003a4c:	f44e                	sd	s3,40(sp)
    80003a4e:	f052                	sd	s4,32(sp)
    80003a50:	ec56                	sd	s5,24(sp)
    80003a52:	e85a                	sd	s6,16(sp)
    80003a54:	e45e                	sd	s7,8(sp)
    80003a56:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a58:	0002c717          	auipc	a4,0x2c
    80003a5c:	c8c72703          	lw	a4,-884(a4) # 8002f6e4 <sb+0xc>
    80003a60:	4785                	li	a5,1
    80003a62:	04e7fa63          	bgeu	a5,a4,80003ab6 <ialloc+0x74>
    80003a66:	8aaa                	mv	s5,a0
    80003a68:	8bae                	mv	s7,a1
    80003a6a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a6c:	0002ca17          	auipc	s4,0x2c
    80003a70:	c6ca0a13          	addi	s4,s4,-916 # 8002f6d8 <sb>
    80003a74:	00048b1b          	sext.w	s6,s1
    80003a78:	0044d793          	srli	a5,s1,0x4
    80003a7c:	018a2583          	lw	a1,24(s4)
    80003a80:	9dbd                	addw	a1,a1,a5
    80003a82:	8556                	mv	a0,s5
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	940080e7          	jalr	-1728(ra) # 800033c4 <bread>
    80003a8c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a8e:	05850993          	addi	s3,a0,88
    80003a92:	00f4f793          	andi	a5,s1,15
    80003a96:	079a                	slli	a5,a5,0x6
    80003a98:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a9a:	00099783          	lh	a5,0(s3)
    80003a9e:	c3a1                	beqz	a5,80003ade <ialloc+0x9c>
    brelse(bp);
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	a54080e7          	jalr	-1452(ra) # 800034f4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003aa8:	0485                	addi	s1,s1,1
    80003aaa:	00ca2703          	lw	a4,12(s4)
    80003aae:	0004879b          	sext.w	a5,s1
    80003ab2:	fce7e1e3          	bltu	a5,a4,80003a74 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003ab6:	00005517          	auipc	a0,0x5
    80003aba:	b4250513          	addi	a0,a0,-1214 # 800085f8 <syscalls+0x168>
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	aca080e7          	jalr	-1334(ra) # 80000588 <printf>
  return 0;
    80003ac6:	4501                	li	a0,0
}
    80003ac8:	60a6                	ld	ra,72(sp)
    80003aca:	6406                	ld	s0,64(sp)
    80003acc:	74e2                	ld	s1,56(sp)
    80003ace:	7942                	ld	s2,48(sp)
    80003ad0:	79a2                	ld	s3,40(sp)
    80003ad2:	7a02                	ld	s4,32(sp)
    80003ad4:	6ae2                	ld	s5,24(sp)
    80003ad6:	6b42                	ld	s6,16(sp)
    80003ad8:	6ba2                	ld	s7,8(sp)
    80003ada:	6161                	addi	sp,sp,80
    80003adc:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003ade:	04000613          	li	a2,64
    80003ae2:	4581                	li	a1,0
    80003ae4:	854e                	mv	a0,s3
    80003ae6:	ffffd097          	auipc	ra,0xffffd
    80003aea:	1ec080e7          	jalr	492(ra) # 80000cd2 <memset>
      dip->type = type;
    80003aee:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003af2:	854a                	mv	a0,s2
    80003af4:	00001097          	auipc	ra,0x1
    80003af8:	f96080e7          	jalr	-106(ra) # 80004a8a <log_write>
      brelse(bp);
    80003afc:	854a                	mv	a0,s2
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	9f6080e7          	jalr	-1546(ra) # 800034f4 <brelse>
      return iget(dev, inum);
    80003b06:	85da                	mv	a1,s6
    80003b08:	8556                	mv	a0,s5
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	d9c080e7          	jalr	-612(ra) # 800038a6 <iget>
    80003b12:	bf5d                	j	80003ac8 <ialloc+0x86>

0000000080003b14 <iupdate>:
{
    80003b14:	1101                	addi	sp,sp,-32
    80003b16:	ec06                	sd	ra,24(sp)
    80003b18:	e822                	sd	s0,16(sp)
    80003b1a:	e426                	sd	s1,8(sp)
    80003b1c:	e04a                	sd	s2,0(sp)
    80003b1e:	1000                	addi	s0,sp,32
    80003b20:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b22:	415c                	lw	a5,4(a0)
    80003b24:	0047d79b          	srliw	a5,a5,0x4
    80003b28:	0002c597          	auipc	a1,0x2c
    80003b2c:	bc85a583          	lw	a1,-1080(a1) # 8002f6f0 <sb+0x18>
    80003b30:	9dbd                	addw	a1,a1,a5
    80003b32:	4108                	lw	a0,0(a0)
    80003b34:	00000097          	auipc	ra,0x0
    80003b38:	890080e7          	jalr	-1904(ra) # 800033c4 <bread>
    80003b3c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b3e:	05850793          	addi	a5,a0,88
    80003b42:	40c8                	lw	a0,4(s1)
    80003b44:	893d                	andi	a0,a0,15
    80003b46:	051a                	slli	a0,a0,0x6
    80003b48:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b4a:	04449703          	lh	a4,68(s1)
    80003b4e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b52:	04649703          	lh	a4,70(s1)
    80003b56:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b5a:	04849703          	lh	a4,72(s1)
    80003b5e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b62:	04a49703          	lh	a4,74(s1)
    80003b66:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b6a:	44f8                	lw	a4,76(s1)
    80003b6c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b6e:	03400613          	li	a2,52
    80003b72:	05048593          	addi	a1,s1,80
    80003b76:	0531                	addi	a0,a0,12
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	1b6080e7          	jalr	438(ra) # 80000d2e <memmove>
  log_write(bp);
    80003b80:	854a                	mv	a0,s2
    80003b82:	00001097          	auipc	ra,0x1
    80003b86:	f08080e7          	jalr	-248(ra) # 80004a8a <log_write>
  brelse(bp);
    80003b8a:	854a                	mv	a0,s2
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	968080e7          	jalr	-1688(ra) # 800034f4 <brelse>
}
    80003b94:	60e2                	ld	ra,24(sp)
    80003b96:	6442                	ld	s0,16(sp)
    80003b98:	64a2                	ld	s1,8(sp)
    80003b9a:	6902                	ld	s2,0(sp)
    80003b9c:	6105                	addi	sp,sp,32
    80003b9e:	8082                	ret

0000000080003ba0 <idup>:
{
    80003ba0:	1101                	addi	sp,sp,-32
    80003ba2:	ec06                	sd	ra,24(sp)
    80003ba4:	e822                	sd	s0,16(sp)
    80003ba6:	e426                	sd	s1,8(sp)
    80003ba8:	1000                	addi	s0,sp,32
    80003baa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bac:	0002c517          	auipc	a0,0x2c
    80003bb0:	b4c50513          	addi	a0,a0,-1204 # 8002f6f8 <itable>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	022080e7          	jalr	34(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003bbc:	449c                	lw	a5,8(s1)
    80003bbe:	2785                	addiw	a5,a5,1
    80003bc0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bc2:	0002c517          	auipc	a0,0x2c
    80003bc6:	b3650513          	addi	a0,a0,-1226 # 8002f6f8 <itable>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	0c0080e7          	jalr	192(ra) # 80000c8a <release>
}
    80003bd2:	8526                	mv	a0,s1
    80003bd4:	60e2                	ld	ra,24(sp)
    80003bd6:	6442                	ld	s0,16(sp)
    80003bd8:	64a2                	ld	s1,8(sp)
    80003bda:	6105                	addi	sp,sp,32
    80003bdc:	8082                	ret

0000000080003bde <ilock>:
{
    80003bde:	1101                	addi	sp,sp,-32
    80003be0:	ec06                	sd	ra,24(sp)
    80003be2:	e822                	sd	s0,16(sp)
    80003be4:	e426                	sd	s1,8(sp)
    80003be6:	e04a                	sd	s2,0(sp)
    80003be8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bea:	c115                	beqz	a0,80003c0e <ilock+0x30>
    80003bec:	84aa                	mv	s1,a0
    80003bee:	451c                	lw	a5,8(a0)
    80003bf0:	00f05f63          	blez	a5,80003c0e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003bf4:	0541                	addi	a0,a0,16
    80003bf6:	00001097          	auipc	ra,0x1
    80003bfa:	fb4080e7          	jalr	-76(ra) # 80004baa <acquiresleep>
  if(ip->valid == 0){
    80003bfe:	40bc                	lw	a5,64(s1)
    80003c00:	cf99                	beqz	a5,80003c1e <ilock+0x40>
}
    80003c02:	60e2                	ld	ra,24(sp)
    80003c04:	6442                	ld	s0,16(sp)
    80003c06:	64a2                	ld	s1,8(sp)
    80003c08:	6902                	ld	s2,0(sp)
    80003c0a:	6105                	addi	sp,sp,32
    80003c0c:	8082                	ret
    panic("ilock");
    80003c0e:	00005517          	auipc	a0,0x5
    80003c12:	a0250513          	addi	a0,a0,-1534 # 80008610 <syscalls+0x180>
    80003c16:	ffffd097          	auipc	ra,0xffffd
    80003c1a:	928080e7          	jalr	-1752(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c1e:	40dc                	lw	a5,4(s1)
    80003c20:	0047d79b          	srliw	a5,a5,0x4
    80003c24:	0002c597          	auipc	a1,0x2c
    80003c28:	acc5a583          	lw	a1,-1332(a1) # 8002f6f0 <sb+0x18>
    80003c2c:	9dbd                	addw	a1,a1,a5
    80003c2e:	4088                	lw	a0,0(s1)
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	794080e7          	jalr	1940(ra) # 800033c4 <bread>
    80003c38:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c3a:	05850593          	addi	a1,a0,88
    80003c3e:	40dc                	lw	a5,4(s1)
    80003c40:	8bbd                	andi	a5,a5,15
    80003c42:	079a                	slli	a5,a5,0x6
    80003c44:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c46:	00059783          	lh	a5,0(a1)
    80003c4a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c4e:	00259783          	lh	a5,2(a1)
    80003c52:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c56:	00459783          	lh	a5,4(a1)
    80003c5a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c5e:	00659783          	lh	a5,6(a1)
    80003c62:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c66:	459c                	lw	a5,8(a1)
    80003c68:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c6a:	03400613          	li	a2,52
    80003c6e:	05b1                	addi	a1,a1,12
    80003c70:	05048513          	addi	a0,s1,80
    80003c74:	ffffd097          	auipc	ra,0xffffd
    80003c78:	0ba080e7          	jalr	186(ra) # 80000d2e <memmove>
    brelse(bp);
    80003c7c:	854a                	mv	a0,s2
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	876080e7          	jalr	-1930(ra) # 800034f4 <brelse>
    ip->valid = 1;
    80003c86:	4785                	li	a5,1
    80003c88:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c8a:	04449783          	lh	a5,68(s1)
    80003c8e:	fbb5                	bnez	a5,80003c02 <ilock+0x24>
      panic("ilock: no type");
    80003c90:	00005517          	auipc	a0,0x5
    80003c94:	98850513          	addi	a0,a0,-1656 # 80008618 <syscalls+0x188>
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	8a6080e7          	jalr	-1882(ra) # 8000053e <panic>

0000000080003ca0 <iunlock>:
{
    80003ca0:	1101                	addi	sp,sp,-32
    80003ca2:	ec06                	sd	ra,24(sp)
    80003ca4:	e822                	sd	s0,16(sp)
    80003ca6:	e426                	sd	s1,8(sp)
    80003ca8:	e04a                	sd	s2,0(sp)
    80003caa:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cac:	c905                	beqz	a0,80003cdc <iunlock+0x3c>
    80003cae:	84aa                	mv	s1,a0
    80003cb0:	01050913          	addi	s2,a0,16
    80003cb4:	854a                	mv	a0,s2
    80003cb6:	00001097          	auipc	ra,0x1
    80003cba:	f8e080e7          	jalr	-114(ra) # 80004c44 <holdingsleep>
    80003cbe:	cd19                	beqz	a0,80003cdc <iunlock+0x3c>
    80003cc0:	449c                	lw	a5,8(s1)
    80003cc2:	00f05d63          	blez	a5,80003cdc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	00001097          	auipc	ra,0x1
    80003ccc:	f38080e7          	jalr	-200(ra) # 80004c00 <releasesleep>
}
    80003cd0:	60e2                	ld	ra,24(sp)
    80003cd2:	6442                	ld	s0,16(sp)
    80003cd4:	64a2                	ld	s1,8(sp)
    80003cd6:	6902                	ld	s2,0(sp)
    80003cd8:	6105                	addi	sp,sp,32
    80003cda:	8082                	ret
    panic("iunlock");
    80003cdc:	00005517          	auipc	a0,0x5
    80003ce0:	94c50513          	addi	a0,a0,-1716 # 80008628 <syscalls+0x198>
    80003ce4:	ffffd097          	auipc	ra,0xffffd
    80003ce8:	85a080e7          	jalr	-1958(ra) # 8000053e <panic>

0000000080003cec <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cec:	7179                	addi	sp,sp,-48
    80003cee:	f406                	sd	ra,40(sp)
    80003cf0:	f022                	sd	s0,32(sp)
    80003cf2:	ec26                	sd	s1,24(sp)
    80003cf4:	e84a                	sd	s2,16(sp)
    80003cf6:	e44e                	sd	s3,8(sp)
    80003cf8:	e052                	sd	s4,0(sp)
    80003cfa:	1800                	addi	s0,sp,48
    80003cfc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cfe:	05050493          	addi	s1,a0,80
    80003d02:	08050913          	addi	s2,a0,128
    80003d06:	a021                	j	80003d0e <itrunc+0x22>
    80003d08:	0491                	addi	s1,s1,4
    80003d0a:	01248d63          	beq	s1,s2,80003d24 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d0e:	408c                	lw	a1,0(s1)
    80003d10:	dde5                	beqz	a1,80003d08 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d12:	0009a503          	lw	a0,0(s3)
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	8f4080e7          	jalr	-1804(ra) # 8000360a <bfree>
      ip->addrs[i] = 0;
    80003d1e:	0004a023          	sw	zero,0(s1)
    80003d22:	b7dd                	j	80003d08 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d24:	0809a583          	lw	a1,128(s3)
    80003d28:	e185                	bnez	a1,80003d48 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d2a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d2e:	854e                	mv	a0,s3
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	de4080e7          	jalr	-540(ra) # 80003b14 <iupdate>
}
    80003d38:	70a2                	ld	ra,40(sp)
    80003d3a:	7402                	ld	s0,32(sp)
    80003d3c:	64e2                	ld	s1,24(sp)
    80003d3e:	6942                	ld	s2,16(sp)
    80003d40:	69a2                	ld	s3,8(sp)
    80003d42:	6a02                	ld	s4,0(sp)
    80003d44:	6145                	addi	sp,sp,48
    80003d46:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d48:	0009a503          	lw	a0,0(s3)
    80003d4c:	fffff097          	auipc	ra,0xfffff
    80003d50:	678080e7          	jalr	1656(ra) # 800033c4 <bread>
    80003d54:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d56:	05850493          	addi	s1,a0,88
    80003d5a:	45850913          	addi	s2,a0,1112
    80003d5e:	a021                	j	80003d66 <itrunc+0x7a>
    80003d60:	0491                	addi	s1,s1,4
    80003d62:	01248b63          	beq	s1,s2,80003d78 <itrunc+0x8c>
      if(a[j])
    80003d66:	408c                	lw	a1,0(s1)
    80003d68:	dde5                	beqz	a1,80003d60 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d6a:	0009a503          	lw	a0,0(s3)
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	89c080e7          	jalr	-1892(ra) # 8000360a <bfree>
    80003d76:	b7ed                	j	80003d60 <itrunc+0x74>
    brelse(bp);
    80003d78:	8552                	mv	a0,s4
    80003d7a:	fffff097          	auipc	ra,0xfffff
    80003d7e:	77a080e7          	jalr	1914(ra) # 800034f4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d82:	0809a583          	lw	a1,128(s3)
    80003d86:	0009a503          	lw	a0,0(s3)
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	880080e7          	jalr	-1920(ra) # 8000360a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d92:	0809a023          	sw	zero,128(s3)
    80003d96:	bf51                	j	80003d2a <itrunc+0x3e>

0000000080003d98 <iput>:
{
    80003d98:	1101                	addi	sp,sp,-32
    80003d9a:	ec06                	sd	ra,24(sp)
    80003d9c:	e822                	sd	s0,16(sp)
    80003d9e:	e426                	sd	s1,8(sp)
    80003da0:	e04a                	sd	s2,0(sp)
    80003da2:	1000                	addi	s0,sp,32
    80003da4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003da6:	0002c517          	auipc	a0,0x2c
    80003daa:	95250513          	addi	a0,a0,-1710 # 8002f6f8 <itable>
    80003dae:	ffffd097          	auipc	ra,0xffffd
    80003db2:	e28080e7          	jalr	-472(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003db6:	4498                	lw	a4,8(s1)
    80003db8:	4785                	li	a5,1
    80003dba:	02f70363          	beq	a4,a5,80003de0 <iput+0x48>
  ip->ref--;
    80003dbe:	449c                	lw	a5,8(s1)
    80003dc0:	37fd                	addiw	a5,a5,-1
    80003dc2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dc4:	0002c517          	auipc	a0,0x2c
    80003dc8:	93450513          	addi	a0,a0,-1740 # 8002f6f8 <itable>
    80003dcc:	ffffd097          	auipc	ra,0xffffd
    80003dd0:	ebe080e7          	jalr	-322(ra) # 80000c8a <release>
}
    80003dd4:	60e2                	ld	ra,24(sp)
    80003dd6:	6442                	ld	s0,16(sp)
    80003dd8:	64a2                	ld	s1,8(sp)
    80003dda:	6902                	ld	s2,0(sp)
    80003ddc:	6105                	addi	sp,sp,32
    80003dde:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003de0:	40bc                	lw	a5,64(s1)
    80003de2:	dff1                	beqz	a5,80003dbe <iput+0x26>
    80003de4:	04a49783          	lh	a5,74(s1)
    80003de8:	fbf9                	bnez	a5,80003dbe <iput+0x26>
    acquiresleep(&ip->lock);
    80003dea:	01048913          	addi	s2,s1,16
    80003dee:	854a                	mv	a0,s2
    80003df0:	00001097          	auipc	ra,0x1
    80003df4:	dba080e7          	jalr	-582(ra) # 80004baa <acquiresleep>
    release(&itable.lock);
    80003df8:	0002c517          	auipc	a0,0x2c
    80003dfc:	90050513          	addi	a0,a0,-1792 # 8002f6f8 <itable>
    80003e00:	ffffd097          	auipc	ra,0xffffd
    80003e04:	e8a080e7          	jalr	-374(ra) # 80000c8a <release>
    itrunc(ip);
    80003e08:	8526                	mv	a0,s1
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	ee2080e7          	jalr	-286(ra) # 80003cec <itrunc>
    ip->type = 0;
    80003e12:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e16:	8526                	mv	a0,s1
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	cfc080e7          	jalr	-772(ra) # 80003b14 <iupdate>
    ip->valid = 0;
    80003e20:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e24:	854a                	mv	a0,s2
    80003e26:	00001097          	auipc	ra,0x1
    80003e2a:	dda080e7          	jalr	-550(ra) # 80004c00 <releasesleep>
    acquire(&itable.lock);
    80003e2e:	0002c517          	auipc	a0,0x2c
    80003e32:	8ca50513          	addi	a0,a0,-1846 # 8002f6f8 <itable>
    80003e36:	ffffd097          	auipc	ra,0xffffd
    80003e3a:	da0080e7          	jalr	-608(ra) # 80000bd6 <acquire>
    80003e3e:	b741                	j	80003dbe <iput+0x26>

0000000080003e40 <iunlockput>:
{
    80003e40:	1101                	addi	sp,sp,-32
    80003e42:	ec06                	sd	ra,24(sp)
    80003e44:	e822                	sd	s0,16(sp)
    80003e46:	e426                	sd	s1,8(sp)
    80003e48:	1000                	addi	s0,sp,32
    80003e4a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	e54080e7          	jalr	-428(ra) # 80003ca0 <iunlock>
  iput(ip);
    80003e54:	8526                	mv	a0,s1
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	f42080e7          	jalr	-190(ra) # 80003d98 <iput>
}
    80003e5e:	60e2                	ld	ra,24(sp)
    80003e60:	6442                	ld	s0,16(sp)
    80003e62:	64a2                	ld	s1,8(sp)
    80003e64:	6105                	addi	sp,sp,32
    80003e66:	8082                	ret

0000000080003e68 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e68:	1141                	addi	sp,sp,-16
    80003e6a:	e422                	sd	s0,8(sp)
    80003e6c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e6e:	411c                	lw	a5,0(a0)
    80003e70:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e72:	415c                	lw	a5,4(a0)
    80003e74:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e76:	04451783          	lh	a5,68(a0)
    80003e7a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e7e:	04a51783          	lh	a5,74(a0)
    80003e82:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e86:	04c56783          	lwu	a5,76(a0)
    80003e8a:	e99c                	sd	a5,16(a1)
}
    80003e8c:	6422                	ld	s0,8(sp)
    80003e8e:	0141                	addi	sp,sp,16
    80003e90:	8082                	ret

0000000080003e92 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e92:	457c                	lw	a5,76(a0)
    80003e94:	0ed7e963          	bltu	a5,a3,80003f86 <readi+0xf4>
{
    80003e98:	7159                	addi	sp,sp,-112
    80003e9a:	f486                	sd	ra,104(sp)
    80003e9c:	f0a2                	sd	s0,96(sp)
    80003e9e:	eca6                	sd	s1,88(sp)
    80003ea0:	e8ca                	sd	s2,80(sp)
    80003ea2:	e4ce                	sd	s3,72(sp)
    80003ea4:	e0d2                	sd	s4,64(sp)
    80003ea6:	fc56                	sd	s5,56(sp)
    80003ea8:	f85a                	sd	s6,48(sp)
    80003eaa:	f45e                	sd	s7,40(sp)
    80003eac:	f062                	sd	s8,32(sp)
    80003eae:	ec66                	sd	s9,24(sp)
    80003eb0:	e86a                	sd	s10,16(sp)
    80003eb2:	e46e                	sd	s11,8(sp)
    80003eb4:	1880                	addi	s0,sp,112
    80003eb6:	8b2a                	mv	s6,a0
    80003eb8:	8bae                	mv	s7,a1
    80003eba:	8a32                	mv	s4,a2
    80003ebc:	84b6                	mv	s1,a3
    80003ebe:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ec0:	9f35                	addw	a4,a4,a3
    return 0;
    80003ec2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ec4:	0ad76063          	bltu	a4,a3,80003f64 <readi+0xd2>
  if(off + n > ip->size)
    80003ec8:	00e7f463          	bgeu	a5,a4,80003ed0 <readi+0x3e>
    n = ip->size - off;
    80003ecc:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ed0:	0a0a8963          	beqz	s5,80003f82 <readi+0xf0>
    80003ed4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ed6:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003eda:	5c7d                	li	s8,-1
    80003edc:	a82d                	j	80003f16 <readi+0x84>
    80003ede:	020d1d93          	slli	s11,s10,0x20
    80003ee2:	020ddd93          	srli	s11,s11,0x20
    80003ee6:	05890793          	addi	a5,s2,88
    80003eea:	86ee                	mv	a3,s11
    80003eec:	963e                	add	a2,a2,a5
    80003eee:	85d2                	mv	a1,s4
    80003ef0:	855e                	mv	a0,s7
    80003ef2:	fffff097          	auipc	ra,0xfffff
    80003ef6:	b1c080e7          	jalr	-1252(ra) # 80002a0e <either_copyout>
    80003efa:	05850d63          	beq	a0,s8,80003f54 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003efe:	854a                	mv	a0,s2
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	5f4080e7          	jalr	1524(ra) # 800034f4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f08:	013d09bb          	addw	s3,s10,s3
    80003f0c:	009d04bb          	addw	s1,s10,s1
    80003f10:	9a6e                	add	s4,s4,s11
    80003f12:	0559f763          	bgeu	s3,s5,80003f60 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f16:	00a4d59b          	srliw	a1,s1,0xa
    80003f1a:	855a                	mv	a0,s6
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	8a2080e7          	jalr	-1886(ra) # 800037be <bmap>
    80003f24:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f28:	cd85                	beqz	a1,80003f60 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f2a:	000b2503          	lw	a0,0(s6)
    80003f2e:	fffff097          	auipc	ra,0xfffff
    80003f32:	496080e7          	jalr	1174(ra) # 800033c4 <bread>
    80003f36:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f38:	3ff4f613          	andi	a2,s1,1023
    80003f3c:	40cc87bb          	subw	a5,s9,a2
    80003f40:	413a873b          	subw	a4,s5,s3
    80003f44:	8d3e                	mv	s10,a5
    80003f46:	2781                	sext.w	a5,a5
    80003f48:	0007069b          	sext.w	a3,a4
    80003f4c:	f8f6f9e3          	bgeu	a3,a5,80003ede <readi+0x4c>
    80003f50:	8d3a                	mv	s10,a4
    80003f52:	b771                	j	80003ede <readi+0x4c>
      brelse(bp);
    80003f54:	854a                	mv	a0,s2
    80003f56:	fffff097          	auipc	ra,0xfffff
    80003f5a:	59e080e7          	jalr	1438(ra) # 800034f4 <brelse>
      tot = -1;
    80003f5e:	59fd                	li	s3,-1
  }
  return tot;
    80003f60:	0009851b          	sext.w	a0,s3
}
    80003f64:	70a6                	ld	ra,104(sp)
    80003f66:	7406                	ld	s0,96(sp)
    80003f68:	64e6                	ld	s1,88(sp)
    80003f6a:	6946                	ld	s2,80(sp)
    80003f6c:	69a6                	ld	s3,72(sp)
    80003f6e:	6a06                	ld	s4,64(sp)
    80003f70:	7ae2                	ld	s5,56(sp)
    80003f72:	7b42                	ld	s6,48(sp)
    80003f74:	7ba2                	ld	s7,40(sp)
    80003f76:	7c02                	ld	s8,32(sp)
    80003f78:	6ce2                	ld	s9,24(sp)
    80003f7a:	6d42                	ld	s10,16(sp)
    80003f7c:	6da2                	ld	s11,8(sp)
    80003f7e:	6165                	addi	sp,sp,112
    80003f80:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f82:	89d6                	mv	s3,s5
    80003f84:	bff1                	j	80003f60 <readi+0xce>
    return 0;
    80003f86:	4501                	li	a0,0
}
    80003f88:	8082                	ret

0000000080003f8a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f8a:	457c                	lw	a5,76(a0)
    80003f8c:	10d7e863          	bltu	a5,a3,8000409c <writei+0x112>
{
    80003f90:	7159                	addi	sp,sp,-112
    80003f92:	f486                	sd	ra,104(sp)
    80003f94:	f0a2                	sd	s0,96(sp)
    80003f96:	eca6                	sd	s1,88(sp)
    80003f98:	e8ca                	sd	s2,80(sp)
    80003f9a:	e4ce                	sd	s3,72(sp)
    80003f9c:	e0d2                	sd	s4,64(sp)
    80003f9e:	fc56                	sd	s5,56(sp)
    80003fa0:	f85a                	sd	s6,48(sp)
    80003fa2:	f45e                	sd	s7,40(sp)
    80003fa4:	f062                	sd	s8,32(sp)
    80003fa6:	ec66                	sd	s9,24(sp)
    80003fa8:	e86a                	sd	s10,16(sp)
    80003faa:	e46e                	sd	s11,8(sp)
    80003fac:	1880                	addi	s0,sp,112
    80003fae:	8aaa                	mv	s5,a0
    80003fb0:	8bae                	mv	s7,a1
    80003fb2:	8a32                	mv	s4,a2
    80003fb4:	8936                	mv	s2,a3
    80003fb6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fb8:	00e687bb          	addw	a5,a3,a4
    80003fbc:	0ed7e263          	bltu	a5,a3,800040a0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fc0:	00043737          	lui	a4,0x43
    80003fc4:	0ef76063          	bltu	a4,a5,800040a4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fc8:	0c0b0863          	beqz	s6,80004098 <writei+0x10e>
    80003fcc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fce:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fd2:	5c7d                	li	s8,-1
    80003fd4:	a091                	j	80004018 <writei+0x8e>
    80003fd6:	020d1d93          	slli	s11,s10,0x20
    80003fda:	020ddd93          	srli	s11,s11,0x20
    80003fde:	05848793          	addi	a5,s1,88
    80003fe2:	86ee                	mv	a3,s11
    80003fe4:	8652                	mv	a2,s4
    80003fe6:	85de                	mv	a1,s7
    80003fe8:	953e                	add	a0,a0,a5
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	a7a080e7          	jalr	-1414(ra) # 80002a64 <either_copyin>
    80003ff2:	07850263          	beq	a0,s8,80004056 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ff6:	8526                	mv	a0,s1
    80003ff8:	00001097          	auipc	ra,0x1
    80003ffc:	a92080e7          	jalr	-1390(ra) # 80004a8a <log_write>
    brelse(bp);
    80004000:	8526                	mv	a0,s1
    80004002:	fffff097          	auipc	ra,0xfffff
    80004006:	4f2080e7          	jalr	1266(ra) # 800034f4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000400a:	013d09bb          	addw	s3,s10,s3
    8000400e:	012d093b          	addw	s2,s10,s2
    80004012:	9a6e                	add	s4,s4,s11
    80004014:	0569f663          	bgeu	s3,s6,80004060 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004018:	00a9559b          	srliw	a1,s2,0xa
    8000401c:	8556                	mv	a0,s5
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	7a0080e7          	jalr	1952(ra) # 800037be <bmap>
    80004026:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000402a:	c99d                	beqz	a1,80004060 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000402c:	000aa503          	lw	a0,0(s5)
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	394080e7          	jalr	916(ra) # 800033c4 <bread>
    80004038:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000403a:	3ff97513          	andi	a0,s2,1023
    8000403e:	40ac87bb          	subw	a5,s9,a0
    80004042:	413b073b          	subw	a4,s6,s3
    80004046:	8d3e                	mv	s10,a5
    80004048:	2781                	sext.w	a5,a5
    8000404a:	0007069b          	sext.w	a3,a4
    8000404e:	f8f6f4e3          	bgeu	a3,a5,80003fd6 <writei+0x4c>
    80004052:	8d3a                	mv	s10,a4
    80004054:	b749                	j	80003fd6 <writei+0x4c>
      brelse(bp);
    80004056:	8526                	mv	a0,s1
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	49c080e7          	jalr	1180(ra) # 800034f4 <brelse>
  }

  if(off > ip->size)
    80004060:	04caa783          	lw	a5,76(s5)
    80004064:	0127f463          	bgeu	a5,s2,8000406c <writei+0xe2>
    ip->size = off;
    80004068:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000406c:	8556                	mv	a0,s5
    8000406e:	00000097          	auipc	ra,0x0
    80004072:	aa6080e7          	jalr	-1370(ra) # 80003b14 <iupdate>

  return tot;
    80004076:	0009851b          	sext.w	a0,s3
}
    8000407a:	70a6                	ld	ra,104(sp)
    8000407c:	7406                	ld	s0,96(sp)
    8000407e:	64e6                	ld	s1,88(sp)
    80004080:	6946                	ld	s2,80(sp)
    80004082:	69a6                	ld	s3,72(sp)
    80004084:	6a06                	ld	s4,64(sp)
    80004086:	7ae2                	ld	s5,56(sp)
    80004088:	7b42                	ld	s6,48(sp)
    8000408a:	7ba2                	ld	s7,40(sp)
    8000408c:	7c02                	ld	s8,32(sp)
    8000408e:	6ce2                	ld	s9,24(sp)
    80004090:	6d42                	ld	s10,16(sp)
    80004092:	6da2                	ld	s11,8(sp)
    80004094:	6165                	addi	sp,sp,112
    80004096:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004098:	89da                	mv	s3,s6
    8000409a:	bfc9                	j	8000406c <writei+0xe2>
    return -1;
    8000409c:	557d                	li	a0,-1
}
    8000409e:	8082                	ret
    return -1;
    800040a0:	557d                	li	a0,-1
    800040a2:	bfe1                	j	8000407a <writei+0xf0>
    return -1;
    800040a4:	557d                	li	a0,-1
    800040a6:	bfd1                	j	8000407a <writei+0xf0>

00000000800040a8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040a8:	1141                	addi	sp,sp,-16
    800040aa:	e406                	sd	ra,8(sp)
    800040ac:	e022                	sd	s0,0(sp)
    800040ae:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040b0:	4639                	li	a2,14
    800040b2:	ffffd097          	auipc	ra,0xffffd
    800040b6:	cf0080e7          	jalr	-784(ra) # 80000da2 <strncmp>
}
    800040ba:	60a2                	ld	ra,8(sp)
    800040bc:	6402                	ld	s0,0(sp)
    800040be:	0141                	addi	sp,sp,16
    800040c0:	8082                	ret

00000000800040c2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040c2:	7139                	addi	sp,sp,-64
    800040c4:	fc06                	sd	ra,56(sp)
    800040c6:	f822                	sd	s0,48(sp)
    800040c8:	f426                	sd	s1,40(sp)
    800040ca:	f04a                	sd	s2,32(sp)
    800040cc:	ec4e                	sd	s3,24(sp)
    800040ce:	e852                	sd	s4,16(sp)
    800040d0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040d2:	04451703          	lh	a4,68(a0)
    800040d6:	4785                	li	a5,1
    800040d8:	00f71a63          	bne	a4,a5,800040ec <dirlookup+0x2a>
    800040dc:	892a                	mv	s2,a0
    800040de:	89ae                	mv	s3,a1
    800040e0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040e2:	457c                	lw	a5,76(a0)
    800040e4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040e6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040e8:	e79d                	bnez	a5,80004116 <dirlookup+0x54>
    800040ea:	a8a5                	j	80004162 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040ec:	00004517          	auipc	a0,0x4
    800040f0:	54450513          	addi	a0,a0,1348 # 80008630 <syscalls+0x1a0>
    800040f4:	ffffc097          	auipc	ra,0xffffc
    800040f8:	44a080e7          	jalr	1098(ra) # 8000053e <panic>
      panic("dirlookup read");
    800040fc:	00004517          	auipc	a0,0x4
    80004100:	54c50513          	addi	a0,a0,1356 # 80008648 <syscalls+0x1b8>
    80004104:	ffffc097          	auipc	ra,0xffffc
    80004108:	43a080e7          	jalr	1082(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000410c:	24c1                	addiw	s1,s1,16
    8000410e:	04c92783          	lw	a5,76(s2)
    80004112:	04f4f763          	bgeu	s1,a5,80004160 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004116:	4741                	li	a4,16
    80004118:	86a6                	mv	a3,s1
    8000411a:	fc040613          	addi	a2,s0,-64
    8000411e:	4581                	li	a1,0
    80004120:	854a                	mv	a0,s2
    80004122:	00000097          	auipc	ra,0x0
    80004126:	d70080e7          	jalr	-656(ra) # 80003e92 <readi>
    8000412a:	47c1                	li	a5,16
    8000412c:	fcf518e3          	bne	a0,a5,800040fc <dirlookup+0x3a>
    if(de.inum == 0)
    80004130:	fc045783          	lhu	a5,-64(s0)
    80004134:	dfe1                	beqz	a5,8000410c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004136:	fc240593          	addi	a1,s0,-62
    8000413a:	854e                	mv	a0,s3
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	f6c080e7          	jalr	-148(ra) # 800040a8 <namecmp>
    80004144:	f561                	bnez	a0,8000410c <dirlookup+0x4a>
      if(poff)
    80004146:	000a0463          	beqz	s4,8000414e <dirlookup+0x8c>
        *poff = off;
    8000414a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000414e:	fc045583          	lhu	a1,-64(s0)
    80004152:	00092503          	lw	a0,0(s2)
    80004156:	fffff097          	auipc	ra,0xfffff
    8000415a:	750080e7          	jalr	1872(ra) # 800038a6 <iget>
    8000415e:	a011                	j	80004162 <dirlookup+0xa0>
  return 0;
    80004160:	4501                	li	a0,0
}
    80004162:	70e2                	ld	ra,56(sp)
    80004164:	7442                	ld	s0,48(sp)
    80004166:	74a2                	ld	s1,40(sp)
    80004168:	7902                	ld	s2,32(sp)
    8000416a:	69e2                	ld	s3,24(sp)
    8000416c:	6a42                	ld	s4,16(sp)
    8000416e:	6121                	addi	sp,sp,64
    80004170:	8082                	ret

0000000080004172 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004172:	711d                	addi	sp,sp,-96
    80004174:	ec86                	sd	ra,88(sp)
    80004176:	e8a2                	sd	s0,80(sp)
    80004178:	e4a6                	sd	s1,72(sp)
    8000417a:	e0ca                	sd	s2,64(sp)
    8000417c:	fc4e                	sd	s3,56(sp)
    8000417e:	f852                	sd	s4,48(sp)
    80004180:	f456                	sd	s5,40(sp)
    80004182:	f05a                	sd	s6,32(sp)
    80004184:	ec5e                	sd	s7,24(sp)
    80004186:	e862                	sd	s8,16(sp)
    80004188:	e466                	sd	s9,8(sp)
    8000418a:	1080                	addi	s0,sp,96
    8000418c:	84aa                	mv	s1,a0
    8000418e:	8aae                	mv	s5,a1
    80004190:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004192:	00054703          	lbu	a4,0(a0)
    80004196:	02f00793          	li	a5,47
    8000419a:	02f70363          	beq	a4,a5,800041c0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000419e:	ffffe097          	auipc	ra,0xffffe
    800041a2:	d8a080e7          	jalr	-630(ra) # 80001f28 <myproc>
    800041a6:	15053503          	ld	a0,336(a0)
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	9f6080e7          	jalr	-1546(ra) # 80003ba0 <idup>
    800041b2:	89aa                	mv	s3,a0
  while(*path == '/')
    800041b4:	02f00913          	li	s2,47
  len = path - s;
    800041b8:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800041ba:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041bc:	4b85                	li	s7,1
    800041be:	a865                	j	80004276 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800041c0:	4585                	li	a1,1
    800041c2:	4505                	li	a0,1
    800041c4:	fffff097          	auipc	ra,0xfffff
    800041c8:	6e2080e7          	jalr	1762(ra) # 800038a6 <iget>
    800041cc:	89aa                	mv	s3,a0
    800041ce:	b7dd                	j	800041b4 <namex+0x42>
      iunlockput(ip);
    800041d0:	854e                	mv	a0,s3
    800041d2:	00000097          	auipc	ra,0x0
    800041d6:	c6e080e7          	jalr	-914(ra) # 80003e40 <iunlockput>
      return 0;
    800041da:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041dc:	854e                	mv	a0,s3
    800041de:	60e6                	ld	ra,88(sp)
    800041e0:	6446                	ld	s0,80(sp)
    800041e2:	64a6                	ld	s1,72(sp)
    800041e4:	6906                	ld	s2,64(sp)
    800041e6:	79e2                	ld	s3,56(sp)
    800041e8:	7a42                	ld	s4,48(sp)
    800041ea:	7aa2                	ld	s5,40(sp)
    800041ec:	7b02                	ld	s6,32(sp)
    800041ee:	6be2                	ld	s7,24(sp)
    800041f0:	6c42                	ld	s8,16(sp)
    800041f2:	6ca2                	ld	s9,8(sp)
    800041f4:	6125                	addi	sp,sp,96
    800041f6:	8082                	ret
      iunlock(ip);
    800041f8:	854e                	mv	a0,s3
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	aa6080e7          	jalr	-1370(ra) # 80003ca0 <iunlock>
      return ip;
    80004202:	bfe9                	j	800041dc <namex+0x6a>
      iunlockput(ip);
    80004204:	854e                	mv	a0,s3
    80004206:	00000097          	auipc	ra,0x0
    8000420a:	c3a080e7          	jalr	-966(ra) # 80003e40 <iunlockput>
      return 0;
    8000420e:	89e6                	mv	s3,s9
    80004210:	b7f1                	j	800041dc <namex+0x6a>
  len = path - s;
    80004212:	40b48633          	sub	a2,s1,a1
    80004216:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000421a:	099c5463          	bge	s8,s9,800042a2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000421e:	4639                	li	a2,14
    80004220:	8552                	mv	a0,s4
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	b0c080e7          	jalr	-1268(ra) # 80000d2e <memmove>
  while(*path == '/')
    8000422a:	0004c783          	lbu	a5,0(s1)
    8000422e:	01279763          	bne	a5,s2,8000423c <namex+0xca>
    path++;
    80004232:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004234:	0004c783          	lbu	a5,0(s1)
    80004238:	ff278de3          	beq	a5,s2,80004232 <namex+0xc0>
    ilock(ip);
    8000423c:	854e                	mv	a0,s3
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	9a0080e7          	jalr	-1632(ra) # 80003bde <ilock>
    if(ip->type != T_DIR){
    80004246:	04499783          	lh	a5,68(s3)
    8000424a:	f97793e3          	bne	a5,s7,800041d0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000424e:	000a8563          	beqz	s5,80004258 <namex+0xe6>
    80004252:	0004c783          	lbu	a5,0(s1)
    80004256:	d3cd                	beqz	a5,800041f8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004258:	865a                	mv	a2,s6
    8000425a:	85d2                	mv	a1,s4
    8000425c:	854e                	mv	a0,s3
    8000425e:	00000097          	auipc	ra,0x0
    80004262:	e64080e7          	jalr	-412(ra) # 800040c2 <dirlookup>
    80004266:	8caa                	mv	s9,a0
    80004268:	dd51                	beqz	a0,80004204 <namex+0x92>
    iunlockput(ip);
    8000426a:	854e                	mv	a0,s3
    8000426c:	00000097          	auipc	ra,0x0
    80004270:	bd4080e7          	jalr	-1068(ra) # 80003e40 <iunlockput>
    ip = next;
    80004274:	89e6                	mv	s3,s9
  while(*path == '/')
    80004276:	0004c783          	lbu	a5,0(s1)
    8000427a:	05279763          	bne	a5,s2,800042c8 <namex+0x156>
    path++;
    8000427e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004280:	0004c783          	lbu	a5,0(s1)
    80004284:	ff278de3          	beq	a5,s2,8000427e <namex+0x10c>
  if(*path == 0)
    80004288:	c79d                	beqz	a5,800042b6 <namex+0x144>
    path++;
    8000428a:	85a6                	mv	a1,s1
  len = path - s;
    8000428c:	8cda                	mv	s9,s6
    8000428e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004290:	01278963          	beq	a5,s2,800042a2 <namex+0x130>
    80004294:	dfbd                	beqz	a5,80004212 <namex+0xa0>
    path++;
    80004296:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004298:	0004c783          	lbu	a5,0(s1)
    8000429c:	ff279ce3          	bne	a5,s2,80004294 <namex+0x122>
    800042a0:	bf8d                	j	80004212 <namex+0xa0>
    memmove(name, s, len);
    800042a2:	2601                	sext.w	a2,a2
    800042a4:	8552                	mv	a0,s4
    800042a6:	ffffd097          	auipc	ra,0xffffd
    800042aa:	a88080e7          	jalr	-1400(ra) # 80000d2e <memmove>
    name[len] = 0;
    800042ae:	9cd2                	add	s9,s9,s4
    800042b0:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800042b4:	bf9d                	j	8000422a <namex+0xb8>
  if(nameiparent){
    800042b6:	f20a83e3          	beqz	s5,800041dc <namex+0x6a>
    iput(ip);
    800042ba:	854e                	mv	a0,s3
    800042bc:	00000097          	auipc	ra,0x0
    800042c0:	adc080e7          	jalr	-1316(ra) # 80003d98 <iput>
    return 0;
    800042c4:	4981                	li	s3,0
    800042c6:	bf19                	j	800041dc <namex+0x6a>
  if(*path == 0)
    800042c8:	d7fd                	beqz	a5,800042b6 <namex+0x144>
  while(*path != '/' && *path != 0)
    800042ca:	0004c783          	lbu	a5,0(s1)
    800042ce:	85a6                	mv	a1,s1
    800042d0:	b7d1                	j	80004294 <namex+0x122>

00000000800042d2 <dirlink>:
{
    800042d2:	7139                	addi	sp,sp,-64
    800042d4:	fc06                	sd	ra,56(sp)
    800042d6:	f822                	sd	s0,48(sp)
    800042d8:	f426                	sd	s1,40(sp)
    800042da:	f04a                	sd	s2,32(sp)
    800042dc:	ec4e                	sd	s3,24(sp)
    800042de:	e852                	sd	s4,16(sp)
    800042e0:	0080                	addi	s0,sp,64
    800042e2:	892a                	mv	s2,a0
    800042e4:	8a2e                	mv	s4,a1
    800042e6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042e8:	4601                	li	a2,0
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	dd8080e7          	jalr	-552(ra) # 800040c2 <dirlookup>
    800042f2:	e93d                	bnez	a0,80004368 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042f4:	04c92483          	lw	s1,76(s2)
    800042f8:	c49d                	beqz	s1,80004326 <dirlink+0x54>
    800042fa:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042fc:	4741                	li	a4,16
    800042fe:	86a6                	mv	a3,s1
    80004300:	fc040613          	addi	a2,s0,-64
    80004304:	4581                	li	a1,0
    80004306:	854a                	mv	a0,s2
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	b8a080e7          	jalr	-1142(ra) # 80003e92 <readi>
    80004310:	47c1                	li	a5,16
    80004312:	06f51163          	bne	a0,a5,80004374 <dirlink+0xa2>
    if(de.inum == 0)
    80004316:	fc045783          	lhu	a5,-64(s0)
    8000431a:	c791                	beqz	a5,80004326 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000431c:	24c1                	addiw	s1,s1,16
    8000431e:	04c92783          	lw	a5,76(s2)
    80004322:	fcf4ede3          	bltu	s1,a5,800042fc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004326:	4639                	li	a2,14
    80004328:	85d2                	mv	a1,s4
    8000432a:	fc240513          	addi	a0,s0,-62
    8000432e:	ffffd097          	auipc	ra,0xffffd
    80004332:	ab0080e7          	jalr	-1360(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004336:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000433a:	4741                	li	a4,16
    8000433c:	86a6                	mv	a3,s1
    8000433e:	fc040613          	addi	a2,s0,-64
    80004342:	4581                	li	a1,0
    80004344:	854a                	mv	a0,s2
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	c44080e7          	jalr	-956(ra) # 80003f8a <writei>
    8000434e:	1541                	addi	a0,a0,-16
    80004350:	00a03533          	snez	a0,a0
    80004354:	40a00533          	neg	a0,a0
}
    80004358:	70e2                	ld	ra,56(sp)
    8000435a:	7442                	ld	s0,48(sp)
    8000435c:	74a2                	ld	s1,40(sp)
    8000435e:	7902                	ld	s2,32(sp)
    80004360:	69e2                	ld	s3,24(sp)
    80004362:	6a42                	ld	s4,16(sp)
    80004364:	6121                	addi	sp,sp,64
    80004366:	8082                	ret
    iput(ip);
    80004368:	00000097          	auipc	ra,0x0
    8000436c:	a30080e7          	jalr	-1488(ra) # 80003d98 <iput>
    return -1;
    80004370:	557d                	li	a0,-1
    80004372:	b7dd                	j	80004358 <dirlink+0x86>
      panic("dirlink read");
    80004374:	00004517          	auipc	a0,0x4
    80004378:	2e450513          	addi	a0,a0,740 # 80008658 <syscalls+0x1c8>
    8000437c:	ffffc097          	auipc	ra,0xffffc
    80004380:	1c2080e7          	jalr	450(ra) # 8000053e <panic>

0000000080004384 <namei>:

struct inode*
namei(char *path)
{
    80004384:	1101                	addi	sp,sp,-32
    80004386:	ec06                	sd	ra,24(sp)
    80004388:	e822                	sd	s0,16(sp)
    8000438a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000438c:	fe040613          	addi	a2,s0,-32
    80004390:	4581                	li	a1,0
    80004392:	00000097          	auipc	ra,0x0
    80004396:	de0080e7          	jalr	-544(ra) # 80004172 <namex>
}
    8000439a:	60e2                	ld	ra,24(sp)
    8000439c:	6442                	ld	s0,16(sp)
    8000439e:	6105                	addi	sp,sp,32
    800043a0:	8082                	ret

00000000800043a2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043a2:	1141                	addi	sp,sp,-16
    800043a4:	e406                	sd	ra,8(sp)
    800043a6:	e022                	sd	s0,0(sp)
    800043a8:	0800                	addi	s0,sp,16
    800043aa:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043ac:	4585                	li	a1,1
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	dc4080e7          	jalr	-572(ra) # 80004172 <namex>
}
    800043b6:	60a2                	ld	ra,8(sp)
    800043b8:	6402                	ld	s0,0(sp)
    800043ba:	0141                	addi	sp,sp,16
    800043bc:	8082                	ret

00000000800043be <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    800043be:	1101                	addi	sp,sp,-32
    800043c0:	ec22                	sd	s0,24(sp)
    800043c2:	1000                	addi	s0,sp,32
    800043c4:	872a                	mv	a4,a0
    800043c6:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800043c8:	00004797          	auipc	a5,0x4
    800043cc:	2a078793          	addi	a5,a5,672 # 80008668 <syscalls+0x1d8>
    800043d0:	6394                	ld	a3,0(a5)
    800043d2:	fed43023          	sd	a3,-32(s0)
    800043d6:	0087d683          	lhu	a3,8(a5)
    800043da:	fed41423          	sh	a3,-24(s0)
    800043de:	00a7c783          	lbu	a5,10(a5)
    800043e2:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800043e6:	87ae                	mv	a5,a1
    if(i<0){
    800043e8:	02074b63          	bltz	a4,8000441e <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    800043ec:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    800043ee:	4629                	li	a2,10
        ++p;
    800043f0:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    800043f2:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    800043f6:	feed                	bnez	a3,800043f0 <itoa+0x32>
    *p = '\0';
    800043f8:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    800043fc:	4629                	li	a2,10
    800043fe:	17fd                	addi	a5,a5,-1
    80004400:	02c766bb          	remw	a3,a4,a2
    80004404:	ff040593          	addi	a1,s0,-16
    80004408:	96ae                	add	a3,a3,a1
    8000440a:	ff06c683          	lbu	a3,-16(a3)
    8000440e:	00d78023          	sb	a3,0(a5)
        i = i/10;
    80004412:	02c7473b          	divw	a4,a4,a2
    }while(i);
    80004416:	f765                	bnez	a4,800043fe <itoa+0x40>
    return b;
}
    80004418:	6462                	ld	s0,24(sp)
    8000441a:	6105                	addi	sp,sp,32
    8000441c:	8082                	ret
        *p++ = '-';
    8000441e:	00158793          	addi	a5,a1,1
    80004422:	02d00693          	li	a3,45
    80004426:	00d58023          	sb	a3,0(a1)
        i *= -1;
    8000442a:	40e0073b          	negw	a4,a4
    8000442e:	bf7d                	j	800043ec <itoa+0x2e>

0000000080004430 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    80004430:	711d                	addi	sp,sp,-96
    80004432:	ec86                	sd	ra,88(sp)
    80004434:	e8a2                	sd	s0,80(sp)
    80004436:	e4a6                	sd	s1,72(sp)
    80004438:	e0ca                	sd	s2,64(sp)
    8000443a:	1080                	addi	s0,sp,96
    8000443c:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    8000443e:	4619                	li	a2,6
    80004440:	00004597          	auipc	a1,0x4
    80004444:	23858593          	addi	a1,a1,568 # 80008678 <syscalls+0x1e8>
    80004448:	fd040513          	addi	a0,s0,-48
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	8e2080e7          	jalr	-1822(ra) # 80000d2e <memmove>
  itoa(p->pid, path+ 6);
    80004454:	fd640593          	addi	a1,s0,-42
    80004458:	5888                	lw	a0,48(s1)
    8000445a:	00000097          	auipc	ra,0x0
    8000445e:	f64080e7          	jalr	-156(ra) # 800043be <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004462:	1684b503          	ld	a0,360(s1)
    80004466:	16050763          	beqz	a0,800045d4 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    8000446a:	00001097          	auipc	ra,0x1
    8000446e:	914080e7          	jalr	-1772(ra) # 80004d7e <fileclose>

  begin_op();
    80004472:	00000097          	auipc	ra,0x0
    80004476:	440080e7          	jalr	1088(ra) # 800048b2 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    8000447a:	fb040593          	addi	a1,s0,-80
    8000447e:	fd040513          	addi	a0,s0,-48
    80004482:	00000097          	auipc	ra,0x0
    80004486:	f20080e7          	jalr	-224(ra) # 800043a2 <nameiparent>
    8000448a:	892a                	mv	s2,a0
    8000448c:	cd69                	beqz	a0,80004566 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    8000448e:	fffff097          	auipc	ra,0xfffff
    80004492:	750080e7          	jalr	1872(ra) # 80003bde <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004496:	00004597          	auipc	a1,0x4
    8000449a:	1ea58593          	addi	a1,a1,490 # 80008680 <syscalls+0x1f0>
    8000449e:	fb040513          	addi	a0,s0,-80
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	c06080e7          	jalr	-1018(ra) # 800040a8 <namecmp>
    800044aa:	c57d                	beqz	a0,80004598 <removeSwapFile+0x168>
    800044ac:	00004597          	auipc	a1,0x4
    800044b0:	1dc58593          	addi	a1,a1,476 # 80008688 <syscalls+0x1f8>
    800044b4:	fb040513          	addi	a0,s0,-80
    800044b8:	00000097          	auipc	ra,0x0
    800044bc:	bf0080e7          	jalr	-1040(ra) # 800040a8 <namecmp>
    800044c0:	cd61                	beqz	a0,80004598 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800044c2:	fac40613          	addi	a2,s0,-84
    800044c6:	fb040593          	addi	a1,s0,-80
    800044ca:	854a                	mv	a0,s2
    800044cc:	00000097          	auipc	ra,0x0
    800044d0:	bf6080e7          	jalr	-1034(ra) # 800040c2 <dirlookup>
    800044d4:	84aa                	mv	s1,a0
    800044d6:	c169                	beqz	a0,80004598 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800044d8:	fffff097          	auipc	ra,0xfffff
    800044dc:	706080e7          	jalr	1798(ra) # 80003bde <ilock>

  if(ip->nlink < 1)
    800044e0:	04a49783          	lh	a5,74(s1)
    800044e4:	08f05763          	blez	a5,80004572 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800044e8:	04449703          	lh	a4,68(s1)
    800044ec:	4785                	li	a5,1
    800044ee:	08f70a63          	beq	a4,a5,80004582 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800044f2:	4641                	li	a2,16
    800044f4:	4581                	li	a1,0
    800044f6:	fc040513          	addi	a0,s0,-64
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	7d8080e7          	jalr	2008(ra) # 80000cd2 <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004502:	4741                	li	a4,16
    80004504:	fac42683          	lw	a3,-84(s0)
    80004508:	fc040613          	addi	a2,s0,-64
    8000450c:	4581                	li	a1,0
    8000450e:	854a                	mv	a0,s2
    80004510:	00000097          	auipc	ra,0x0
    80004514:	a7a080e7          	jalr	-1414(ra) # 80003f8a <writei>
    80004518:	47c1                	li	a5,16
    8000451a:	08f51a63          	bne	a0,a5,800045ae <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    8000451e:	04449703          	lh	a4,68(s1)
    80004522:	4785                	li	a5,1
    80004524:	08f70d63          	beq	a4,a5,800045be <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004528:	854a                	mv	a0,s2
    8000452a:	00000097          	auipc	ra,0x0
    8000452e:	916080e7          	jalr	-1770(ra) # 80003e40 <iunlockput>

  ip->nlink--;
    80004532:	04a4d783          	lhu	a5,74(s1)
    80004536:	37fd                	addiw	a5,a5,-1
    80004538:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000453c:	8526                	mv	a0,s1
    8000453e:	fffff097          	auipc	ra,0xfffff
    80004542:	5d6080e7          	jalr	1494(ra) # 80003b14 <iupdate>
  iunlockput(ip);
    80004546:	8526                	mv	a0,s1
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	8f8080e7          	jalr	-1800(ra) # 80003e40 <iunlockput>

  end_op();
    80004550:	00000097          	auipc	ra,0x0
    80004554:	3e2080e7          	jalr	994(ra) # 80004932 <end_op>

  return 0;
    80004558:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    8000455a:	60e6                	ld	ra,88(sp)
    8000455c:	6446                	ld	s0,80(sp)
    8000455e:	64a6                	ld	s1,72(sp)
    80004560:	6906                	ld	s2,64(sp)
    80004562:	6125                	addi	sp,sp,96
    80004564:	8082                	ret
    end_op();
    80004566:	00000097          	auipc	ra,0x0
    8000456a:	3cc080e7          	jalr	972(ra) # 80004932 <end_op>
    return -1;
    8000456e:	557d                	li	a0,-1
    80004570:	b7ed                	j	8000455a <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004572:	00004517          	auipc	a0,0x4
    80004576:	11e50513          	addi	a0,a0,286 # 80008690 <syscalls+0x200>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	fc4080e7          	jalr	-60(ra) # 8000053e <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004582:	8526                	mv	a0,s1
    80004584:	00001097          	auipc	ra,0x1
    80004588:	7a8080e7          	jalr	1960(ra) # 80005d2c <isdirempty>
    8000458c:	f13d                	bnez	a0,800044f2 <removeSwapFile+0xc2>
    iunlockput(ip);
    8000458e:	8526                	mv	a0,s1
    80004590:	00000097          	auipc	ra,0x0
    80004594:	8b0080e7          	jalr	-1872(ra) # 80003e40 <iunlockput>
    iunlockput(dp);
    80004598:	854a                	mv	a0,s2
    8000459a:	00000097          	auipc	ra,0x0
    8000459e:	8a6080e7          	jalr	-1882(ra) # 80003e40 <iunlockput>
    end_op();
    800045a2:	00000097          	auipc	ra,0x0
    800045a6:	390080e7          	jalr	912(ra) # 80004932 <end_op>
    return -1;
    800045aa:	557d                	li	a0,-1
    800045ac:	b77d                	j	8000455a <removeSwapFile+0x12a>
    panic("unlink: writei");
    800045ae:	00004517          	auipc	a0,0x4
    800045b2:	0fa50513          	addi	a0,a0,250 # 800086a8 <syscalls+0x218>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	f88080e7          	jalr	-120(ra) # 8000053e <panic>
    dp->nlink--;
    800045be:	04a95783          	lhu	a5,74(s2)
    800045c2:	37fd                	addiw	a5,a5,-1
    800045c4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800045c8:	854a                	mv	a0,s2
    800045ca:	fffff097          	auipc	ra,0xfffff
    800045ce:	54a080e7          	jalr	1354(ra) # 80003b14 <iupdate>
    800045d2:	bf99                	j	80004528 <removeSwapFile+0xf8>
    return -1;
    800045d4:	557d                	li	a0,-1
    800045d6:	b751                	j	8000455a <removeSwapFile+0x12a>

00000000800045d8 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    800045d8:	7179                	addi	sp,sp,-48
    800045da:	f406                	sd	ra,40(sp)
    800045dc:	f022                	sd	s0,32(sp)
    800045de:	ec26                	sd	s1,24(sp)
    800045e0:	e84a                	sd	s2,16(sp)
    800045e2:	1800                	addi	s0,sp,48
    800045e4:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800045e6:	4619                	li	a2,6
    800045e8:	00004597          	auipc	a1,0x4
    800045ec:	09058593          	addi	a1,a1,144 # 80008678 <syscalls+0x1e8>
    800045f0:	fd040513          	addi	a0,s0,-48
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	73a080e7          	jalr	1850(ra) # 80000d2e <memmove>
  itoa(p->pid, path+ 6);
    800045fc:	fd640593          	addi	a1,s0,-42
    80004600:	5888                	lw	a0,48(s1)
    80004602:	00000097          	auipc	ra,0x0
    80004606:	dbc080e7          	jalr	-580(ra) # 800043be <itoa>

  begin_op();
    8000460a:	00000097          	auipc	ra,0x0
    8000460e:	2a8080e7          	jalr	680(ra) # 800048b2 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004612:	4681                	li	a3,0
    80004614:	4601                	li	a2,0
    80004616:	4589                	li	a1,2
    80004618:	fd040513          	addi	a0,s0,-48
    8000461c:	00002097          	auipc	ra,0x2
    80004620:	904080e7          	jalr	-1788(ra) # 80005f20 <create>
    80004624:	892a                	mv	s2,a0
  iunlock(in);
    80004626:	fffff097          	auipc	ra,0xfffff
    8000462a:	67a080e7          	jalr	1658(ra) # 80003ca0 <iunlock>
  p->swapFile = filealloc();
    8000462e:	00000097          	auipc	ra,0x0
    80004632:	694080e7          	jalr	1684(ra) # 80004cc2 <filealloc>
    80004636:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    8000463a:	cd1d                	beqz	a0,80004678 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    8000463c:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004640:	1684b703          	ld	a4,360(s1)
    80004644:	4789                	li	a5,2
    80004646:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004648:	1684b703          	ld	a4,360(s1)
    8000464c:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004650:	1684b703          	ld	a4,360(s1)
    80004654:	4685                	li	a3,1
    80004656:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    8000465a:	1684b703          	ld	a4,360(s1)
    8000465e:	00f704a3          	sb	a5,9(a4)
    end_op();
    80004662:	00000097          	auipc	ra,0x0
    80004666:	2d0080e7          	jalr	720(ra) # 80004932 <end_op>

    return 0;
}
    8000466a:	4501                	li	a0,0
    8000466c:	70a2                	ld	ra,40(sp)
    8000466e:	7402                	ld	s0,32(sp)
    80004670:	64e2                	ld	s1,24(sp)
    80004672:	6942                	ld	s2,16(sp)
    80004674:	6145                	addi	sp,sp,48
    80004676:	8082                	ret
    panic("no slot for files on /store");
    80004678:	00004517          	auipc	a0,0x4
    8000467c:	04050513          	addi	a0,a0,64 # 800086b8 <syscalls+0x228>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	ebe080e7          	jalr	-322(ra) # 8000053e <panic>

0000000080004688 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004688:	1141                	addi	sp,sp,-16
    8000468a:	e406                	sd	ra,8(sp)
    8000468c:	e022                	sd	s0,0(sp)
    8000468e:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004690:	16853783          	ld	a5,360(a0)
    80004694:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004696:	8636                	mv	a2,a3
    80004698:	16853503          	ld	a0,360(a0)
    8000469c:	00001097          	auipc	ra,0x1
    800046a0:	ad4080e7          	jalr	-1324(ra) # 80005170 <kfilewrite>
}
    800046a4:	60a2                	ld	ra,8(sp)
    800046a6:	6402                	ld	s0,0(sp)
    800046a8:	0141                	addi	sp,sp,16
    800046aa:	8082                	ret

00000000800046ac <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    800046ac:	1141                	addi	sp,sp,-16
    800046ae:	e406                	sd	ra,8(sp)
    800046b0:	e022                	sd	s0,0(sp)
    800046b2:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800046b4:	16853783          	ld	a5,360(a0)
    800046b8:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    800046ba:	8636                	mv	a2,a3
    800046bc:	16853503          	ld	a0,360(a0)
    800046c0:	00001097          	auipc	ra,0x1
    800046c4:	9ee080e7          	jalr	-1554(ra) # 800050ae <kfileread>
    800046c8:	60a2                	ld	ra,8(sp)
    800046ca:	6402                	ld	s0,0(sp)
    800046cc:	0141                	addi	sp,sp,16
    800046ce:	8082                	ret

00000000800046d0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046d0:	1101                	addi	sp,sp,-32
    800046d2:	ec06                	sd	ra,24(sp)
    800046d4:	e822                	sd	s0,16(sp)
    800046d6:	e426                	sd	s1,8(sp)
    800046d8:	e04a                	sd	s2,0(sp)
    800046da:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800046dc:	0002d917          	auipc	s2,0x2d
    800046e0:	ac490913          	addi	s2,s2,-1340 # 800311a0 <log>
    800046e4:	01892583          	lw	a1,24(s2)
    800046e8:	02892503          	lw	a0,40(s2)
    800046ec:	fffff097          	auipc	ra,0xfffff
    800046f0:	cd8080e7          	jalr	-808(ra) # 800033c4 <bread>
    800046f4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800046f6:	02c92683          	lw	a3,44(s2)
    800046fa:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800046fc:	02d05763          	blez	a3,8000472a <write_head+0x5a>
    80004700:	0002d797          	auipc	a5,0x2d
    80004704:	ad078793          	addi	a5,a5,-1328 # 800311d0 <log+0x30>
    80004708:	05c50713          	addi	a4,a0,92
    8000470c:	36fd                	addiw	a3,a3,-1
    8000470e:	1682                	slli	a3,a3,0x20
    80004710:	9281                	srli	a3,a3,0x20
    80004712:	068a                	slli	a3,a3,0x2
    80004714:	0002d617          	auipc	a2,0x2d
    80004718:	ac060613          	addi	a2,a2,-1344 # 800311d4 <log+0x34>
    8000471c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000471e:	4390                	lw	a2,0(a5)
    80004720:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004722:	0791                	addi	a5,a5,4
    80004724:	0711                	addi	a4,a4,4
    80004726:	fed79ce3          	bne	a5,a3,8000471e <write_head+0x4e>
  }
  bwrite(buf);
    8000472a:	8526                	mv	a0,s1
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	d8a080e7          	jalr	-630(ra) # 800034b6 <bwrite>
  brelse(buf);
    80004734:	8526                	mv	a0,s1
    80004736:	fffff097          	auipc	ra,0xfffff
    8000473a:	dbe080e7          	jalr	-578(ra) # 800034f4 <brelse>
}
    8000473e:	60e2                	ld	ra,24(sp)
    80004740:	6442                	ld	s0,16(sp)
    80004742:	64a2                	ld	s1,8(sp)
    80004744:	6902                	ld	s2,0(sp)
    80004746:	6105                	addi	sp,sp,32
    80004748:	8082                	ret

000000008000474a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000474a:	0002d797          	auipc	a5,0x2d
    8000474e:	a827a783          	lw	a5,-1406(a5) # 800311cc <log+0x2c>
    80004752:	0af05d63          	blez	a5,8000480c <install_trans+0xc2>
{
    80004756:	7139                	addi	sp,sp,-64
    80004758:	fc06                	sd	ra,56(sp)
    8000475a:	f822                	sd	s0,48(sp)
    8000475c:	f426                	sd	s1,40(sp)
    8000475e:	f04a                	sd	s2,32(sp)
    80004760:	ec4e                	sd	s3,24(sp)
    80004762:	e852                	sd	s4,16(sp)
    80004764:	e456                	sd	s5,8(sp)
    80004766:	e05a                	sd	s6,0(sp)
    80004768:	0080                	addi	s0,sp,64
    8000476a:	8b2a                	mv	s6,a0
    8000476c:	0002da97          	auipc	s5,0x2d
    80004770:	a64a8a93          	addi	s5,s5,-1436 # 800311d0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004774:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004776:	0002d997          	auipc	s3,0x2d
    8000477a:	a2a98993          	addi	s3,s3,-1494 # 800311a0 <log>
    8000477e:	a00d                	j	800047a0 <install_trans+0x56>
    brelse(lbuf);
    80004780:	854a                	mv	a0,s2
    80004782:	fffff097          	auipc	ra,0xfffff
    80004786:	d72080e7          	jalr	-654(ra) # 800034f4 <brelse>
    brelse(dbuf);
    8000478a:	8526                	mv	a0,s1
    8000478c:	fffff097          	auipc	ra,0xfffff
    80004790:	d68080e7          	jalr	-664(ra) # 800034f4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004794:	2a05                	addiw	s4,s4,1
    80004796:	0a91                	addi	s5,s5,4
    80004798:	02c9a783          	lw	a5,44(s3)
    8000479c:	04fa5e63          	bge	s4,a5,800047f8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047a0:	0189a583          	lw	a1,24(s3)
    800047a4:	014585bb          	addw	a1,a1,s4
    800047a8:	2585                	addiw	a1,a1,1
    800047aa:	0289a503          	lw	a0,40(s3)
    800047ae:	fffff097          	auipc	ra,0xfffff
    800047b2:	c16080e7          	jalr	-1002(ra) # 800033c4 <bread>
    800047b6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800047b8:	000aa583          	lw	a1,0(s5)
    800047bc:	0289a503          	lw	a0,40(s3)
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	c04080e7          	jalr	-1020(ra) # 800033c4 <bread>
    800047c8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800047ca:	40000613          	li	a2,1024
    800047ce:	05890593          	addi	a1,s2,88
    800047d2:	05850513          	addi	a0,a0,88
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	558080e7          	jalr	1368(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800047de:	8526                	mv	a0,s1
    800047e0:	fffff097          	auipc	ra,0xfffff
    800047e4:	cd6080e7          	jalr	-810(ra) # 800034b6 <bwrite>
    if(recovering == 0)
    800047e8:	f80b1ce3          	bnez	s6,80004780 <install_trans+0x36>
      bunpin(dbuf);
    800047ec:	8526                	mv	a0,s1
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	de0080e7          	jalr	-544(ra) # 800035ce <bunpin>
    800047f6:	b769                	j	80004780 <install_trans+0x36>
}
    800047f8:	70e2                	ld	ra,56(sp)
    800047fa:	7442                	ld	s0,48(sp)
    800047fc:	74a2                	ld	s1,40(sp)
    800047fe:	7902                	ld	s2,32(sp)
    80004800:	69e2                	ld	s3,24(sp)
    80004802:	6a42                	ld	s4,16(sp)
    80004804:	6aa2                	ld	s5,8(sp)
    80004806:	6b02                	ld	s6,0(sp)
    80004808:	6121                	addi	sp,sp,64
    8000480a:	8082                	ret
    8000480c:	8082                	ret

000000008000480e <initlog>:
{
    8000480e:	7179                	addi	sp,sp,-48
    80004810:	f406                	sd	ra,40(sp)
    80004812:	f022                	sd	s0,32(sp)
    80004814:	ec26                	sd	s1,24(sp)
    80004816:	e84a                	sd	s2,16(sp)
    80004818:	e44e                	sd	s3,8(sp)
    8000481a:	1800                	addi	s0,sp,48
    8000481c:	892a                	mv	s2,a0
    8000481e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004820:	0002d497          	auipc	s1,0x2d
    80004824:	98048493          	addi	s1,s1,-1664 # 800311a0 <log>
    80004828:	00004597          	auipc	a1,0x4
    8000482c:	eb058593          	addi	a1,a1,-336 # 800086d8 <syscalls+0x248>
    80004830:	8526                	mv	a0,s1
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	314080e7          	jalr	788(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000483a:	0149a583          	lw	a1,20(s3)
    8000483e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004840:	0109a783          	lw	a5,16(s3)
    80004844:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004846:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000484a:	854a                	mv	a0,s2
    8000484c:	fffff097          	auipc	ra,0xfffff
    80004850:	b78080e7          	jalr	-1160(ra) # 800033c4 <bread>
  log.lh.n = lh->n;
    80004854:	4d34                	lw	a3,88(a0)
    80004856:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004858:	02d05563          	blez	a3,80004882 <initlog+0x74>
    8000485c:	05c50793          	addi	a5,a0,92
    80004860:	0002d717          	auipc	a4,0x2d
    80004864:	97070713          	addi	a4,a4,-1680 # 800311d0 <log+0x30>
    80004868:	36fd                	addiw	a3,a3,-1
    8000486a:	1682                	slli	a3,a3,0x20
    8000486c:	9281                	srli	a3,a3,0x20
    8000486e:	068a                	slli	a3,a3,0x2
    80004870:	06050613          	addi	a2,a0,96
    80004874:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004876:	4390                	lw	a2,0(a5)
    80004878:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000487a:	0791                	addi	a5,a5,4
    8000487c:	0711                	addi	a4,a4,4
    8000487e:	fed79ce3          	bne	a5,a3,80004876 <initlog+0x68>
  brelse(buf);
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	c72080e7          	jalr	-910(ra) # 800034f4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000488a:	4505                	li	a0,1
    8000488c:	00000097          	auipc	ra,0x0
    80004890:	ebe080e7          	jalr	-322(ra) # 8000474a <install_trans>
  log.lh.n = 0;
    80004894:	0002d797          	auipc	a5,0x2d
    80004898:	9207ac23          	sw	zero,-1736(a5) # 800311cc <log+0x2c>
  write_head(); // clear the log
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	e34080e7          	jalr	-460(ra) # 800046d0 <write_head>
}
    800048a4:	70a2                	ld	ra,40(sp)
    800048a6:	7402                	ld	s0,32(sp)
    800048a8:	64e2                	ld	s1,24(sp)
    800048aa:	6942                	ld	s2,16(sp)
    800048ac:	69a2                	ld	s3,8(sp)
    800048ae:	6145                	addi	sp,sp,48
    800048b0:	8082                	ret

00000000800048b2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800048b2:	1101                	addi	sp,sp,-32
    800048b4:	ec06                	sd	ra,24(sp)
    800048b6:	e822                	sd	s0,16(sp)
    800048b8:	e426                	sd	s1,8(sp)
    800048ba:	e04a                	sd	s2,0(sp)
    800048bc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800048be:	0002d517          	auipc	a0,0x2d
    800048c2:	8e250513          	addi	a0,a0,-1822 # 800311a0 <log>
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	310080e7          	jalr	784(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800048ce:	0002d497          	auipc	s1,0x2d
    800048d2:	8d248493          	addi	s1,s1,-1838 # 800311a0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048d6:	4979                	li	s2,30
    800048d8:	a039                	j	800048e6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800048da:	85a6                	mv	a1,s1
    800048dc:	8526                	mv	a0,s1
    800048de:	ffffe097          	auipc	ra,0xffffe
    800048e2:	d12080e7          	jalr	-750(ra) # 800025f0 <sleep>
    if(log.committing){
    800048e6:	50dc                	lw	a5,36(s1)
    800048e8:	fbed                	bnez	a5,800048da <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048ea:	509c                	lw	a5,32(s1)
    800048ec:	0017871b          	addiw	a4,a5,1
    800048f0:	0007069b          	sext.w	a3,a4
    800048f4:	0027179b          	slliw	a5,a4,0x2
    800048f8:	9fb9                	addw	a5,a5,a4
    800048fa:	0017979b          	slliw	a5,a5,0x1
    800048fe:	54d8                	lw	a4,44(s1)
    80004900:	9fb9                	addw	a5,a5,a4
    80004902:	00f95963          	bge	s2,a5,80004914 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004906:	85a6                	mv	a1,s1
    80004908:	8526                	mv	a0,s1
    8000490a:	ffffe097          	auipc	ra,0xffffe
    8000490e:	ce6080e7          	jalr	-794(ra) # 800025f0 <sleep>
    80004912:	bfd1                	j	800048e6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004914:	0002d517          	auipc	a0,0x2d
    80004918:	88c50513          	addi	a0,a0,-1908 # 800311a0 <log>
    8000491c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	36c080e7          	jalr	876(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004926:	60e2                	ld	ra,24(sp)
    80004928:	6442                	ld	s0,16(sp)
    8000492a:	64a2                	ld	s1,8(sp)
    8000492c:	6902                	ld	s2,0(sp)
    8000492e:	6105                	addi	sp,sp,32
    80004930:	8082                	ret

0000000080004932 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004932:	7139                	addi	sp,sp,-64
    80004934:	fc06                	sd	ra,56(sp)
    80004936:	f822                	sd	s0,48(sp)
    80004938:	f426                	sd	s1,40(sp)
    8000493a:	f04a                	sd	s2,32(sp)
    8000493c:	ec4e                	sd	s3,24(sp)
    8000493e:	e852                	sd	s4,16(sp)
    80004940:	e456                	sd	s5,8(sp)
    80004942:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004944:	0002d497          	auipc	s1,0x2d
    80004948:	85c48493          	addi	s1,s1,-1956 # 800311a0 <log>
    8000494c:	8526                	mv	a0,s1
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	288080e7          	jalr	648(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004956:	509c                	lw	a5,32(s1)
    80004958:	37fd                	addiw	a5,a5,-1
    8000495a:	0007891b          	sext.w	s2,a5
    8000495e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004960:	50dc                	lw	a5,36(s1)
    80004962:	e7b9                	bnez	a5,800049b0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004964:	04091e63          	bnez	s2,800049c0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004968:	0002d497          	auipc	s1,0x2d
    8000496c:	83848493          	addi	s1,s1,-1992 # 800311a0 <log>
    80004970:	4785                	li	a5,1
    80004972:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004974:	8526                	mv	a0,s1
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	314080e7          	jalr	788(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000497e:	54dc                	lw	a5,44(s1)
    80004980:	06f04763          	bgtz	a5,800049ee <end_op+0xbc>
    acquire(&log.lock);
    80004984:	0002d497          	auipc	s1,0x2d
    80004988:	81c48493          	addi	s1,s1,-2020 # 800311a0 <log>
    8000498c:	8526                	mv	a0,s1
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	248080e7          	jalr	584(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004996:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000499a:	8526                	mv	a0,s1
    8000499c:	ffffe097          	auipc	ra,0xffffe
    800049a0:	cb8080e7          	jalr	-840(ra) # 80002654 <wakeup>
    release(&log.lock);
    800049a4:	8526                	mv	a0,s1
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	2e4080e7          	jalr	740(ra) # 80000c8a <release>
}
    800049ae:	a03d                	j	800049dc <end_op+0xaa>
    panic("log.committing");
    800049b0:	00004517          	auipc	a0,0x4
    800049b4:	d3050513          	addi	a0,a0,-720 # 800086e0 <syscalls+0x250>
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	b86080e7          	jalr	-1146(ra) # 8000053e <panic>
    wakeup(&log);
    800049c0:	0002c497          	auipc	s1,0x2c
    800049c4:	7e048493          	addi	s1,s1,2016 # 800311a0 <log>
    800049c8:	8526                	mv	a0,s1
    800049ca:	ffffe097          	auipc	ra,0xffffe
    800049ce:	c8a080e7          	jalr	-886(ra) # 80002654 <wakeup>
  release(&log.lock);
    800049d2:	8526                	mv	a0,s1
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	2b6080e7          	jalr	694(ra) # 80000c8a <release>
}
    800049dc:	70e2                	ld	ra,56(sp)
    800049de:	7442                	ld	s0,48(sp)
    800049e0:	74a2                	ld	s1,40(sp)
    800049e2:	7902                	ld	s2,32(sp)
    800049e4:	69e2                	ld	s3,24(sp)
    800049e6:	6a42                	ld	s4,16(sp)
    800049e8:	6aa2                	ld	s5,8(sp)
    800049ea:	6121                	addi	sp,sp,64
    800049ec:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800049ee:	0002ca97          	auipc	s5,0x2c
    800049f2:	7e2a8a93          	addi	s5,s5,2018 # 800311d0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800049f6:	0002ca17          	auipc	s4,0x2c
    800049fa:	7aaa0a13          	addi	s4,s4,1962 # 800311a0 <log>
    800049fe:	018a2583          	lw	a1,24(s4)
    80004a02:	012585bb          	addw	a1,a1,s2
    80004a06:	2585                	addiw	a1,a1,1
    80004a08:	028a2503          	lw	a0,40(s4)
    80004a0c:	fffff097          	auipc	ra,0xfffff
    80004a10:	9b8080e7          	jalr	-1608(ra) # 800033c4 <bread>
    80004a14:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a16:	000aa583          	lw	a1,0(s5)
    80004a1a:	028a2503          	lw	a0,40(s4)
    80004a1e:	fffff097          	auipc	ra,0xfffff
    80004a22:	9a6080e7          	jalr	-1626(ra) # 800033c4 <bread>
    80004a26:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a28:	40000613          	li	a2,1024
    80004a2c:	05850593          	addi	a1,a0,88
    80004a30:	05848513          	addi	a0,s1,88
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	2fa080e7          	jalr	762(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004a3c:	8526                	mv	a0,s1
    80004a3e:	fffff097          	auipc	ra,0xfffff
    80004a42:	a78080e7          	jalr	-1416(ra) # 800034b6 <bwrite>
    brelse(from);
    80004a46:	854e                	mv	a0,s3
    80004a48:	fffff097          	auipc	ra,0xfffff
    80004a4c:	aac080e7          	jalr	-1364(ra) # 800034f4 <brelse>
    brelse(to);
    80004a50:	8526                	mv	a0,s1
    80004a52:	fffff097          	auipc	ra,0xfffff
    80004a56:	aa2080e7          	jalr	-1374(ra) # 800034f4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a5a:	2905                	addiw	s2,s2,1
    80004a5c:	0a91                	addi	s5,s5,4
    80004a5e:	02ca2783          	lw	a5,44(s4)
    80004a62:	f8f94ee3          	blt	s2,a5,800049fe <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a66:	00000097          	auipc	ra,0x0
    80004a6a:	c6a080e7          	jalr	-918(ra) # 800046d0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004a6e:	4501                	li	a0,0
    80004a70:	00000097          	auipc	ra,0x0
    80004a74:	cda080e7          	jalr	-806(ra) # 8000474a <install_trans>
    log.lh.n = 0;
    80004a78:	0002c797          	auipc	a5,0x2c
    80004a7c:	7407aa23          	sw	zero,1876(a5) # 800311cc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a80:	00000097          	auipc	ra,0x0
    80004a84:	c50080e7          	jalr	-944(ra) # 800046d0 <write_head>
    80004a88:	bdf5                	j	80004984 <end_op+0x52>

0000000080004a8a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a8a:	1101                	addi	sp,sp,-32
    80004a8c:	ec06                	sd	ra,24(sp)
    80004a8e:	e822                	sd	s0,16(sp)
    80004a90:	e426                	sd	s1,8(sp)
    80004a92:	e04a                	sd	s2,0(sp)
    80004a94:	1000                	addi	s0,sp,32
    80004a96:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a98:	0002c917          	auipc	s2,0x2c
    80004a9c:	70890913          	addi	s2,s2,1800 # 800311a0 <log>
    80004aa0:	854a                	mv	a0,s2
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	134080e7          	jalr	308(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004aaa:	02c92603          	lw	a2,44(s2)
    80004aae:	47f5                	li	a5,29
    80004ab0:	06c7c563          	blt	a5,a2,80004b1a <log_write+0x90>
    80004ab4:	0002c797          	auipc	a5,0x2c
    80004ab8:	7087a783          	lw	a5,1800(a5) # 800311bc <log+0x1c>
    80004abc:	37fd                	addiw	a5,a5,-1
    80004abe:	04f65e63          	bge	a2,a5,80004b1a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ac2:	0002c797          	auipc	a5,0x2c
    80004ac6:	6fe7a783          	lw	a5,1790(a5) # 800311c0 <log+0x20>
    80004aca:	06f05063          	blez	a5,80004b2a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ace:	4781                	li	a5,0
    80004ad0:	06c05563          	blez	a2,80004b3a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ad4:	44cc                	lw	a1,12(s1)
    80004ad6:	0002c717          	auipc	a4,0x2c
    80004ada:	6fa70713          	addi	a4,a4,1786 # 800311d0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ade:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ae0:	4314                	lw	a3,0(a4)
    80004ae2:	04b68c63          	beq	a3,a1,80004b3a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004ae6:	2785                	addiw	a5,a5,1
    80004ae8:	0711                	addi	a4,a4,4
    80004aea:	fef61be3          	bne	a2,a5,80004ae0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004aee:	0621                	addi	a2,a2,8
    80004af0:	060a                	slli	a2,a2,0x2
    80004af2:	0002c797          	auipc	a5,0x2c
    80004af6:	6ae78793          	addi	a5,a5,1710 # 800311a0 <log>
    80004afa:	963e                	add	a2,a2,a5
    80004afc:	44dc                	lw	a5,12(s1)
    80004afe:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b00:	8526                	mv	a0,s1
    80004b02:	fffff097          	auipc	ra,0xfffff
    80004b06:	a90080e7          	jalr	-1392(ra) # 80003592 <bpin>
    log.lh.n++;
    80004b0a:	0002c717          	auipc	a4,0x2c
    80004b0e:	69670713          	addi	a4,a4,1686 # 800311a0 <log>
    80004b12:	575c                	lw	a5,44(a4)
    80004b14:	2785                	addiw	a5,a5,1
    80004b16:	d75c                	sw	a5,44(a4)
    80004b18:	a835                	j	80004b54 <log_write+0xca>
    panic("too big a transaction");
    80004b1a:	00004517          	auipc	a0,0x4
    80004b1e:	bd650513          	addi	a0,a0,-1066 # 800086f0 <syscalls+0x260>
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	a1c080e7          	jalr	-1508(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004b2a:	00004517          	auipc	a0,0x4
    80004b2e:	bde50513          	addi	a0,a0,-1058 # 80008708 <syscalls+0x278>
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	a0c080e7          	jalr	-1524(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004b3a:	00878713          	addi	a4,a5,8
    80004b3e:	00271693          	slli	a3,a4,0x2
    80004b42:	0002c717          	auipc	a4,0x2c
    80004b46:	65e70713          	addi	a4,a4,1630 # 800311a0 <log>
    80004b4a:	9736                	add	a4,a4,a3
    80004b4c:	44d4                	lw	a3,12(s1)
    80004b4e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b50:	faf608e3          	beq	a2,a5,80004b00 <log_write+0x76>
  }
  release(&log.lock);
    80004b54:	0002c517          	auipc	a0,0x2c
    80004b58:	64c50513          	addi	a0,a0,1612 # 800311a0 <log>
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	12e080e7          	jalr	302(ra) # 80000c8a <release>
}
    80004b64:	60e2                	ld	ra,24(sp)
    80004b66:	6442                	ld	s0,16(sp)
    80004b68:	64a2                	ld	s1,8(sp)
    80004b6a:	6902                	ld	s2,0(sp)
    80004b6c:	6105                	addi	sp,sp,32
    80004b6e:	8082                	ret

0000000080004b70 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b70:	1101                	addi	sp,sp,-32
    80004b72:	ec06                	sd	ra,24(sp)
    80004b74:	e822                	sd	s0,16(sp)
    80004b76:	e426                	sd	s1,8(sp)
    80004b78:	e04a                	sd	s2,0(sp)
    80004b7a:	1000                	addi	s0,sp,32
    80004b7c:	84aa                	mv	s1,a0
    80004b7e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b80:	00004597          	auipc	a1,0x4
    80004b84:	ba858593          	addi	a1,a1,-1112 # 80008728 <syscalls+0x298>
    80004b88:	0521                	addi	a0,a0,8
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	fbc080e7          	jalr	-68(ra) # 80000b46 <initlock>
  lk->name = name;
    80004b92:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b96:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b9a:	0204a423          	sw	zero,40(s1)
}
    80004b9e:	60e2                	ld	ra,24(sp)
    80004ba0:	6442                	ld	s0,16(sp)
    80004ba2:	64a2                	ld	s1,8(sp)
    80004ba4:	6902                	ld	s2,0(sp)
    80004ba6:	6105                	addi	sp,sp,32
    80004ba8:	8082                	ret

0000000080004baa <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004baa:	1101                	addi	sp,sp,-32
    80004bac:	ec06                	sd	ra,24(sp)
    80004bae:	e822                	sd	s0,16(sp)
    80004bb0:	e426                	sd	s1,8(sp)
    80004bb2:	e04a                	sd	s2,0(sp)
    80004bb4:	1000                	addi	s0,sp,32
    80004bb6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bb8:	00850913          	addi	s2,a0,8
    80004bbc:	854a                	mv	a0,s2
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	018080e7          	jalr	24(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004bc6:	409c                	lw	a5,0(s1)
    80004bc8:	cb89                	beqz	a5,80004bda <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004bca:	85ca                	mv	a1,s2
    80004bcc:	8526                	mv	a0,s1
    80004bce:	ffffe097          	auipc	ra,0xffffe
    80004bd2:	a22080e7          	jalr	-1502(ra) # 800025f0 <sleep>
  while (lk->locked) {
    80004bd6:	409c                	lw	a5,0(s1)
    80004bd8:	fbed                	bnez	a5,80004bca <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004bda:	4785                	li	a5,1
    80004bdc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	34a080e7          	jalr	842(ra) # 80001f28 <myproc>
    80004be6:	591c                	lw	a5,48(a0)
    80004be8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004bea:	854a                	mv	a0,s2
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	09e080e7          	jalr	158(ra) # 80000c8a <release>
}
    80004bf4:	60e2                	ld	ra,24(sp)
    80004bf6:	6442                	ld	s0,16(sp)
    80004bf8:	64a2                	ld	s1,8(sp)
    80004bfa:	6902                	ld	s2,0(sp)
    80004bfc:	6105                	addi	sp,sp,32
    80004bfe:	8082                	ret

0000000080004c00 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c00:	1101                	addi	sp,sp,-32
    80004c02:	ec06                	sd	ra,24(sp)
    80004c04:	e822                	sd	s0,16(sp)
    80004c06:	e426                	sd	s1,8(sp)
    80004c08:	e04a                	sd	s2,0(sp)
    80004c0a:	1000                	addi	s0,sp,32
    80004c0c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c0e:	00850913          	addi	s2,a0,8
    80004c12:	854a                	mv	a0,s2
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	fc2080e7          	jalr	-62(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004c1c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c20:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c24:	8526                	mv	a0,s1
    80004c26:	ffffe097          	auipc	ra,0xffffe
    80004c2a:	a2e080e7          	jalr	-1490(ra) # 80002654 <wakeup>
  release(&lk->lk);
    80004c2e:	854a                	mv	a0,s2
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	05a080e7          	jalr	90(ra) # 80000c8a <release>
}
    80004c38:	60e2                	ld	ra,24(sp)
    80004c3a:	6442                	ld	s0,16(sp)
    80004c3c:	64a2                	ld	s1,8(sp)
    80004c3e:	6902                	ld	s2,0(sp)
    80004c40:	6105                	addi	sp,sp,32
    80004c42:	8082                	ret

0000000080004c44 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c44:	7179                	addi	sp,sp,-48
    80004c46:	f406                	sd	ra,40(sp)
    80004c48:	f022                	sd	s0,32(sp)
    80004c4a:	ec26                	sd	s1,24(sp)
    80004c4c:	e84a                	sd	s2,16(sp)
    80004c4e:	e44e                	sd	s3,8(sp)
    80004c50:	1800                	addi	s0,sp,48
    80004c52:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c54:	00850913          	addi	s2,a0,8
    80004c58:	854a                	mv	a0,s2
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	f7c080e7          	jalr	-132(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c62:	409c                	lw	a5,0(s1)
    80004c64:	ef99                	bnez	a5,80004c82 <holdingsleep+0x3e>
    80004c66:	4481                	li	s1,0
  release(&lk->lk);
    80004c68:	854a                	mv	a0,s2
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	020080e7          	jalr	32(ra) # 80000c8a <release>
  return r;
}
    80004c72:	8526                	mv	a0,s1
    80004c74:	70a2                	ld	ra,40(sp)
    80004c76:	7402                	ld	s0,32(sp)
    80004c78:	64e2                	ld	s1,24(sp)
    80004c7a:	6942                	ld	s2,16(sp)
    80004c7c:	69a2                	ld	s3,8(sp)
    80004c7e:	6145                	addi	sp,sp,48
    80004c80:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c82:	0284a983          	lw	s3,40(s1)
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	2a2080e7          	jalr	674(ra) # 80001f28 <myproc>
    80004c8e:	5904                	lw	s1,48(a0)
    80004c90:	413484b3          	sub	s1,s1,s3
    80004c94:	0014b493          	seqz	s1,s1
    80004c98:	bfc1                	j	80004c68 <holdingsleep+0x24>

0000000080004c9a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c9a:	1141                	addi	sp,sp,-16
    80004c9c:	e406                	sd	ra,8(sp)
    80004c9e:	e022                	sd	s0,0(sp)
    80004ca0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ca2:	00004597          	auipc	a1,0x4
    80004ca6:	a9658593          	addi	a1,a1,-1386 # 80008738 <syscalls+0x2a8>
    80004caa:	0002c517          	auipc	a0,0x2c
    80004cae:	63e50513          	addi	a0,a0,1598 # 800312e8 <ftable>
    80004cb2:	ffffc097          	auipc	ra,0xffffc
    80004cb6:	e94080e7          	jalr	-364(ra) # 80000b46 <initlock>
}
    80004cba:	60a2                	ld	ra,8(sp)
    80004cbc:	6402                	ld	s0,0(sp)
    80004cbe:	0141                	addi	sp,sp,16
    80004cc0:	8082                	ret

0000000080004cc2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004cc2:	1101                	addi	sp,sp,-32
    80004cc4:	ec06                	sd	ra,24(sp)
    80004cc6:	e822                	sd	s0,16(sp)
    80004cc8:	e426                	sd	s1,8(sp)
    80004cca:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ccc:	0002c517          	auipc	a0,0x2c
    80004cd0:	61c50513          	addi	a0,a0,1564 # 800312e8 <ftable>
    80004cd4:	ffffc097          	auipc	ra,0xffffc
    80004cd8:	f02080e7          	jalr	-254(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cdc:	0002c497          	auipc	s1,0x2c
    80004ce0:	62448493          	addi	s1,s1,1572 # 80031300 <ftable+0x18>
    80004ce4:	0002d717          	auipc	a4,0x2d
    80004ce8:	5bc70713          	addi	a4,a4,1468 # 800322a0 <disk>
    if(f->ref == 0){
    80004cec:	40dc                	lw	a5,4(s1)
    80004cee:	cf99                	beqz	a5,80004d0c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cf0:	02848493          	addi	s1,s1,40
    80004cf4:	fee49ce3          	bne	s1,a4,80004cec <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004cf8:	0002c517          	auipc	a0,0x2c
    80004cfc:	5f050513          	addi	a0,a0,1520 # 800312e8 <ftable>
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	f8a080e7          	jalr	-118(ra) # 80000c8a <release>
  return 0;
    80004d08:	4481                	li	s1,0
    80004d0a:	a819                	j	80004d20 <filealloc+0x5e>
      f->ref = 1;
    80004d0c:	4785                	li	a5,1
    80004d0e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d10:	0002c517          	auipc	a0,0x2c
    80004d14:	5d850513          	addi	a0,a0,1496 # 800312e8 <ftable>
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	f72080e7          	jalr	-142(ra) # 80000c8a <release>
}
    80004d20:	8526                	mv	a0,s1
    80004d22:	60e2                	ld	ra,24(sp)
    80004d24:	6442                	ld	s0,16(sp)
    80004d26:	64a2                	ld	s1,8(sp)
    80004d28:	6105                	addi	sp,sp,32
    80004d2a:	8082                	ret

0000000080004d2c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d2c:	1101                	addi	sp,sp,-32
    80004d2e:	ec06                	sd	ra,24(sp)
    80004d30:	e822                	sd	s0,16(sp)
    80004d32:	e426                	sd	s1,8(sp)
    80004d34:	1000                	addi	s0,sp,32
    80004d36:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d38:	0002c517          	auipc	a0,0x2c
    80004d3c:	5b050513          	addi	a0,a0,1456 # 800312e8 <ftable>
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	e96080e7          	jalr	-362(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004d48:	40dc                	lw	a5,4(s1)
    80004d4a:	02f05263          	blez	a5,80004d6e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d4e:	2785                	addiw	a5,a5,1
    80004d50:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d52:	0002c517          	auipc	a0,0x2c
    80004d56:	59650513          	addi	a0,a0,1430 # 800312e8 <ftable>
    80004d5a:	ffffc097          	auipc	ra,0xffffc
    80004d5e:	f30080e7          	jalr	-208(ra) # 80000c8a <release>
  return f;
}
    80004d62:	8526                	mv	a0,s1
    80004d64:	60e2                	ld	ra,24(sp)
    80004d66:	6442                	ld	s0,16(sp)
    80004d68:	64a2                	ld	s1,8(sp)
    80004d6a:	6105                	addi	sp,sp,32
    80004d6c:	8082                	ret
    panic("filedup");
    80004d6e:	00004517          	auipc	a0,0x4
    80004d72:	9d250513          	addi	a0,a0,-1582 # 80008740 <syscalls+0x2b0>
    80004d76:	ffffb097          	auipc	ra,0xffffb
    80004d7a:	7c8080e7          	jalr	1992(ra) # 8000053e <panic>

0000000080004d7e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d7e:	7139                	addi	sp,sp,-64
    80004d80:	fc06                	sd	ra,56(sp)
    80004d82:	f822                	sd	s0,48(sp)
    80004d84:	f426                	sd	s1,40(sp)
    80004d86:	f04a                	sd	s2,32(sp)
    80004d88:	ec4e                	sd	s3,24(sp)
    80004d8a:	e852                	sd	s4,16(sp)
    80004d8c:	e456                	sd	s5,8(sp)
    80004d8e:	0080                	addi	s0,sp,64
    80004d90:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d92:	0002c517          	auipc	a0,0x2c
    80004d96:	55650513          	addi	a0,a0,1366 # 800312e8 <ftable>
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	e3c080e7          	jalr	-452(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004da2:	40dc                	lw	a5,4(s1)
    80004da4:	06f05163          	blez	a5,80004e06 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004da8:	37fd                	addiw	a5,a5,-1
    80004daa:	0007871b          	sext.w	a4,a5
    80004dae:	c0dc                	sw	a5,4(s1)
    80004db0:	06e04363          	bgtz	a4,80004e16 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004db4:	0004a903          	lw	s2,0(s1)
    80004db8:	0094ca83          	lbu	s5,9(s1)
    80004dbc:	0104ba03          	ld	s4,16(s1)
    80004dc0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004dc4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004dc8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004dcc:	0002c517          	auipc	a0,0x2c
    80004dd0:	51c50513          	addi	a0,a0,1308 # 800312e8 <ftable>
    80004dd4:	ffffc097          	auipc	ra,0xffffc
    80004dd8:	eb6080e7          	jalr	-330(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004ddc:	4785                	li	a5,1
    80004dde:	04f90d63          	beq	s2,a5,80004e38 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004de2:	3979                	addiw	s2,s2,-2
    80004de4:	4785                	li	a5,1
    80004de6:	0527e063          	bltu	a5,s2,80004e26 <fileclose+0xa8>
    begin_op();
    80004dea:	00000097          	auipc	ra,0x0
    80004dee:	ac8080e7          	jalr	-1336(ra) # 800048b2 <begin_op>
    iput(ff.ip);
    80004df2:	854e                	mv	a0,s3
    80004df4:	fffff097          	auipc	ra,0xfffff
    80004df8:	fa4080e7          	jalr	-92(ra) # 80003d98 <iput>
    end_op();
    80004dfc:	00000097          	auipc	ra,0x0
    80004e00:	b36080e7          	jalr	-1226(ra) # 80004932 <end_op>
    80004e04:	a00d                	j	80004e26 <fileclose+0xa8>
    panic("fileclose");
    80004e06:	00004517          	auipc	a0,0x4
    80004e0a:	94250513          	addi	a0,a0,-1726 # 80008748 <syscalls+0x2b8>
    80004e0e:	ffffb097          	auipc	ra,0xffffb
    80004e12:	730080e7          	jalr	1840(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004e16:	0002c517          	auipc	a0,0x2c
    80004e1a:	4d250513          	addi	a0,a0,1234 # 800312e8 <ftable>
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	e6c080e7          	jalr	-404(ra) # 80000c8a <release>
  }
}
    80004e26:	70e2                	ld	ra,56(sp)
    80004e28:	7442                	ld	s0,48(sp)
    80004e2a:	74a2                	ld	s1,40(sp)
    80004e2c:	7902                	ld	s2,32(sp)
    80004e2e:	69e2                	ld	s3,24(sp)
    80004e30:	6a42                	ld	s4,16(sp)
    80004e32:	6aa2                	ld	s5,8(sp)
    80004e34:	6121                	addi	sp,sp,64
    80004e36:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e38:	85d6                	mv	a1,s5
    80004e3a:	8552                	mv	a0,s4
    80004e3c:	00000097          	auipc	ra,0x0
    80004e40:	542080e7          	jalr	1346(ra) # 8000537e <pipeclose>
    80004e44:	b7cd                	j	80004e26 <fileclose+0xa8>

0000000080004e46 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e46:	715d                	addi	sp,sp,-80
    80004e48:	e486                	sd	ra,72(sp)
    80004e4a:	e0a2                	sd	s0,64(sp)
    80004e4c:	fc26                	sd	s1,56(sp)
    80004e4e:	f84a                	sd	s2,48(sp)
    80004e50:	f44e                	sd	s3,40(sp)
    80004e52:	0880                	addi	s0,sp,80
    80004e54:	84aa                	mv	s1,a0
    80004e56:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e58:	ffffd097          	auipc	ra,0xffffd
    80004e5c:	0d0080e7          	jalr	208(ra) # 80001f28 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e60:	409c                	lw	a5,0(s1)
    80004e62:	37f9                	addiw	a5,a5,-2
    80004e64:	4705                	li	a4,1
    80004e66:	04f76763          	bltu	a4,a5,80004eb4 <filestat+0x6e>
    80004e6a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e6c:	6c88                	ld	a0,24(s1)
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	d70080e7          	jalr	-656(ra) # 80003bde <ilock>
    stati(f->ip, &st);
    80004e76:	fb840593          	addi	a1,s0,-72
    80004e7a:	6c88                	ld	a0,24(s1)
    80004e7c:	fffff097          	auipc	ra,0xfffff
    80004e80:	fec080e7          	jalr	-20(ra) # 80003e68 <stati>
    iunlock(f->ip);
    80004e84:	6c88                	ld	a0,24(s1)
    80004e86:	fffff097          	auipc	ra,0xfffff
    80004e8a:	e1a080e7          	jalr	-486(ra) # 80003ca0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e8e:	46e1                	li	a3,24
    80004e90:	fb840613          	addi	a2,s0,-72
    80004e94:	85ce                	mv	a1,s3
    80004e96:	05093503          	ld	a0,80(s2)
    80004e9a:	ffffc097          	auipc	ra,0xffffc
    80004e9e:	7d6080e7          	jalr	2006(ra) # 80001670 <copyout>
    80004ea2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ea6:	60a6                	ld	ra,72(sp)
    80004ea8:	6406                	ld	s0,64(sp)
    80004eaa:	74e2                	ld	s1,56(sp)
    80004eac:	7942                	ld	s2,48(sp)
    80004eae:	79a2                	ld	s3,40(sp)
    80004eb0:	6161                	addi	sp,sp,80
    80004eb2:	8082                	ret
  return -1;
    80004eb4:	557d                	li	a0,-1
    80004eb6:	bfc5                	j	80004ea6 <filestat+0x60>

0000000080004eb8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004eb8:	7179                	addi	sp,sp,-48
    80004eba:	f406                	sd	ra,40(sp)
    80004ebc:	f022                	sd	s0,32(sp)
    80004ebe:	ec26                	sd	s1,24(sp)
    80004ec0:	e84a                	sd	s2,16(sp)
    80004ec2:	e44e                	sd	s3,8(sp)
    80004ec4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ec6:	00854783          	lbu	a5,8(a0)
    80004eca:	c3d5                	beqz	a5,80004f6e <fileread+0xb6>
    80004ecc:	84aa                	mv	s1,a0
    80004ece:	89ae                	mv	s3,a1
    80004ed0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ed2:	411c                	lw	a5,0(a0)
    80004ed4:	4705                	li	a4,1
    80004ed6:	04e78963          	beq	a5,a4,80004f28 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004eda:	470d                	li	a4,3
    80004edc:	04e78d63          	beq	a5,a4,80004f36 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ee0:	4709                	li	a4,2
    80004ee2:	06e79e63          	bne	a5,a4,80004f5e <fileread+0xa6>
    ilock(f->ip);
    80004ee6:	6d08                	ld	a0,24(a0)
    80004ee8:	fffff097          	auipc	ra,0xfffff
    80004eec:	cf6080e7          	jalr	-778(ra) # 80003bde <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ef0:	874a                	mv	a4,s2
    80004ef2:	5094                	lw	a3,32(s1)
    80004ef4:	864e                	mv	a2,s3
    80004ef6:	4585                	li	a1,1
    80004ef8:	6c88                	ld	a0,24(s1)
    80004efa:	fffff097          	auipc	ra,0xfffff
    80004efe:	f98080e7          	jalr	-104(ra) # 80003e92 <readi>
    80004f02:	892a                	mv	s2,a0
    80004f04:	00a05563          	blez	a0,80004f0e <fileread+0x56>
      f->off += r;
    80004f08:	509c                	lw	a5,32(s1)
    80004f0a:	9fa9                	addw	a5,a5,a0
    80004f0c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f0e:	6c88                	ld	a0,24(s1)
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	d90080e7          	jalr	-624(ra) # 80003ca0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f18:	854a                	mv	a0,s2
    80004f1a:	70a2                	ld	ra,40(sp)
    80004f1c:	7402                	ld	s0,32(sp)
    80004f1e:	64e2                	ld	s1,24(sp)
    80004f20:	6942                	ld	s2,16(sp)
    80004f22:	69a2                	ld	s3,8(sp)
    80004f24:	6145                	addi	sp,sp,48
    80004f26:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f28:	6908                	ld	a0,16(a0)
    80004f2a:	00000097          	auipc	ra,0x0
    80004f2e:	5bc080e7          	jalr	1468(ra) # 800054e6 <piperead>
    80004f32:	892a                	mv	s2,a0
    80004f34:	b7d5                	j	80004f18 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f36:	02451783          	lh	a5,36(a0)
    80004f3a:	03079693          	slli	a3,a5,0x30
    80004f3e:	92c1                	srli	a3,a3,0x30
    80004f40:	4725                	li	a4,9
    80004f42:	02d76863          	bltu	a4,a3,80004f72 <fileread+0xba>
    80004f46:	0792                	slli	a5,a5,0x4
    80004f48:	0002c717          	auipc	a4,0x2c
    80004f4c:	30070713          	addi	a4,a4,768 # 80031248 <devsw>
    80004f50:	97ba                	add	a5,a5,a4
    80004f52:	639c                	ld	a5,0(a5)
    80004f54:	c38d                	beqz	a5,80004f76 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f56:	4505                	li	a0,1
    80004f58:	9782                	jalr	a5
    80004f5a:	892a                	mv	s2,a0
    80004f5c:	bf75                	j	80004f18 <fileread+0x60>
    panic("fileread");
    80004f5e:	00003517          	auipc	a0,0x3
    80004f62:	7fa50513          	addi	a0,a0,2042 # 80008758 <syscalls+0x2c8>
    80004f66:	ffffb097          	auipc	ra,0xffffb
    80004f6a:	5d8080e7          	jalr	1496(ra) # 8000053e <panic>
    return -1;
    80004f6e:	597d                	li	s2,-1
    80004f70:	b765                	j	80004f18 <fileread+0x60>
      return -1;
    80004f72:	597d                	li	s2,-1
    80004f74:	b755                	j	80004f18 <fileread+0x60>
    80004f76:	597d                	li	s2,-1
    80004f78:	b745                	j	80004f18 <fileread+0x60>

0000000080004f7a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f7a:	715d                	addi	sp,sp,-80
    80004f7c:	e486                	sd	ra,72(sp)
    80004f7e:	e0a2                	sd	s0,64(sp)
    80004f80:	fc26                	sd	s1,56(sp)
    80004f82:	f84a                	sd	s2,48(sp)
    80004f84:	f44e                	sd	s3,40(sp)
    80004f86:	f052                	sd	s4,32(sp)
    80004f88:	ec56                	sd	s5,24(sp)
    80004f8a:	e85a                	sd	s6,16(sp)
    80004f8c:	e45e                	sd	s7,8(sp)
    80004f8e:	e062                	sd	s8,0(sp)
    80004f90:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f92:	00954783          	lbu	a5,9(a0)
    80004f96:	10078663          	beqz	a5,800050a2 <filewrite+0x128>
    80004f9a:	892a                	mv	s2,a0
    80004f9c:	8aae                	mv	s5,a1
    80004f9e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fa0:	411c                	lw	a5,0(a0)
    80004fa2:	4705                	li	a4,1
    80004fa4:	02e78263          	beq	a5,a4,80004fc8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fa8:	470d                	li	a4,3
    80004faa:	02e78663          	beq	a5,a4,80004fd6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fae:	4709                	li	a4,2
    80004fb0:	0ee79163          	bne	a5,a4,80005092 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004fb4:	0ac05d63          	blez	a2,8000506e <filewrite+0xf4>
    int i = 0;
    80004fb8:	4981                	li	s3,0
    80004fba:	6b05                	lui	s6,0x1
    80004fbc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004fc0:	6b85                	lui	s7,0x1
    80004fc2:	c00b8b9b          	addiw	s7,s7,-1024
    80004fc6:	a861                	j	8000505e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004fc8:	6908                	ld	a0,16(a0)
    80004fca:	00000097          	auipc	ra,0x0
    80004fce:	424080e7          	jalr	1060(ra) # 800053ee <pipewrite>
    80004fd2:	8a2a                	mv	s4,a0
    80004fd4:	a045                	j	80005074 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004fd6:	02451783          	lh	a5,36(a0)
    80004fda:	03079693          	slli	a3,a5,0x30
    80004fde:	92c1                	srli	a3,a3,0x30
    80004fe0:	4725                	li	a4,9
    80004fe2:	0cd76263          	bltu	a4,a3,800050a6 <filewrite+0x12c>
    80004fe6:	0792                	slli	a5,a5,0x4
    80004fe8:	0002c717          	auipc	a4,0x2c
    80004fec:	26070713          	addi	a4,a4,608 # 80031248 <devsw>
    80004ff0:	97ba                	add	a5,a5,a4
    80004ff2:	679c                	ld	a5,8(a5)
    80004ff4:	cbdd                	beqz	a5,800050aa <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ff6:	4505                	li	a0,1
    80004ff8:	9782                	jalr	a5
    80004ffa:	8a2a                	mv	s4,a0
    80004ffc:	a8a5                	j	80005074 <filewrite+0xfa>
    80004ffe:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005002:	00000097          	auipc	ra,0x0
    80005006:	8b0080e7          	jalr	-1872(ra) # 800048b2 <begin_op>
      ilock(f->ip);
    8000500a:	01893503          	ld	a0,24(s2)
    8000500e:	fffff097          	auipc	ra,0xfffff
    80005012:	bd0080e7          	jalr	-1072(ra) # 80003bde <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005016:	8762                	mv	a4,s8
    80005018:	02092683          	lw	a3,32(s2)
    8000501c:	01598633          	add	a2,s3,s5
    80005020:	4585                	li	a1,1
    80005022:	01893503          	ld	a0,24(s2)
    80005026:	fffff097          	auipc	ra,0xfffff
    8000502a:	f64080e7          	jalr	-156(ra) # 80003f8a <writei>
    8000502e:	84aa                	mv	s1,a0
    80005030:	00a05763          	blez	a0,8000503e <filewrite+0xc4>
        f->off += r;
    80005034:	02092783          	lw	a5,32(s2)
    80005038:	9fa9                	addw	a5,a5,a0
    8000503a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000503e:	01893503          	ld	a0,24(s2)
    80005042:	fffff097          	auipc	ra,0xfffff
    80005046:	c5e080e7          	jalr	-930(ra) # 80003ca0 <iunlock>
      end_op();
    8000504a:	00000097          	auipc	ra,0x0
    8000504e:	8e8080e7          	jalr	-1816(ra) # 80004932 <end_op>

      if(r != n1){
    80005052:	009c1f63          	bne	s8,s1,80005070 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005056:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000505a:	0149db63          	bge	s3,s4,80005070 <filewrite+0xf6>
      int n1 = n - i;
    8000505e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005062:	84be                	mv	s1,a5
    80005064:	2781                	sext.w	a5,a5
    80005066:	f8fb5ce3          	bge	s6,a5,80004ffe <filewrite+0x84>
    8000506a:	84de                	mv	s1,s7
    8000506c:	bf49                	j	80004ffe <filewrite+0x84>
    int i = 0;
    8000506e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005070:	013a1f63          	bne	s4,s3,8000508e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005074:	8552                	mv	a0,s4
    80005076:	60a6                	ld	ra,72(sp)
    80005078:	6406                	ld	s0,64(sp)
    8000507a:	74e2                	ld	s1,56(sp)
    8000507c:	7942                	ld	s2,48(sp)
    8000507e:	79a2                	ld	s3,40(sp)
    80005080:	7a02                	ld	s4,32(sp)
    80005082:	6ae2                	ld	s5,24(sp)
    80005084:	6b42                	ld	s6,16(sp)
    80005086:	6ba2                	ld	s7,8(sp)
    80005088:	6c02                	ld	s8,0(sp)
    8000508a:	6161                	addi	sp,sp,80
    8000508c:	8082                	ret
    ret = (i == n ? n : -1);
    8000508e:	5a7d                	li	s4,-1
    80005090:	b7d5                	j	80005074 <filewrite+0xfa>
    panic("filewrite");
    80005092:	00003517          	auipc	a0,0x3
    80005096:	6d650513          	addi	a0,a0,1750 # 80008768 <syscalls+0x2d8>
    8000509a:	ffffb097          	auipc	ra,0xffffb
    8000509e:	4a4080e7          	jalr	1188(ra) # 8000053e <panic>
    return -1;
    800050a2:	5a7d                	li	s4,-1
    800050a4:	bfc1                	j	80005074 <filewrite+0xfa>
      return -1;
    800050a6:	5a7d                	li	s4,-1
    800050a8:	b7f1                	j	80005074 <filewrite+0xfa>
    800050aa:	5a7d                	li	s4,-1
    800050ac:	b7e1                	j	80005074 <filewrite+0xfa>

00000000800050ae <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    800050ae:	7179                	addi	sp,sp,-48
    800050b0:	f406                	sd	ra,40(sp)
    800050b2:	f022                	sd	s0,32(sp)
    800050b4:	ec26                	sd	s1,24(sp)
    800050b6:	e84a                	sd	s2,16(sp)
    800050b8:	e44e                	sd	s3,8(sp)
    800050ba:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800050bc:	00854783          	lbu	a5,8(a0)
    800050c0:	c3d5                	beqz	a5,80005164 <kfileread+0xb6>
    800050c2:	84aa                	mv	s1,a0
    800050c4:	89ae                	mv	s3,a1
    800050c6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800050c8:	411c                	lw	a5,0(a0)
    800050ca:	4705                	li	a4,1
    800050cc:	04e78963          	beq	a5,a4,8000511e <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800050d0:	470d                	li	a4,3
    800050d2:	04e78d63          	beq	a5,a4,8000512c <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800050d6:	4709                	li	a4,2
    800050d8:	06e79e63          	bne	a5,a4,80005154 <kfileread+0xa6>
    ilock(f->ip);
    800050dc:	6d08                	ld	a0,24(a0)
    800050de:	fffff097          	auipc	ra,0xfffff
    800050e2:	b00080e7          	jalr	-1280(ra) # 80003bde <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    800050e6:	874a                	mv	a4,s2
    800050e8:	5094                	lw	a3,32(s1)
    800050ea:	864e                	mv	a2,s3
    800050ec:	4581                	li	a1,0
    800050ee:	6c88                	ld	a0,24(s1)
    800050f0:	fffff097          	auipc	ra,0xfffff
    800050f4:	da2080e7          	jalr	-606(ra) # 80003e92 <readi>
    800050f8:	892a                	mv	s2,a0
    800050fa:	00a05563          	blez	a0,80005104 <kfileread+0x56>
      f->off += r;
    800050fe:	509c                	lw	a5,32(s1)
    80005100:	9fa9                	addw	a5,a5,a0
    80005102:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005104:	6c88                	ld	a0,24(s1)
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	b9a080e7          	jalr	-1126(ra) # 80003ca0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000510e:	854a                	mv	a0,s2
    80005110:	70a2                	ld	ra,40(sp)
    80005112:	7402                	ld	s0,32(sp)
    80005114:	64e2                	ld	s1,24(sp)
    80005116:	6942                	ld	s2,16(sp)
    80005118:	69a2                	ld	s3,8(sp)
    8000511a:	6145                	addi	sp,sp,48
    8000511c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000511e:	6908                	ld	a0,16(a0)
    80005120:	00000097          	auipc	ra,0x0
    80005124:	3c6080e7          	jalr	966(ra) # 800054e6 <piperead>
    80005128:	892a                	mv	s2,a0
    8000512a:	b7d5                	j	8000510e <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000512c:	02451783          	lh	a5,36(a0)
    80005130:	03079693          	slli	a3,a5,0x30
    80005134:	92c1                	srli	a3,a3,0x30
    80005136:	4725                	li	a4,9
    80005138:	02d76863          	bltu	a4,a3,80005168 <kfileread+0xba>
    8000513c:	0792                	slli	a5,a5,0x4
    8000513e:	0002c717          	auipc	a4,0x2c
    80005142:	10a70713          	addi	a4,a4,266 # 80031248 <devsw>
    80005146:	97ba                	add	a5,a5,a4
    80005148:	639c                	ld	a5,0(a5)
    8000514a:	c38d                	beqz	a5,8000516c <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000514c:	4505                	li	a0,1
    8000514e:	9782                	jalr	a5
    80005150:	892a                	mv	s2,a0
    80005152:	bf75                	j	8000510e <kfileread+0x60>
    panic("fileread");
    80005154:	00003517          	auipc	a0,0x3
    80005158:	60450513          	addi	a0,a0,1540 # 80008758 <syscalls+0x2c8>
    8000515c:	ffffb097          	auipc	ra,0xffffb
    80005160:	3e2080e7          	jalr	994(ra) # 8000053e <panic>
    return -1;
    80005164:	597d                	li	s2,-1
    80005166:	b765                	j	8000510e <kfileread+0x60>
      return -1;
    80005168:	597d                	li	s2,-1
    8000516a:	b755                	j	8000510e <kfileread+0x60>
    8000516c:	597d                	li	s2,-1
    8000516e:	b745                	j	8000510e <kfileread+0x60>

0000000080005170 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80005170:	715d                	addi	sp,sp,-80
    80005172:	e486                	sd	ra,72(sp)
    80005174:	e0a2                	sd	s0,64(sp)
    80005176:	fc26                	sd	s1,56(sp)
    80005178:	f84a                	sd	s2,48(sp)
    8000517a:	f44e                	sd	s3,40(sp)
    8000517c:	f052                	sd	s4,32(sp)
    8000517e:	ec56                	sd	s5,24(sp)
    80005180:	e85a                	sd	s6,16(sp)
    80005182:	e45e                	sd	s7,8(sp)
    80005184:	e062                	sd	s8,0(sp)
    80005186:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005188:	00954783          	lbu	a5,9(a0)
    8000518c:	10078663          	beqz	a5,80005298 <kfilewrite+0x128>
    80005190:	892a                	mv	s2,a0
    80005192:	8aae                	mv	s5,a1
    80005194:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005196:	411c                	lw	a5,0(a0)
    80005198:	4705                	li	a4,1
    8000519a:	02e78263          	beq	a5,a4,800051be <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000519e:	470d                	li	a4,3
    800051a0:	02e78663          	beq	a5,a4,800051cc <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800051a4:	4709                	li	a4,2
    800051a6:	0ee79163          	bne	a5,a4,80005288 <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800051aa:	0ac05d63          	blez	a2,80005264 <kfilewrite+0xf4>
    int i = 0;
    800051ae:	4981                	li	s3,0
    800051b0:	6b05                	lui	s6,0x1
    800051b2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800051b6:	6b85                	lui	s7,0x1
    800051b8:	c00b8b9b          	addiw	s7,s7,-1024
    800051bc:	a861                	j	80005254 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800051be:	6908                	ld	a0,16(a0)
    800051c0:	00000097          	auipc	ra,0x0
    800051c4:	22e080e7          	jalr	558(ra) # 800053ee <pipewrite>
    800051c8:	8a2a                	mv	s4,a0
    800051ca:	a045                	j	8000526a <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800051cc:	02451783          	lh	a5,36(a0)
    800051d0:	03079693          	slli	a3,a5,0x30
    800051d4:	92c1                	srli	a3,a3,0x30
    800051d6:	4725                	li	a4,9
    800051d8:	0cd76263          	bltu	a4,a3,8000529c <kfilewrite+0x12c>
    800051dc:	0792                	slli	a5,a5,0x4
    800051de:	0002c717          	auipc	a4,0x2c
    800051e2:	06a70713          	addi	a4,a4,106 # 80031248 <devsw>
    800051e6:	97ba                	add	a5,a5,a4
    800051e8:	679c                	ld	a5,8(a5)
    800051ea:	cbdd                	beqz	a5,800052a0 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800051ec:	4505                	li	a0,1
    800051ee:	9782                	jalr	a5
    800051f0:	8a2a                	mv	s4,a0
    800051f2:	a8a5                	j	8000526a <kfilewrite+0xfa>
    800051f4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	6ba080e7          	jalr	1722(ra) # 800048b2 <begin_op>
      ilock(f->ip);
    80005200:	01893503          	ld	a0,24(s2)
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	9da080e7          	jalr	-1574(ra) # 80003bde <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    8000520c:	8762                	mv	a4,s8
    8000520e:	02092683          	lw	a3,32(s2)
    80005212:	01598633          	add	a2,s3,s5
    80005216:	4581                	li	a1,0
    80005218:	01893503          	ld	a0,24(s2)
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	d6e080e7          	jalr	-658(ra) # 80003f8a <writei>
    80005224:	84aa                	mv	s1,a0
    80005226:	00a05763          	blez	a0,80005234 <kfilewrite+0xc4>
        f->off += r;
    8000522a:	02092783          	lw	a5,32(s2)
    8000522e:	9fa9                	addw	a5,a5,a0
    80005230:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005234:	01893503          	ld	a0,24(s2)
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	a68080e7          	jalr	-1432(ra) # 80003ca0 <iunlock>
      end_op();
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	6f2080e7          	jalr	1778(ra) # 80004932 <end_op>

      if(r != n1){
    80005248:	009c1f63          	bne	s8,s1,80005266 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000524c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005250:	0149db63          	bge	s3,s4,80005266 <kfilewrite+0xf6>
      int n1 = n - i;
    80005254:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005258:	84be                	mv	s1,a5
    8000525a:	2781                	sext.w	a5,a5
    8000525c:	f8fb5ce3          	bge	s6,a5,800051f4 <kfilewrite+0x84>
    80005260:	84de                	mv	s1,s7
    80005262:	bf49                	j	800051f4 <kfilewrite+0x84>
    int i = 0;
    80005264:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005266:	013a1f63          	bne	s4,s3,80005284 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    8000526a:	8552                	mv	a0,s4
    8000526c:	60a6                	ld	ra,72(sp)
    8000526e:	6406                	ld	s0,64(sp)
    80005270:	74e2                	ld	s1,56(sp)
    80005272:	7942                	ld	s2,48(sp)
    80005274:	79a2                	ld	s3,40(sp)
    80005276:	7a02                	ld	s4,32(sp)
    80005278:	6ae2                	ld	s5,24(sp)
    8000527a:	6b42                	ld	s6,16(sp)
    8000527c:	6ba2                	ld	s7,8(sp)
    8000527e:	6c02                	ld	s8,0(sp)
    80005280:	6161                	addi	sp,sp,80
    80005282:	8082                	ret
    ret = (i == n ? n : -1);
    80005284:	5a7d                	li	s4,-1
    80005286:	b7d5                	j	8000526a <kfilewrite+0xfa>
    panic("filewrite");
    80005288:	00003517          	auipc	a0,0x3
    8000528c:	4e050513          	addi	a0,a0,1248 # 80008768 <syscalls+0x2d8>
    80005290:	ffffb097          	auipc	ra,0xffffb
    80005294:	2ae080e7          	jalr	686(ra) # 8000053e <panic>
    return -1;
    80005298:	5a7d                	li	s4,-1
    8000529a:	bfc1                	j	8000526a <kfilewrite+0xfa>
      return -1;
    8000529c:	5a7d                	li	s4,-1
    8000529e:	b7f1                	j	8000526a <kfilewrite+0xfa>
    800052a0:	5a7d                	li	s4,-1
    800052a2:	b7e1                	j	8000526a <kfilewrite+0xfa>

00000000800052a4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800052a4:	7179                	addi	sp,sp,-48
    800052a6:	f406                	sd	ra,40(sp)
    800052a8:	f022                	sd	s0,32(sp)
    800052aa:	ec26                	sd	s1,24(sp)
    800052ac:	e84a                	sd	s2,16(sp)
    800052ae:	e44e                	sd	s3,8(sp)
    800052b0:	e052                	sd	s4,0(sp)
    800052b2:	1800                	addi	s0,sp,48
    800052b4:	84aa                	mv	s1,a0
    800052b6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800052b8:	0005b023          	sd	zero,0(a1)
    800052bc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	a02080e7          	jalr	-1534(ra) # 80004cc2 <filealloc>
    800052c8:	e088                	sd	a0,0(s1)
    800052ca:	c551                	beqz	a0,80005356 <pipealloc+0xb2>
    800052cc:	00000097          	auipc	ra,0x0
    800052d0:	9f6080e7          	jalr	-1546(ra) # 80004cc2 <filealloc>
    800052d4:	00aa3023          	sd	a0,0(s4)
    800052d8:	c92d                	beqz	a0,8000534a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800052da:	ffffc097          	auipc	ra,0xffffc
    800052de:	80c080e7          	jalr	-2036(ra) # 80000ae6 <kalloc>
    800052e2:	892a                	mv	s2,a0
    800052e4:	c125                	beqz	a0,80005344 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800052e6:	4985                	li	s3,1
    800052e8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800052ec:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800052f0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800052f4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800052f8:	00003597          	auipc	a1,0x3
    800052fc:	48058593          	addi	a1,a1,1152 # 80008778 <syscalls+0x2e8>
    80005300:	ffffc097          	auipc	ra,0xffffc
    80005304:	846080e7          	jalr	-1978(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80005308:	609c                	ld	a5,0(s1)
    8000530a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000530e:	609c                	ld	a5,0(s1)
    80005310:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005314:	609c                	ld	a5,0(s1)
    80005316:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000531a:	609c                	ld	a5,0(s1)
    8000531c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005320:	000a3783          	ld	a5,0(s4)
    80005324:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005328:	000a3783          	ld	a5,0(s4)
    8000532c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005330:	000a3783          	ld	a5,0(s4)
    80005334:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005338:	000a3783          	ld	a5,0(s4)
    8000533c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005340:	4501                	li	a0,0
    80005342:	a025                	j	8000536a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005344:	6088                	ld	a0,0(s1)
    80005346:	e501                	bnez	a0,8000534e <pipealloc+0xaa>
    80005348:	a039                	j	80005356 <pipealloc+0xb2>
    8000534a:	6088                	ld	a0,0(s1)
    8000534c:	c51d                	beqz	a0,8000537a <pipealloc+0xd6>
    fileclose(*f0);
    8000534e:	00000097          	auipc	ra,0x0
    80005352:	a30080e7          	jalr	-1488(ra) # 80004d7e <fileclose>
  if(*f1)
    80005356:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000535a:	557d                	li	a0,-1
  if(*f1)
    8000535c:	c799                	beqz	a5,8000536a <pipealloc+0xc6>
    fileclose(*f1);
    8000535e:	853e                	mv	a0,a5
    80005360:	00000097          	auipc	ra,0x0
    80005364:	a1e080e7          	jalr	-1506(ra) # 80004d7e <fileclose>
  return -1;
    80005368:	557d                	li	a0,-1
}
    8000536a:	70a2                	ld	ra,40(sp)
    8000536c:	7402                	ld	s0,32(sp)
    8000536e:	64e2                	ld	s1,24(sp)
    80005370:	6942                	ld	s2,16(sp)
    80005372:	69a2                	ld	s3,8(sp)
    80005374:	6a02                	ld	s4,0(sp)
    80005376:	6145                	addi	sp,sp,48
    80005378:	8082                	ret
  return -1;
    8000537a:	557d                	li	a0,-1
    8000537c:	b7fd                	j	8000536a <pipealloc+0xc6>

000000008000537e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000537e:	1101                	addi	sp,sp,-32
    80005380:	ec06                	sd	ra,24(sp)
    80005382:	e822                	sd	s0,16(sp)
    80005384:	e426                	sd	s1,8(sp)
    80005386:	e04a                	sd	s2,0(sp)
    80005388:	1000                	addi	s0,sp,32
    8000538a:	84aa                	mv	s1,a0
    8000538c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000538e:	ffffc097          	auipc	ra,0xffffc
    80005392:	848080e7          	jalr	-1976(ra) # 80000bd6 <acquire>
  if(writable){
    80005396:	02090d63          	beqz	s2,800053d0 <pipeclose+0x52>
    pi->writeopen = 0;
    8000539a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000539e:	21848513          	addi	a0,s1,536
    800053a2:	ffffd097          	auipc	ra,0xffffd
    800053a6:	2b2080e7          	jalr	690(ra) # 80002654 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800053aa:	2204b783          	ld	a5,544(s1)
    800053ae:	eb95                	bnez	a5,800053e2 <pipeclose+0x64>
    release(&pi->lock);
    800053b0:	8526                	mv	a0,s1
    800053b2:	ffffc097          	auipc	ra,0xffffc
    800053b6:	8d8080e7          	jalr	-1832(ra) # 80000c8a <release>
    kfree((char*)pi);
    800053ba:	8526                	mv	a0,s1
    800053bc:	ffffb097          	auipc	ra,0xffffb
    800053c0:	62e080e7          	jalr	1582(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    800053c4:	60e2                	ld	ra,24(sp)
    800053c6:	6442                	ld	s0,16(sp)
    800053c8:	64a2                	ld	s1,8(sp)
    800053ca:	6902                	ld	s2,0(sp)
    800053cc:	6105                	addi	sp,sp,32
    800053ce:	8082                	ret
    pi->readopen = 0;
    800053d0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800053d4:	21c48513          	addi	a0,s1,540
    800053d8:	ffffd097          	auipc	ra,0xffffd
    800053dc:	27c080e7          	jalr	636(ra) # 80002654 <wakeup>
    800053e0:	b7e9                	j	800053aa <pipeclose+0x2c>
    release(&pi->lock);
    800053e2:	8526                	mv	a0,s1
    800053e4:	ffffc097          	auipc	ra,0xffffc
    800053e8:	8a6080e7          	jalr	-1882(ra) # 80000c8a <release>
}
    800053ec:	bfe1                	j	800053c4 <pipeclose+0x46>

00000000800053ee <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800053ee:	711d                	addi	sp,sp,-96
    800053f0:	ec86                	sd	ra,88(sp)
    800053f2:	e8a2                	sd	s0,80(sp)
    800053f4:	e4a6                	sd	s1,72(sp)
    800053f6:	e0ca                	sd	s2,64(sp)
    800053f8:	fc4e                	sd	s3,56(sp)
    800053fa:	f852                	sd	s4,48(sp)
    800053fc:	f456                	sd	s5,40(sp)
    800053fe:	f05a                	sd	s6,32(sp)
    80005400:	ec5e                	sd	s7,24(sp)
    80005402:	e862                	sd	s8,16(sp)
    80005404:	1080                	addi	s0,sp,96
    80005406:	84aa                	mv	s1,a0
    80005408:	8aae                	mv	s5,a1
    8000540a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000540c:	ffffd097          	auipc	ra,0xffffd
    80005410:	b1c080e7          	jalr	-1252(ra) # 80001f28 <myproc>
    80005414:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005416:	8526                	mv	a0,s1
    80005418:	ffffb097          	auipc	ra,0xffffb
    8000541c:	7be080e7          	jalr	1982(ra) # 80000bd6 <acquire>
  while(i < n){
    80005420:	0b405663          	blez	s4,800054cc <pipewrite+0xde>
  int i = 0;
    80005424:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005426:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005428:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000542c:	21c48b93          	addi	s7,s1,540
    80005430:	a089                	j	80005472 <pipewrite+0x84>
      release(&pi->lock);
    80005432:	8526                	mv	a0,s1
    80005434:	ffffc097          	auipc	ra,0xffffc
    80005438:	856080e7          	jalr	-1962(ra) # 80000c8a <release>
      return -1;
    8000543c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000543e:	854a                	mv	a0,s2
    80005440:	60e6                	ld	ra,88(sp)
    80005442:	6446                	ld	s0,80(sp)
    80005444:	64a6                	ld	s1,72(sp)
    80005446:	6906                	ld	s2,64(sp)
    80005448:	79e2                	ld	s3,56(sp)
    8000544a:	7a42                	ld	s4,48(sp)
    8000544c:	7aa2                	ld	s5,40(sp)
    8000544e:	7b02                	ld	s6,32(sp)
    80005450:	6be2                	ld	s7,24(sp)
    80005452:	6c42                	ld	s8,16(sp)
    80005454:	6125                	addi	sp,sp,96
    80005456:	8082                	ret
      wakeup(&pi->nread);
    80005458:	8562                	mv	a0,s8
    8000545a:	ffffd097          	auipc	ra,0xffffd
    8000545e:	1fa080e7          	jalr	506(ra) # 80002654 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005462:	85a6                	mv	a1,s1
    80005464:	855e                	mv	a0,s7
    80005466:	ffffd097          	auipc	ra,0xffffd
    8000546a:	18a080e7          	jalr	394(ra) # 800025f0 <sleep>
  while(i < n){
    8000546e:	07495063          	bge	s2,s4,800054ce <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005472:	2204a783          	lw	a5,544(s1)
    80005476:	dfd5                	beqz	a5,80005432 <pipewrite+0x44>
    80005478:	854e                	mv	a0,s3
    8000547a:	ffffd097          	auipc	ra,0xffffd
    8000547e:	434080e7          	jalr	1076(ra) # 800028ae <killed>
    80005482:	f945                	bnez	a0,80005432 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005484:	2184a783          	lw	a5,536(s1)
    80005488:	21c4a703          	lw	a4,540(s1)
    8000548c:	2007879b          	addiw	a5,a5,512
    80005490:	fcf704e3          	beq	a4,a5,80005458 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005494:	4685                	li	a3,1
    80005496:	01590633          	add	a2,s2,s5
    8000549a:	faf40593          	addi	a1,s0,-81
    8000549e:	0509b503          	ld	a0,80(s3)
    800054a2:	ffffc097          	auipc	ra,0xffffc
    800054a6:	25a080e7          	jalr	602(ra) # 800016fc <copyin>
    800054aa:	03650263          	beq	a0,s6,800054ce <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800054ae:	21c4a783          	lw	a5,540(s1)
    800054b2:	0017871b          	addiw	a4,a5,1
    800054b6:	20e4ae23          	sw	a4,540(s1)
    800054ba:	1ff7f793          	andi	a5,a5,511
    800054be:	97a6                	add	a5,a5,s1
    800054c0:	faf44703          	lbu	a4,-81(s0)
    800054c4:	00e78c23          	sb	a4,24(a5)
      i++;
    800054c8:	2905                	addiw	s2,s2,1
    800054ca:	b755                	j	8000546e <pipewrite+0x80>
  int i = 0;
    800054cc:	4901                	li	s2,0
  wakeup(&pi->nread);
    800054ce:	21848513          	addi	a0,s1,536
    800054d2:	ffffd097          	auipc	ra,0xffffd
    800054d6:	182080e7          	jalr	386(ra) # 80002654 <wakeup>
  release(&pi->lock);
    800054da:	8526                	mv	a0,s1
    800054dc:	ffffb097          	auipc	ra,0xffffb
    800054e0:	7ae080e7          	jalr	1966(ra) # 80000c8a <release>
  return i;
    800054e4:	bfa9                	j	8000543e <pipewrite+0x50>

00000000800054e6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800054e6:	715d                	addi	sp,sp,-80
    800054e8:	e486                	sd	ra,72(sp)
    800054ea:	e0a2                	sd	s0,64(sp)
    800054ec:	fc26                	sd	s1,56(sp)
    800054ee:	f84a                	sd	s2,48(sp)
    800054f0:	f44e                	sd	s3,40(sp)
    800054f2:	f052                	sd	s4,32(sp)
    800054f4:	ec56                	sd	s5,24(sp)
    800054f6:	e85a                	sd	s6,16(sp)
    800054f8:	0880                	addi	s0,sp,80
    800054fa:	84aa                	mv	s1,a0
    800054fc:	892e                	mv	s2,a1
    800054fe:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005500:	ffffd097          	auipc	ra,0xffffd
    80005504:	a28080e7          	jalr	-1496(ra) # 80001f28 <myproc>
    80005508:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffb097          	auipc	ra,0xffffb
    80005510:	6ca080e7          	jalr	1738(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005514:	2184a703          	lw	a4,536(s1)
    80005518:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000551c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005520:	02f71763          	bne	a4,a5,8000554e <piperead+0x68>
    80005524:	2244a783          	lw	a5,548(s1)
    80005528:	c39d                	beqz	a5,8000554e <piperead+0x68>
    if(killed(pr)){
    8000552a:	8552                	mv	a0,s4
    8000552c:	ffffd097          	auipc	ra,0xffffd
    80005530:	382080e7          	jalr	898(ra) # 800028ae <killed>
    80005534:	e941                	bnez	a0,800055c4 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005536:	85a6                	mv	a1,s1
    80005538:	854e                	mv	a0,s3
    8000553a:	ffffd097          	auipc	ra,0xffffd
    8000553e:	0b6080e7          	jalr	182(ra) # 800025f0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005542:	2184a703          	lw	a4,536(s1)
    80005546:	21c4a783          	lw	a5,540(s1)
    8000554a:	fcf70de3          	beq	a4,a5,80005524 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000554e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005550:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005552:	05505363          	blez	s5,80005598 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80005556:	2184a783          	lw	a5,536(s1)
    8000555a:	21c4a703          	lw	a4,540(s1)
    8000555e:	02f70d63          	beq	a4,a5,80005598 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005562:	0017871b          	addiw	a4,a5,1
    80005566:	20e4ac23          	sw	a4,536(s1)
    8000556a:	1ff7f793          	andi	a5,a5,511
    8000556e:	97a6                	add	a5,a5,s1
    80005570:	0187c783          	lbu	a5,24(a5)
    80005574:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005578:	4685                	li	a3,1
    8000557a:	fbf40613          	addi	a2,s0,-65
    8000557e:	85ca                	mv	a1,s2
    80005580:	050a3503          	ld	a0,80(s4)
    80005584:	ffffc097          	auipc	ra,0xffffc
    80005588:	0ec080e7          	jalr	236(ra) # 80001670 <copyout>
    8000558c:	01650663          	beq	a0,s6,80005598 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005590:	2985                	addiw	s3,s3,1
    80005592:	0905                	addi	s2,s2,1
    80005594:	fd3a91e3          	bne	s5,s3,80005556 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005598:	21c48513          	addi	a0,s1,540
    8000559c:	ffffd097          	auipc	ra,0xffffd
    800055a0:	0b8080e7          	jalr	184(ra) # 80002654 <wakeup>
  release(&pi->lock);
    800055a4:	8526                	mv	a0,s1
    800055a6:	ffffb097          	auipc	ra,0xffffb
    800055aa:	6e4080e7          	jalr	1764(ra) # 80000c8a <release>
  return i;
}
    800055ae:	854e                	mv	a0,s3
    800055b0:	60a6                	ld	ra,72(sp)
    800055b2:	6406                	ld	s0,64(sp)
    800055b4:	74e2                	ld	s1,56(sp)
    800055b6:	7942                	ld	s2,48(sp)
    800055b8:	79a2                	ld	s3,40(sp)
    800055ba:	7a02                	ld	s4,32(sp)
    800055bc:	6ae2                	ld	s5,24(sp)
    800055be:	6b42                	ld	s6,16(sp)
    800055c0:	6161                	addi	sp,sp,80
    800055c2:	8082                	ret
      release(&pi->lock);
    800055c4:	8526                	mv	a0,s1
    800055c6:	ffffb097          	auipc	ra,0xffffb
    800055ca:	6c4080e7          	jalr	1732(ra) # 80000c8a <release>
      return -1;
    800055ce:	59fd                	li	s3,-1
    800055d0:	bff9                	j	800055ae <piperead+0xc8>

00000000800055d2 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800055d2:	1141                	addi	sp,sp,-16
    800055d4:	e422                	sd	s0,8(sp)
    800055d6:	0800                	addi	s0,sp,16
    800055d8:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800055da:	8905                	andi	a0,a0,1
    800055dc:	c111                	beqz	a0,800055e0 <flags2perm+0xe>
      perm = PTE_X;
    800055de:	4521                	li	a0,8
    if(flags & 0x2)
    800055e0:	8b89                	andi	a5,a5,2
    800055e2:	c399                	beqz	a5,800055e8 <flags2perm+0x16>
      perm |= PTE_W;
    800055e4:	00456513          	ori	a0,a0,4
    return perm;
}
    800055e8:	6422                	ld	s0,8(sp)
    800055ea:	0141                	addi	sp,sp,16
    800055ec:	8082                	ret

00000000800055ee <exec>:

int
exec(char *path, char **argv)
{
    800055ee:	de010113          	addi	sp,sp,-544
    800055f2:	20113c23          	sd	ra,536(sp)
    800055f6:	20813823          	sd	s0,528(sp)
    800055fa:	20913423          	sd	s1,520(sp)
    800055fe:	21213023          	sd	s2,512(sp)
    80005602:	ffce                	sd	s3,504(sp)
    80005604:	fbd2                	sd	s4,496(sp)
    80005606:	f7d6                	sd	s5,488(sp)
    80005608:	f3da                	sd	s6,480(sp)
    8000560a:	efde                	sd	s7,472(sp)
    8000560c:	ebe2                	sd	s8,464(sp)
    8000560e:	e7e6                	sd	s9,456(sp)
    80005610:	e3ea                	sd	s10,448(sp)
    80005612:	ff6e                	sd	s11,440(sp)
    80005614:	1400                	addi	s0,sp,544
    80005616:	892a                	mv	s2,a0
    80005618:	dea43423          	sd	a0,-536(s0)
    8000561c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005620:	ffffd097          	auipc	ra,0xffffd
    80005624:	908080e7          	jalr	-1784(ra) # 80001f28 <myproc>
    80005628:	84aa                	mv	s1,a0
    removeSwapFile(p);
    createSwapFile(p);
  }
  #endif

  begin_op();
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	288080e7          	jalr	648(ra) # 800048b2 <begin_op>

  if((ip = namei(path)) == 0){
    80005632:	854a                	mv	a0,s2
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	d50080e7          	jalr	-688(ra) # 80004384 <namei>
    8000563c:	c93d                	beqz	a0,800056b2 <exec+0xc4>
    8000563e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	59e080e7          	jalr	1438(ra) # 80003bde <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005648:	04000713          	li	a4,64
    8000564c:	4681                	li	a3,0
    8000564e:	e5040613          	addi	a2,s0,-432
    80005652:	4581                	li	a1,0
    80005654:	8556                	mv	a0,s5
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	83c080e7          	jalr	-1988(ra) # 80003e92 <readi>
    8000565e:	04000793          	li	a5,64
    80005662:	00f51a63          	bne	a0,a5,80005676 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005666:	e5042703          	lw	a4,-432(s0)
    8000566a:	464c47b7          	lui	a5,0x464c4
    8000566e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005672:	04f70663          	beq	a4,a5,800056be <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005676:	8556                	mv	a0,s5
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	7c8080e7          	jalr	1992(ra) # 80003e40 <iunlockput>
    end_op();
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	2b2080e7          	jalr	690(ra) # 80004932 <end_op>
  }
  return -1;
    80005688:	557d                	li	a0,-1
}
    8000568a:	21813083          	ld	ra,536(sp)
    8000568e:	21013403          	ld	s0,528(sp)
    80005692:	20813483          	ld	s1,520(sp)
    80005696:	20013903          	ld	s2,512(sp)
    8000569a:	79fe                	ld	s3,504(sp)
    8000569c:	7a5e                	ld	s4,496(sp)
    8000569e:	7abe                	ld	s5,488(sp)
    800056a0:	7b1e                	ld	s6,480(sp)
    800056a2:	6bfe                	ld	s7,472(sp)
    800056a4:	6c5e                	ld	s8,464(sp)
    800056a6:	6cbe                	ld	s9,456(sp)
    800056a8:	6d1e                	ld	s10,448(sp)
    800056aa:	7dfa                	ld	s11,440(sp)
    800056ac:	22010113          	addi	sp,sp,544
    800056b0:	8082                	ret
    end_op();
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	280080e7          	jalr	640(ra) # 80004932 <end_op>
    return -1;
    800056ba:	557d                	li	a0,-1
    800056bc:	b7f9                	j	8000568a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800056be:	8526                	mv	a0,s1
    800056c0:	ffffd097          	auipc	ra,0xffffd
    800056c4:	92c080e7          	jalr	-1748(ra) # 80001fec <proc_pagetable>
    800056c8:	8b2a                	mv	s6,a0
    800056ca:	d555                	beqz	a0,80005676 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056cc:	e7042783          	lw	a5,-400(s0)
    800056d0:	e8845703          	lhu	a4,-376(s0)
    800056d4:	c735                	beqz	a4,80005740 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800056d6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056d8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800056dc:	6a05                	lui	s4,0x1
    800056de:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800056e2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800056e6:	6d85                	lui	s11,0x1
    800056e8:	7d7d                	lui	s10,0xfffff
    800056ea:	a481                	j	8000592a <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800056ec:	00003517          	auipc	a0,0x3
    800056f0:	09450513          	addi	a0,a0,148 # 80008780 <syscalls+0x2f0>
    800056f4:	ffffb097          	auipc	ra,0xffffb
    800056f8:	e4a080e7          	jalr	-438(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800056fc:	874a                	mv	a4,s2
    800056fe:	009c86bb          	addw	a3,s9,s1
    80005702:	4581                	li	a1,0
    80005704:	8556                	mv	a0,s5
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	78c080e7          	jalr	1932(ra) # 80003e92 <readi>
    8000570e:	2501                	sext.w	a0,a0
    80005710:	1aa91a63          	bne	s2,a0,800058c4 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005714:	009d84bb          	addw	s1,s11,s1
    80005718:	013d09bb          	addw	s3,s10,s3
    8000571c:	1f74f763          	bgeu	s1,s7,8000590a <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80005720:	02049593          	slli	a1,s1,0x20
    80005724:	9181                	srli	a1,a1,0x20
    80005726:	95e2                	add	a1,a1,s8
    80005728:	855a                	mv	a0,s6
    8000572a:	ffffc097          	auipc	ra,0xffffc
    8000572e:	932080e7          	jalr	-1742(ra) # 8000105c <walkaddr>
    80005732:	862a                	mv	a2,a0
    if(pa == 0)
    80005734:	dd45                	beqz	a0,800056ec <exec+0xfe>
      n = PGSIZE;
    80005736:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005738:	fd49f2e3          	bgeu	s3,s4,800056fc <exec+0x10e>
      n = sz - i;
    8000573c:	894e                	mv	s2,s3
    8000573e:	bf7d                	j	800056fc <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005740:	4901                	li	s2,0
  iunlockput(ip);
    80005742:	8556                	mv	a0,s5
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	6fc080e7          	jalr	1788(ra) # 80003e40 <iunlockput>
  end_op();
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	1e6080e7          	jalr	486(ra) # 80004932 <end_op>
  p = myproc();
    80005754:	ffffc097          	auipc	ra,0xffffc
    80005758:	7d4080e7          	jalr	2004(ra) # 80001f28 <myproc>
    8000575c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000575e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005762:	6785                	lui	a5,0x1
    80005764:	17fd                	addi	a5,a5,-1
    80005766:	993e                	add	s2,s2,a5
    80005768:	77fd                	lui	a5,0xfffff
    8000576a:	00f977b3          	and	a5,s2,a5
    8000576e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005772:	4691                	li	a3,4
    80005774:	6609                	lui	a2,0x2
    80005776:	963e                	add	a2,a2,a5
    80005778:	85be                	mv	a1,a5
    8000577a:	855a                	mv	a0,s6
    8000577c:	ffffc097          	auipc	ra,0xffffc
    80005780:	c9c080e7          	jalr	-868(ra) # 80001418 <uvmalloc>
    80005784:	8c2a                	mv	s8,a0
  ip = 0;
    80005786:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005788:	12050e63          	beqz	a0,800058c4 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000578c:	75f9                	lui	a1,0xffffe
    8000578e:	95aa                	add	a1,a1,a0
    80005790:	855a                	mv	a0,s6
    80005792:	ffffc097          	auipc	ra,0xffffc
    80005796:	eac080e7          	jalr	-340(ra) # 8000163e <uvmclear>
  stackbase = sp - PGSIZE;
    8000579a:	7afd                	lui	s5,0xfffff
    8000579c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000579e:	df043783          	ld	a5,-528(s0)
    800057a2:	6388                	ld	a0,0(a5)
    800057a4:	c925                	beqz	a0,80005814 <exec+0x226>
    800057a6:	e9040993          	addi	s3,s0,-368
    800057aa:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800057ae:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800057b0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800057b2:	ffffb097          	auipc	ra,0xffffb
    800057b6:	69c080e7          	jalr	1692(ra) # 80000e4e <strlen>
    800057ba:	0015079b          	addiw	a5,a0,1
    800057be:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800057c2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800057c6:	13596663          	bltu	s2,s5,800058f2 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800057ca:	df043d83          	ld	s11,-528(s0)
    800057ce:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800057d2:	8552                	mv	a0,s4
    800057d4:	ffffb097          	auipc	ra,0xffffb
    800057d8:	67a080e7          	jalr	1658(ra) # 80000e4e <strlen>
    800057dc:	0015069b          	addiw	a3,a0,1
    800057e0:	8652                	mv	a2,s4
    800057e2:	85ca                	mv	a1,s2
    800057e4:	855a                	mv	a0,s6
    800057e6:	ffffc097          	auipc	ra,0xffffc
    800057ea:	e8a080e7          	jalr	-374(ra) # 80001670 <copyout>
    800057ee:	10054663          	bltz	a0,800058fa <exec+0x30c>
    ustack[argc] = sp;
    800057f2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800057f6:	0485                	addi	s1,s1,1
    800057f8:	008d8793          	addi	a5,s11,8
    800057fc:	def43823          	sd	a5,-528(s0)
    80005800:	008db503          	ld	a0,8(s11)
    80005804:	c911                	beqz	a0,80005818 <exec+0x22a>
    if(argc >= MAXARG)
    80005806:	09a1                	addi	s3,s3,8
    80005808:	fb3c95e3          	bne	s9,s3,800057b2 <exec+0x1c4>
  sz = sz1;
    8000580c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005810:	4a81                	li	s5,0
    80005812:	a84d                	j	800058c4 <exec+0x2d6>
  sp = sz;
    80005814:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005816:	4481                	li	s1,0
  ustack[argc] = 0;
    80005818:	00349793          	slli	a5,s1,0x3
    8000581c:	f9040713          	addi	a4,s0,-112
    80005820:	97ba                	add	a5,a5,a4
    80005822:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffccb20>
  sp -= (argc+1) * sizeof(uint64);
    80005826:	00148693          	addi	a3,s1,1
    8000582a:	068e                	slli	a3,a3,0x3
    8000582c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005830:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005834:	01597663          	bgeu	s2,s5,80005840 <exec+0x252>
  sz = sz1;
    80005838:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000583c:	4a81                	li	s5,0
    8000583e:	a059                	j	800058c4 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005840:	e9040613          	addi	a2,s0,-368
    80005844:	85ca                	mv	a1,s2
    80005846:	855a                	mv	a0,s6
    80005848:	ffffc097          	auipc	ra,0xffffc
    8000584c:	e28080e7          	jalr	-472(ra) # 80001670 <copyout>
    80005850:	0a054963          	bltz	a0,80005902 <exec+0x314>
  p->trapframe->a1 = sp;
    80005854:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005858:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000585c:	de843783          	ld	a5,-536(s0)
    80005860:	0007c703          	lbu	a4,0(a5)
    80005864:	cf11                	beqz	a4,80005880 <exec+0x292>
    80005866:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005868:	02f00693          	li	a3,47
    8000586c:	a039                	j	8000587a <exec+0x28c>
      last = s+1;
    8000586e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005872:	0785                	addi	a5,a5,1
    80005874:	fff7c703          	lbu	a4,-1(a5)
    80005878:	c701                	beqz	a4,80005880 <exec+0x292>
    if(*s == '/')
    8000587a:	fed71ce3          	bne	a4,a3,80005872 <exec+0x284>
    8000587e:	bfc5                	j	8000586e <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005880:	4641                	li	a2,16
    80005882:	de843583          	ld	a1,-536(s0)
    80005886:	158b8513          	addi	a0,s7,344
    8000588a:	ffffb097          	auipc	ra,0xffffb
    8000588e:	592080e7          	jalr	1426(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005892:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005896:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000589a:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000589e:	058bb783          	ld	a5,88(s7)
    800058a2:	e6843703          	ld	a4,-408(s0)
    800058a6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800058a8:	058bb783          	ld	a5,88(s7)
    800058ac:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800058b0:	85ea                	mv	a1,s10
    800058b2:	ffffc097          	auipc	ra,0xffffc
    800058b6:	7d6080e7          	jalr	2006(ra) # 80002088 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800058ba:	0004851b          	sext.w	a0,s1
    800058be:	b3f1                	j	8000568a <exec+0x9c>
    800058c0:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800058c4:	df843583          	ld	a1,-520(s0)
    800058c8:	855a                	mv	a0,s6
    800058ca:	ffffc097          	auipc	ra,0xffffc
    800058ce:	7be080e7          	jalr	1982(ra) # 80002088 <proc_freepagetable>
  if(ip){
    800058d2:	da0a92e3          	bnez	s5,80005676 <exec+0x88>
  return -1;
    800058d6:	557d                	li	a0,-1
    800058d8:	bb4d                	j	8000568a <exec+0x9c>
    800058da:	df243c23          	sd	s2,-520(s0)
    800058de:	b7dd                	j	800058c4 <exec+0x2d6>
    800058e0:	df243c23          	sd	s2,-520(s0)
    800058e4:	b7c5                	j	800058c4 <exec+0x2d6>
    800058e6:	df243c23          	sd	s2,-520(s0)
    800058ea:	bfe9                	j	800058c4 <exec+0x2d6>
    800058ec:	df243c23          	sd	s2,-520(s0)
    800058f0:	bfd1                	j	800058c4 <exec+0x2d6>
  sz = sz1;
    800058f2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800058f6:	4a81                	li	s5,0
    800058f8:	b7f1                	j	800058c4 <exec+0x2d6>
  sz = sz1;
    800058fa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800058fe:	4a81                	li	s5,0
    80005900:	b7d1                	j	800058c4 <exec+0x2d6>
  sz = sz1;
    80005902:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005906:	4a81                	li	s5,0
    80005908:	bf75                	j	800058c4 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000590a:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000590e:	e0843783          	ld	a5,-504(s0)
    80005912:	0017869b          	addiw	a3,a5,1
    80005916:	e0d43423          	sd	a3,-504(s0)
    8000591a:	e0043783          	ld	a5,-512(s0)
    8000591e:	0387879b          	addiw	a5,a5,56
    80005922:	e8845703          	lhu	a4,-376(s0)
    80005926:	e0e6dee3          	bge	a3,a4,80005742 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000592a:	2781                	sext.w	a5,a5
    8000592c:	e0f43023          	sd	a5,-512(s0)
    80005930:	03800713          	li	a4,56
    80005934:	86be                	mv	a3,a5
    80005936:	e1840613          	addi	a2,s0,-488
    8000593a:	4581                	li	a1,0
    8000593c:	8556                	mv	a0,s5
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	554080e7          	jalr	1364(ra) # 80003e92 <readi>
    80005946:	03800793          	li	a5,56
    8000594a:	f6f51be3          	bne	a0,a5,800058c0 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000594e:	e1842783          	lw	a5,-488(s0)
    80005952:	4705                	li	a4,1
    80005954:	fae79de3          	bne	a5,a4,8000590e <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005958:	e4043483          	ld	s1,-448(s0)
    8000595c:	e3843783          	ld	a5,-456(s0)
    80005960:	f6f4ede3          	bltu	s1,a5,800058da <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005964:	e2843783          	ld	a5,-472(s0)
    80005968:	94be                	add	s1,s1,a5
    8000596a:	f6f4ebe3          	bltu	s1,a5,800058e0 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000596e:	de043703          	ld	a4,-544(s0)
    80005972:	8ff9                	and	a5,a5,a4
    80005974:	fbad                	bnez	a5,800058e6 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005976:	e1c42503          	lw	a0,-484(s0)
    8000597a:	00000097          	auipc	ra,0x0
    8000597e:	c58080e7          	jalr	-936(ra) # 800055d2 <flags2perm>
    80005982:	86aa                	mv	a3,a0
    80005984:	8626                	mv	a2,s1
    80005986:	85ca                	mv	a1,s2
    80005988:	855a                	mv	a0,s6
    8000598a:	ffffc097          	auipc	ra,0xffffc
    8000598e:	a8e080e7          	jalr	-1394(ra) # 80001418 <uvmalloc>
    80005992:	dea43c23          	sd	a0,-520(s0)
    80005996:	d939                	beqz	a0,800058ec <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005998:	e2843c03          	ld	s8,-472(s0)
    8000599c:	e2042c83          	lw	s9,-480(s0)
    800059a0:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800059a4:	f60b83e3          	beqz	s7,8000590a <exec+0x31c>
    800059a8:	89de                	mv	s3,s7
    800059aa:	4481                	li	s1,0
    800059ac:	bb95                	j	80005720 <exec+0x132>

00000000800059ae <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800059ae:	7179                	addi	sp,sp,-48
    800059b0:	f406                	sd	ra,40(sp)
    800059b2:	f022                	sd	s0,32(sp)
    800059b4:	ec26                	sd	s1,24(sp)
    800059b6:	e84a                	sd	s2,16(sp)
    800059b8:	1800                	addi	s0,sp,48
    800059ba:	892e                	mv	s2,a1
    800059bc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800059be:	fdc40593          	addi	a1,s0,-36
    800059c2:	ffffd097          	auipc	ra,0xffffd
    800059c6:	6b0080e7          	jalr	1712(ra) # 80003072 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800059ca:	fdc42703          	lw	a4,-36(s0)
    800059ce:	47bd                	li	a5,15
    800059d0:	02e7eb63          	bltu	a5,a4,80005a06 <argfd+0x58>
    800059d4:	ffffc097          	auipc	ra,0xffffc
    800059d8:	554080e7          	jalr	1364(ra) # 80001f28 <myproc>
    800059dc:	fdc42703          	lw	a4,-36(s0)
    800059e0:	01a70793          	addi	a5,a4,26
    800059e4:	078e                	slli	a5,a5,0x3
    800059e6:	953e                	add	a0,a0,a5
    800059e8:	611c                	ld	a5,0(a0)
    800059ea:	c385                	beqz	a5,80005a0a <argfd+0x5c>
    return -1;
  if(pfd)
    800059ec:	00090463          	beqz	s2,800059f4 <argfd+0x46>
    *pfd = fd;
    800059f0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800059f4:	4501                	li	a0,0
  if(pf)
    800059f6:	c091                	beqz	s1,800059fa <argfd+0x4c>
    *pf = f;
    800059f8:	e09c                	sd	a5,0(s1)
}
    800059fa:	70a2                	ld	ra,40(sp)
    800059fc:	7402                	ld	s0,32(sp)
    800059fe:	64e2                	ld	s1,24(sp)
    80005a00:	6942                	ld	s2,16(sp)
    80005a02:	6145                	addi	sp,sp,48
    80005a04:	8082                	ret
    return -1;
    80005a06:	557d                	li	a0,-1
    80005a08:	bfcd                	j	800059fa <argfd+0x4c>
    80005a0a:	557d                	li	a0,-1
    80005a0c:	b7fd                	j	800059fa <argfd+0x4c>

0000000080005a0e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005a0e:	1101                	addi	sp,sp,-32
    80005a10:	ec06                	sd	ra,24(sp)
    80005a12:	e822                	sd	s0,16(sp)
    80005a14:	e426                	sd	s1,8(sp)
    80005a16:	1000                	addi	s0,sp,32
    80005a18:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005a1a:	ffffc097          	auipc	ra,0xffffc
    80005a1e:	50e080e7          	jalr	1294(ra) # 80001f28 <myproc>
    80005a22:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005a24:	0d050793          	addi	a5,a0,208
    80005a28:	4501                	li	a0,0
    80005a2a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005a2c:	6398                	ld	a4,0(a5)
    80005a2e:	cb19                	beqz	a4,80005a44 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005a30:	2505                	addiw	a0,a0,1
    80005a32:	07a1                	addi	a5,a5,8
    80005a34:	fed51ce3          	bne	a0,a3,80005a2c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005a38:	557d                	li	a0,-1
}
    80005a3a:	60e2                	ld	ra,24(sp)
    80005a3c:	6442                	ld	s0,16(sp)
    80005a3e:	64a2                	ld	s1,8(sp)
    80005a40:	6105                	addi	sp,sp,32
    80005a42:	8082                	ret
      p->ofile[fd] = f;
    80005a44:	01a50793          	addi	a5,a0,26
    80005a48:	078e                	slli	a5,a5,0x3
    80005a4a:	963e                	add	a2,a2,a5
    80005a4c:	e204                	sd	s1,0(a2)
      return fd;
    80005a4e:	b7f5                	j	80005a3a <fdalloc+0x2c>

0000000080005a50 <sys_dup>:

uint64
sys_dup(void)
{
    80005a50:	7179                	addi	sp,sp,-48
    80005a52:	f406                	sd	ra,40(sp)
    80005a54:	f022                	sd	s0,32(sp)
    80005a56:	ec26                	sd	s1,24(sp)
    80005a58:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005a5a:	fd840613          	addi	a2,s0,-40
    80005a5e:	4581                	li	a1,0
    80005a60:	4501                	li	a0,0
    80005a62:	00000097          	auipc	ra,0x0
    80005a66:	f4c080e7          	jalr	-180(ra) # 800059ae <argfd>
    return -1;
    80005a6a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a6c:	02054363          	bltz	a0,80005a92 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005a70:	fd843503          	ld	a0,-40(s0)
    80005a74:	00000097          	auipc	ra,0x0
    80005a78:	f9a080e7          	jalr	-102(ra) # 80005a0e <fdalloc>
    80005a7c:	84aa                	mv	s1,a0
    return -1;
    80005a7e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a80:	00054963          	bltz	a0,80005a92 <sys_dup+0x42>
  filedup(f);
    80005a84:	fd843503          	ld	a0,-40(s0)
    80005a88:	fffff097          	auipc	ra,0xfffff
    80005a8c:	2a4080e7          	jalr	676(ra) # 80004d2c <filedup>
  return fd;
    80005a90:	87a6                	mv	a5,s1
}
    80005a92:	853e                	mv	a0,a5
    80005a94:	70a2                	ld	ra,40(sp)
    80005a96:	7402                	ld	s0,32(sp)
    80005a98:	64e2                	ld	s1,24(sp)
    80005a9a:	6145                	addi	sp,sp,48
    80005a9c:	8082                	ret

0000000080005a9e <sys_read>:

uint64
sys_read(void)
{
    80005a9e:	7179                	addi	sp,sp,-48
    80005aa0:	f406                	sd	ra,40(sp)
    80005aa2:	f022                	sd	s0,32(sp)
    80005aa4:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  argaddr(1, &p);
    80005aa6:	fd840593          	addi	a1,s0,-40
    80005aaa:	4505                	li	a0,1
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	5e6080e7          	jalr	1510(ra) # 80003092 <argaddr>
  argint(2, &n);
    80005ab4:	fe440593          	addi	a1,s0,-28
    80005ab8:	4509                	li	a0,2
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	5b8080e7          	jalr	1464(ra) # 80003072 <argint>
  if(argfd(0, 0, &f) < 0)
    80005ac2:	fe840613          	addi	a2,s0,-24
    80005ac6:	4581                	li	a1,0
    80005ac8:	4501                	li	a0,0
    80005aca:	00000097          	auipc	ra,0x0
    80005ace:	ee4080e7          	jalr	-284(ra) # 800059ae <argfd>
    80005ad2:	87aa                	mv	a5,a0
    return -1;
    80005ad4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ad6:	0007cc63          	bltz	a5,80005aee <sys_read+0x50>
  return fileread(f, p, n);
    80005ada:	fe442603          	lw	a2,-28(s0)
    80005ade:	fd843583          	ld	a1,-40(s0)
    80005ae2:	fe843503          	ld	a0,-24(s0)
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	3d2080e7          	jalr	978(ra) # 80004eb8 <fileread>
}
    80005aee:	70a2                	ld	ra,40(sp)
    80005af0:	7402                	ld	s0,32(sp)
    80005af2:	6145                	addi	sp,sp,48
    80005af4:	8082                	ret

0000000080005af6 <sys_write>:

uint64
sys_write(void)
{
    80005af6:	7179                	addi	sp,sp,-48
    80005af8:	f406                	sd	ra,40(sp)
    80005afa:	f022                	sd	s0,32(sp)
    80005afc:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;
  
  argaddr(1, &p);
    80005afe:	fd840593          	addi	a1,s0,-40
    80005b02:	4505                	li	a0,1
    80005b04:	ffffd097          	auipc	ra,0xffffd
    80005b08:	58e080e7          	jalr	1422(ra) # 80003092 <argaddr>
  argint(2, &n);
    80005b0c:	fe440593          	addi	a1,s0,-28
    80005b10:	4509                	li	a0,2
    80005b12:	ffffd097          	auipc	ra,0xffffd
    80005b16:	560080e7          	jalr	1376(ra) # 80003072 <argint>
  if(argfd(0, 0, &f) < 0)
    80005b1a:	fe840613          	addi	a2,s0,-24
    80005b1e:	4581                	li	a1,0
    80005b20:	4501                	li	a0,0
    80005b22:	00000097          	auipc	ra,0x0
    80005b26:	e8c080e7          	jalr	-372(ra) # 800059ae <argfd>
    80005b2a:	87aa                	mv	a5,a0
    return -1;
    80005b2c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b2e:	0007cc63          	bltz	a5,80005b46 <sys_write+0x50>

  return filewrite(f, p, n);
    80005b32:	fe442603          	lw	a2,-28(s0)
    80005b36:	fd843583          	ld	a1,-40(s0)
    80005b3a:	fe843503          	ld	a0,-24(s0)
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	43c080e7          	jalr	1084(ra) # 80004f7a <filewrite>
}
    80005b46:	70a2                	ld	ra,40(sp)
    80005b48:	7402                	ld	s0,32(sp)
    80005b4a:	6145                	addi	sp,sp,48
    80005b4c:	8082                	ret

0000000080005b4e <sys_close>:

uint64
sys_close(void)
{
    80005b4e:	1101                	addi	sp,sp,-32
    80005b50:	ec06                	sd	ra,24(sp)
    80005b52:	e822                	sd	s0,16(sp)
    80005b54:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005b56:	fe040613          	addi	a2,s0,-32
    80005b5a:	fec40593          	addi	a1,s0,-20
    80005b5e:	4501                	li	a0,0
    80005b60:	00000097          	auipc	ra,0x0
    80005b64:	e4e080e7          	jalr	-434(ra) # 800059ae <argfd>
    return -1;
    80005b68:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b6a:	02054463          	bltz	a0,80005b92 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005b6e:	ffffc097          	auipc	ra,0xffffc
    80005b72:	3ba080e7          	jalr	954(ra) # 80001f28 <myproc>
    80005b76:	fec42783          	lw	a5,-20(s0)
    80005b7a:	07e9                	addi	a5,a5,26
    80005b7c:	078e                	slli	a5,a5,0x3
    80005b7e:	97aa                	add	a5,a5,a0
    80005b80:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005b84:	fe043503          	ld	a0,-32(s0)
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	1f6080e7          	jalr	502(ra) # 80004d7e <fileclose>
  return 0;
    80005b90:	4781                	li	a5,0
}
    80005b92:	853e                	mv	a0,a5
    80005b94:	60e2                	ld	ra,24(sp)
    80005b96:	6442                	ld	s0,16(sp)
    80005b98:	6105                	addi	sp,sp,32
    80005b9a:	8082                	ret

0000000080005b9c <sys_fstat>:

uint64
sys_fstat(void)
{
    80005b9c:	1101                	addi	sp,sp,-32
    80005b9e:	ec06                	sd	ra,24(sp)
    80005ba0:	e822                	sd	s0,16(sp)
    80005ba2:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  argaddr(1, &st);
    80005ba4:	fe040593          	addi	a1,s0,-32
    80005ba8:	4505                	li	a0,1
    80005baa:	ffffd097          	auipc	ra,0xffffd
    80005bae:	4e8080e7          	jalr	1256(ra) # 80003092 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005bb2:	fe840613          	addi	a2,s0,-24
    80005bb6:	4581                	li	a1,0
    80005bb8:	4501                	li	a0,0
    80005bba:	00000097          	auipc	ra,0x0
    80005bbe:	df4080e7          	jalr	-524(ra) # 800059ae <argfd>
    80005bc2:	87aa                	mv	a5,a0
    return -1;
    80005bc4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005bc6:	0007ca63          	bltz	a5,80005bda <sys_fstat+0x3e>
  return filestat(f, st);
    80005bca:	fe043583          	ld	a1,-32(s0)
    80005bce:	fe843503          	ld	a0,-24(s0)
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	274080e7          	jalr	628(ra) # 80004e46 <filestat>
}
    80005bda:	60e2                	ld	ra,24(sp)
    80005bdc:	6442                	ld	s0,16(sp)
    80005bde:	6105                	addi	sp,sp,32
    80005be0:	8082                	ret

0000000080005be2 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005be2:	7169                	addi	sp,sp,-304
    80005be4:	f606                	sd	ra,296(sp)
    80005be6:	f222                	sd	s0,288(sp)
    80005be8:	ee26                	sd	s1,280(sp)
    80005bea:	ea4a                	sd	s2,272(sp)
    80005bec:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bee:	08000613          	li	a2,128
    80005bf2:	ed040593          	addi	a1,s0,-304
    80005bf6:	4501                	li	a0,0
    80005bf8:	ffffd097          	auipc	ra,0xffffd
    80005bfc:	4ba080e7          	jalr	1210(ra) # 800030b2 <argstr>
    return -1;
    80005c00:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c02:	10054e63          	bltz	a0,80005d1e <sys_link+0x13c>
    80005c06:	08000613          	li	a2,128
    80005c0a:	f5040593          	addi	a1,s0,-176
    80005c0e:	4505                	li	a0,1
    80005c10:	ffffd097          	auipc	ra,0xffffd
    80005c14:	4a2080e7          	jalr	1186(ra) # 800030b2 <argstr>
    return -1;
    80005c18:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c1a:	10054263          	bltz	a0,80005d1e <sys_link+0x13c>

  begin_op();
    80005c1e:	fffff097          	auipc	ra,0xfffff
    80005c22:	c94080e7          	jalr	-876(ra) # 800048b2 <begin_op>
  if((ip = namei(old)) == 0){
    80005c26:	ed040513          	addi	a0,s0,-304
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	75a080e7          	jalr	1882(ra) # 80004384 <namei>
    80005c32:	84aa                	mv	s1,a0
    80005c34:	c551                	beqz	a0,80005cc0 <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	fa8080e7          	jalr	-88(ra) # 80003bde <ilock>
  if(ip->type == T_DIR){
    80005c3e:	04449703          	lh	a4,68(s1)
    80005c42:	4785                	li	a5,1
    80005c44:	08f70463          	beq	a4,a5,80005ccc <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005c48:	04a4d783          	lhu	a5,74(s1)
    80005c4c:	2785                	addiw	a5,a5,1
    80005c4e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c52:	8526                	mv	a0,s1
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	ec0080e7          	jalr	-320(ra) # 80003b14 <iupdate>
  iunlock(ip);
    80005c5c:	8526                	mv	a0,s1
    80005c5e:	ffffe097          	auipc	ra,0xffffe
    80005c62:	042080e7          	jalr	66(ra) # 80003ca0 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005c66:	fd040593          	addi	a1,s0,-48
    80005c6a:	f5040513          	addi	a0,s0,-176
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	734080e7          	jalr	1844(ra) # 800043a2 <nameiparent>
    80005c76:	892a                	mv	s2,a0
    80005c78:	c935                	beqz	a0,80005cec <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	f64080e7          	jalr	-156(ra) # 80003bde <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c82:	00092703          	lw	a4,0(s2)
    80005c86:	409c                	lw	a5,0(s1)
    80005c88:	04f71d63          	bne	a4,a5,80005ce2 <sys_link+0x100>
    80005c8c:	40d0                	lw	a2,4(s1)
    80005c8e:	fd040593          	addi	a1,s0,-48
    80005c92:	854a                	mv	a0,s2
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	63e080e7          	jalr	1598(ra) # 800042d2 <dirlink>
    80005c9c:	04054363          	bltz	a0,80005ce2 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005ca0:	854a                	mv	a0,s2
    80005ca2:	ffffe097          	auipc	ra,0xffffe
    80005ca6:	19e080e7          	jalr	414(ra) # 80003e40 <iunlockput>
  iput(ip);
    80005caa:	8526                	mv	a0,s1
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	0ec080e7          	jalr	236(ra) # 80003d98 <iput>

  end_op();
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	c7e080e7          	jalr	-898(ra) # 80004932 <end_op>

  return 0;
    80005cbc:	4781                	li	a5,0
    80005cbe:	a085                	j	80005d1e <sys_link+0x13c>
    end_op();
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	c72080e7          	jalr	-910(ra) # 80004932 <end_op>
    return -1;
    80005cc8:	57fd                	li	a5,-1
    80005cca:	a891                	j	80005d1e <sys_link+0x13c>
    iunlockput(ip);
    80005ccc:	8526                	mv	a0,s1
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	172080e7          	jalr	370(ra) # 80003e40 <iunlockput>
    end_op();
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	c5c080e7          	jalr	-932(ra) # 80004932 <end_op>
    return -1;
    80005cde:	57fd                	li	a5,-1
    80005ce0:	a83d                	j	80005d1e <sys_link+0x13c>
    iunlockput(dp);
    80005ce2:	854a                	mv	a0,s2
    80005ce4:	ffffe097          	auipc	ra,0xffffe
    80005ce8:	15c080e7          	jalr	348(ra) # 80003e40 <iunlockput>

bad:
  ilock(ip);
    80005cec:	8526                	mv	a0,s1
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	ef0080e7          	jalr	-272(ra) # 80003bde <ilock>
  ip->nlink--;
    80005cf6:	04a4d783          	lhu	a5,74(s1)
    80005cfa:	37fd                	addiw	a5,a5,-1
    80005cfc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d00:	8526                	mv	a0,s1
    80005d02:	ffffe097          	auipc	ra,0xffffe
    80005d06:	e12080e7          	jalr	-494(ra) # 80003b14 <iupdate>
  iunlockput(ip);
    80005d0a:	8526                	mv	a0,s1
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	134080e7          	jalr	308(ra) # 80003e40 <iunlockput>
  end_op();
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	c1e080e7          	jalr	-994(ra) # 80004932 <end_op>
  return -1;
    80005d1c:	57fd                	li	a5,-1
}
    80005d1e:	853e                	mv	a0,a5
    80005d20:	70b2                	ld	ra,296(sp)
    80005d22:	7412                	ld	s0,288(sp)
    80005d24:	64f2                	ld	s1,280(sp)
    80005d26:	6952                	ld	s2,272(sp)
    80005d28:	6155                	addi	sp,sp,304
    80005d2a:	8082                	ret

0000000080005d2c <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d2c:	4578                	lw	a4,76(a0)
    80005d2e:	02000793          	li	a5,32
    80005d32:	04e7fa63          	bgeu	a5,a4,80005d86 <isdirempty+0x5a>
{
    80005d36:	7179                	addi	sp,sp,-48
    80005d38:	f406                	sd	ra,40(sp)
    80005d3a:	f022                	sd	s0,32(sp)
    80005d3c:	ec26                	sd	s1,24(sp)
    80005d3e:	e84a                	sd	s2,16(sp)
    80005d40:	1800                	addi	s0,sp,48
    80005d42:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d44:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d48:	4741                	li	a4,16
    80005d4a:	86a6                	mv	a3,s1
    80005d4c:	fd040613          	addi	a2,s0,-48
    80005d50:	4581                	li	a1,0
    80005d52:	854a                	mv	a0,s2
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	13e080e7          	jalr	318(ra) # 80003e92 <readi>
    80005d5c:	47c1                	li	a5,16
    80005d5e:	00f51c63          	bne	a0,a5,80005d76 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80005d62:	fd045783          	lhu	a5,-48(s0)
    80005d66:	e395                	bnez	a5,80005d8a <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d68:	24c1                	addiw	s1,s1,16
    80005d6a:	04c92783          	lw	a5,76(s2)
    80005d6e:	fcf4ede3          	bltu	s1,a5,80005d48 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80005d72:	4505                	li	a0,1
    80005d74:	a821                	j	80005d8c <isdirempty+0x60>
      panic("isdirempty: readi");
    80005d76:	00003517          	auipc	a0,0x3
    80005d7a:	a2a50513          	addi	a0,a0,-1494 # 800087a0 <syscalls+0x310>
    80005d7e:	ffffa097          	auipc	ra,0xffffa
    80005d82:	7c0080e7          	jalr	1984(ra) # 8000053e <panic>
  return 1;
    80005d86:	4505                	li	a0,1
}
    80005d88:	8082                	ret
      return 0;
    80005d8a:	4501                	li	a0,0
}
    80005d8c:	70a2                	ld	ra,40(sp)
    80005d8e:	7402                	ld	s0,32(sp)
    80005d90:	64e2                	ld	s1,24(sp)
    80005d92:	6942                	ld	s2,16(sp)
    80005d94:	6145                	addi	sp,sp,48
    80005d96:	8082                	ret

0000000080005d98 <sys_unlink>:

uint64
sys_unlink(void)
{
    80005d98:	7155                	addi	sp,sp,-208
    80005d9a:	e586                	sd	ra,200(sp)
    80005d9c:	e1a2                	sd	s0,192(sp)
    80005d9e:	fd26                	sd	s1,184(sp)
    80005da0:	f94a                	sd	s2,176(sp)
    80005da2:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80005da4:	08000613          	li	a2,128
    80005da8:	f4040593          	addi	a1,s0,-192
    80005dac:	4501                	li	a0,0
    80005dae:	ffffd097          	auipc	ra,0xffffd
    80005db2:	304080e7          	jalr	772(ra) # 800030b2 <argstr>
    80005db6:	16054363          	bltz	a0,80005f1c <sys_unlink+0x184>
    return -1;

  begin_op();
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	af8080e7          	jalr	-1288(ra) # 800048b2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005dc2:	fc040593          	addi	a1,s0,-64
    80005dc6:	f4040513          	addi	a0,s0,-192
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	5d8080e7          	jalr	1496(ra) # 800043a2 <nameiparent>
    80005dd2:	84aa                	mv	s1,a0
    80005dd4:	c961                	beqz	a0,80005ea4 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80005dd6:	ffffe097          	auipc	ra,0xffffe
    80005dda:	e08080e7          	jalr	-504(ra) # 80003bde <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005dde:	00003597          	auipc	a1,0x3
    80005de2:	8a258593          	addi	a1,a1,-1886 # 80008680 <syscalls+0x1f0>
    80005de6:	fc040513          	addi	a0,s0,-64
    80005dea:	ffffe097          	auipc	ra,0xffffe
    80005dee:	2be080e7          	jalr	702(ra) # 800040a8 <namecmp>
    80005df2:	c175                	beqz	a0,80005ed6 <sys_unlink+0x13e>
    80005df4:	00003597          	auipc	a1,0x3
    80005df8:	89458593          	addi	a1,a1,-1900 # 80008688 <syscalls+0x1f8>
    80005dfc:	fc040513          	addi	a0,s0,-64
    80005e00:	ffffe097          	auipc	ra,0xffffe
    80005e04:	2a8080e7          	jalr	680(ra) # 800040a8 <namecmp>
    80005e08:	c579                	beqz	a0,80005ed6 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80005e0a:	f3c40613          	addi	a2,s0,-196
    80005e0e:	fc040593          	addi	a1,s0,-64
    80005e12:	8526                	mv	a0,s1
    80005e14:	ffffe097          	auipc	ra,0xffffe
    80005e18:	2ae080e7          	jalr	686(ra) # 800040c2 <dirlookup>
    80005e1c:	892a                	mv	s2,a0
    80005e1e:	cd45                	beqz	a0,80005ed6 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	dbe080e7          	jalr	-578(ra) # 80003bde <ilock>

  if(ip->nlink < 1)
    80005e28:	04a91783          	lh	a5,74(s2)
    80005e2c:	08f05263          	blez	a5,80005eb0 <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005e30:	04491703          	lh	a4,68(s2)
    80005e34:	4785                	li	a5,1
    80005e36:	08f70563          	beq	a4,a5,80005ec0 <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80005e3a:	4641                	li	a2,16
    80005e3c:	4581                	li	a1,0
    80005e3e:	fd040513          	addi	a0,s0,-48
    80005e42:	ffffb097          	auipc	ra,0xffffb
    80005e46:	e90080e7          	jalr	-368(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e4a:	4741                	li	a4,16
    80005e4c:	f3c42683          	lw	a3,-196(s0)
    80005e50:	fd040613          	addi	a2,s0,-48
    80005e54:	4581                	li	a1,0
    80005e56:	8526                	mv	a0,s1
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	132080e7          	jalr	306(ra) # 80003f8a <writei>
    80005e60:	47c1                	li	a5,16
    80005e62:	08f51a63          	bne	a0,a5,80005ef6 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80005e66:	04491703          	lh	a4,68(s2)
    80005e6a:	4785                	li	a5,1
    80005e6c:	08f70d63          	beq	a4,a5,80005f06 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80005e70:	8526                	mv	a0,s1
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	fce080e7          	jalr	-50(ra) # 80003e40 <iunlockput>

  ip->nlink--;
    80005e7a:	04a95783          	lhu	a5,74(s2)
    80005e7e:	37fd                	addiw	a5,a5,-1
    80005e80:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005e84:	854a                	mv	a0,s2
    80005e86:	ffffe097          	auipc	ra,0xffffe
    80005e8a:	c8e080e7          	jalr	-882(ra) # 80003b14 <iupdate>
  iunlockput(ip);
    80005e8e:	854a                	mv	a0,s2
    80005e90:	ffffe097          	auipc	ra,0xffffe
    80005e94:	fb0080e7          	jalr	-80(ra) # 80003e40 <iunlockput>

  end_op();
    80005e98:	fffff097          	auipc	ra,0xfffff
    80005e9c:	a9a080e7          	jalr	-1382(ra) # 80004932 <end_op>

  return 0;
    80005ea0:	4501                	li	a0,0
    80005ea2:	a0a1                	j	80005eea <sys_unlink+0x152>
    end_op();
    80005ea4:	fffff097          	auipc	ra,0xfffff
    80005ea8:	a8e080e7          	jalr	-1394(ra) # 80004932 <end_op>
    return -1;
    80005eac:	557d                	li	a0,-1
    80005eae:	a835                	j	80005eea <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80005eb0:	00002517          	auipc	a0,0x2
    80005eb4:	7e050513          	addi	a0,a0,2016 # 80008690 <syscalls+0x200>
    80005eb8:	ffffa097          	auipc	ra,0xffffa
    80005ebc:	686080e7          	jalr	1670(ra) # 8000053e <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ec0:	854a                	mv	a0,s2
    80005ec2:	00000097          	auipc	ra,0x0
    80005ec6:	e6a080e7          	jalr	-406(ra) # 80005d2c <isdirempty>
    80005eca:	f925                	bnez	a0,80005e3a <sys_unlink+0xa2>
    iunlockput(ip);
    80005ecc:	854a                	mv	a0,s2
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	f72080e7          	jalr	-142(ra) # 80003e40 <iunlockput>

bad:
  iunlockput(dp);
    80005ed6:	8526                	mv	a0,s1
    80005ed8:	ffffe097          	auipc	ra,0xffffe
    80005edc:	f68080e7          	jalr	-152(ra) # 80003e40 <iunlockput>
  end_op();
    80005ee0:	fffff097          	auipc	ra,0xfffff
    80005ee4:	a52080e7          	jalr	-1454(ra) # 80004932 <end_op>
  return -1;
    80005ee8:	557d                	li	a0,-1
}
    80005eea:	60ae                	ld	ra,200(sp)
    80005eec:	640e                	ld	s0,192(sp)
    80005eee:	74ea                	ld	s1,184(sp)
    80005ef0:	794a                	ld	s2,176(sp)
    80005ef2:	6169                	addi	sp,sp,208
    80005ef4:	8082                	ret
    panic("unlink: writei");
    80005ef6:	00002517          	auipc	a0,0x2
    80005efa:	7b250513          	addi	a0,a0,1970 # 800086a8 <syscalls+0x218>
    80005efe:	ffffa097          	auipc	ra,0xffffa
    80005f02:	640080e7          	jalr	1600(ra) # 8000053e <panic>
    dp->nlink--;
    80005f06:	04a4d783          	lhu	a5,74(s1)
    80005f0a:	37fd                	addiw	a5,a5,-1
    80005f0c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005f10:	8526                	mv	a0,s1
    80005f12:	ffffe097          	auipc	ra,0xffffe
    80005f16:	c02080e7          	jalr	-1022(ra) # 80003b14 <iupdate>
    80005f1a:	bf99                	j	80005e70 <sys_unlink+0xd8>
    return -1;
    80005f1c:	557d                	li	a0,-1
    80005f1e:	b7f1                	j	80005eea <sys_unlink+0x152>

0000000080005f20 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80005f20:	715d                	addi	sp,sp,-80
    80005f22:	e486                	sd	ra,72(sp)
    80005f24:	e0a2                	sd	s0,64(sp)
    80005f26:	fc26                	sd	s1,56(sp)
    80005f28:	f84a                	sd	s2,48(sp)
    80005f2a:	f44e                	sd	s3,40(sp)
    80005f2c:	f052                	sd	s4,32(sp)
    80005f2e:	ec56                	sd	s5,24(sp)
    80005f30:	e85a                	sd	s6,16(sp)
    80005f32:	0880                	addi	s0,sp,80
    80005f34:	8b2e                	mv	s6,a1
    80005f36:	89b2                	mv	s3,a2
    80005f38:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005f3a:	fb040593          	addi	a1,s0,-80
    80005f3e:	ffffe097          	auipc	ra,0xffffe
    80005f42:	464080e7          	jalr	1124(ra) # 800043a2 <nameiparent>
    80005f46:	84aa                	mv	s1,a0
    80005f48:	14050f63          	beqz	a0,800060a6 <create+0x186>
    return 0;

  ilock(dp);
    80005f4c:	ffffe097          	auipc	ra,0xffffe
    80005f50:	c92080e7          	jalr	-878(ra) # 80003bde <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005f54:	4601                	li	a2,0
    80005f56:	fb040593          	addi	a1,s0,-80
    80005f5a:	8526                	mv	a0,s1
    80005f5c:	ffffe097          	auipc	ra,0xffffe
    80005f60:	166080e7          	jalr	358(ra) # 800040c2 <dirlookup>
    80005f64:	8aaa                	mv	s5,a0
    80005f66:	c931                	beqz	a0,80005fba <create+0x9a>
    iunlockput(dp);
    80005f68:	8526                	mv	a0,s1
    80005f6a:	ffffe097          	auipc	ra,0xffffe
    80005f6e:	ed6080e7          	jalr	-298(ra) # 80003e40 <iunlockput>
    ilock(ip);
    80005f72:	8556                	mv	a0,s5
    80005f74:	ffffe097          	auipc	ra,0xffffe
    80005f78:	c6a080e7          	jalr	-918(ra) # 80003bde <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005f7c:	000b059b          	sext.w	a1,s6
    80005f80:	4789                	li	a5,2
    80005f82:	02f59563          	bne	a1,a5,80005fac <create+0x8c>
    80005f86:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffccc64>
    80005f8a:	37f9                	addiw	a5,a5,-2
    80005f8c:	17c2                	slli	a5,a5,0x30
    80005f8e:	93c1                	srli	a5,a5,0x30
    80005f90:	4705                	li	a4,1
    80005f92:	00f76d63          	bltu	a4,a5,80005fac <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005f96:	8556                	mv	a0,s5
    80005f98:	60a6                	ld	ra,72(sp)
    80005f9a:	6406                	ld	s0,64(sp)
    80005f9c:	74e2                	ld	s1,56(sp)
    80005f9e:	7942                	ld	s2,48(sp)
    80005fa0:	79a2                	ld	s3,40(sp)
    80005fa2:	7a02                	ld	s4,32(sp)
    80005fa4:	6ae2                	ld	s5,24(sp)
    80005fa6:	6b42                	ld	s6,16(sp)
    80005fa8:	6161                	addi	sp,sp,80
    80005faa:	8082                	ret
    iunlockput(ip);
    80005fac:	8556                	mv	a0,s5
    80005fae:	ffffe097          	auipc	ra,0xffffe
    80005fb2:	e92080e7          	jalr	-366(ra) # 80003e40 <iunlockput>
    return 0;
    80005fb6:	4a81                	li	s5,0
    80005fb8:	bff9                	j	80005f96 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005fba:	85da                	mv	a1,s6
    80005fbc:	4088                	lw	a0,0(s1)
    80005fbe:	ffffe097          	auipc	ra,0xffffe
    80005fc2:	a84080e7          	jalr	-1404(ra) # 80003a42 <ialloc>
    80005fc6:	8a2a                	mv	s4,a0
    80005fc8:	c539                	beqz	a0,80006016 <create+0xf6>
  ilock(ip);
    80005fca:	ffffe097          	auipc	ra,0xffffe
    80005fce:	c14080e7          	jalr	-1004(ra) # 80003bde <ilock>
  ip->major = major;
    80005fd2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005fd6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005fda:	4905                	li	s2,1
    80005fdc:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005fe0:	8552                	mv	a0,s4
    80005fe2:	ffffe097          	auipc	ra,0xffffe
    80005fe6:	b32080e7          	jalr	-1230(ra) # 80003b14 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005fea:	000b059b          	sext.w	a1,s6
    80005fee:	03258b63          	beq	a1,s2,80006024 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005ff2:	004a2603          	lw	a2,4(s4)
    80005ff6:	fb040593          	addi	a1,s0,-80
    80005ffa:	8526                	mv	a0,s1
    80005ffc:	ffffe097          	auipc	ra,0xffffe
    80006000:	2d6080e7          	jalr	726(ra) # 800042d2 <dirlink>
    80006004:	06054f63          	bltz	a0,80006082 <create+0x162>
  iunlockput(dp);
    80006008:	8526                	mv	a0,s1
    8000600a:	ffffe097          	auipc	ra,0xffffe
    8000600e:	e36080e7          	jalr	-458(ra) # 80003e40 <iunlockput>
  return ip;
    80006012:	8ad2                	mv	s5,s4
    80006014:	b749                	j	80005f96 <create+0x76>
    iunlockput(dp);
    80006016:	8526                	mv	a0,s1
    80006018:	ffffe097          	auipc	ra,0xffffe
    8000601c:	e28080e7          	jalr	-472(ra) # 80003e40 <iunlockput>
    return 0;
    80006020:	8ad2                	mv	s5,s4
    80006022:	bf95                	j	80005f96 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006024:	004a2603          	lw	a2,4(s4)
    80006028:	00002597          	auipc	a1,0x2
    8000602c:	65858593          	addi	a1,a1,1624 # 80008680 <syscalls+0x1f0>
    80006030:	8552                	mv	a0,s4
    80006032:	ffffe097          	auipc	ra,0xffffe
    80006036:	2a0080e7          	jalr	672(ra) # 800042d2 <dirlink>
    8000603a:	04054463          	bltz	a0,80006082 <create+0x162>
    8000603e:	40d0                	lw	a2,4(s1)
    80006040:	00002597          	auipc	a1,0x2
    80006044:	64858593          	addi	a1,a1,1608 # 80008688 <syscalls+0x1f8>
    80006048:	8552                	mv	a0,s4
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	288080e7          	jalr	648(ra) # 800042d2 <dirlink>
    80006052:	02054863          	bltz	a0,80006082 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80006056:	004a2603          	lw	a2,4(s4)
    8000605a:	fb040593          	addi	a1,s0,-80
    8000605e:	8526                	mv	a0,s1
    80006060:	ffffe097          	auipc	ra,0xffffe
    80006064:	272080e7          	jalr	626(ra) # 800042d2 <dirlink>
    80006068:	00054d63          	bltz	a0,80006082 <create+0x162>
    dp->nlink++;  // for ".."
    8000606c:	04a4d783          	lhu	a5,74(s1)
    80006070:	2785                	addiw	a5,a5,1
    80006072:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006076:	8526                	mv	a0,s1
    80006078:	ffffe097          	auipc	ra,0xffffe
    8000607c:	a9c080e7          	jalr	-1380(ra) # 80003b14 <iupdate>
    80006080:	b761                	j	80006008 <create+0xe8>
  ip->nlink = 0;
    80006082:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80006086:	8552                	mv	a0,s4
    80006088:	ffffe097          	auipc	ra,0xffffe
    8000608c:	a8c080e7          	jalr	-1396(ra) # 80003b14 <iupdate>
  iunlockput(ip);
    80006090:	8552                	mv	a0,s4
    80006092:	ffffe097          	auipc	ra,0xffffe
    80006096:	dae080e7          	jalr	-594(ra) # 80003e40 <iunlockput>
  iunlockput(dp);
    8000609a:	8526                	mv	a0,s1
    8000609c:	ffffe097          	auipc	ra,0xffffe
    800060a0:	da4080e7          	jalr	-604(ra) # 80003e40 <iunlockput>
  return 0;
    800060a4:	bdcd                	j	80005f96 <create+0x76>
    return 0;
    800060a6:	8aaa                	mv	s5,a0
    800060a8:	b5fd                	j	80005f96 <create+0x76>

00000000800060aa <sys_open>:

uint64
sys_open(void)
{
    800060aa:	7131                	addi	sp,sp,-192
    800060ac:	fd06                	sd	ra,184(sp)
    800060ae:	f922                	sd	s0,176(sp)
    800060b0:	f526                	sd	s1,168(sp)
    800060b2:	f14a                	sd	s2,160(sp)
    800060b4:	ed4e                	sd	s3,152(sp)
    800060b6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800060b8:	f4c40593          	addi	a1,s0,-180
    800060bc:	4505                	li	a0,1
    800060be:	ffffd097          	auipc	ra,0xffffd
    800060c2:	fb4080e7          	jalr	-76(ra) # 80003072 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800060c6:	08000613          	li	a2,128
    800060ca:	f5040593          	addi	a1,s0,-176
    800060ce:	4501                	li	a0,0
    800060d0:	ffffd097          	auipc	ra,0xffffd
    800060d4:	fe2080e7          	jalr	-30(ra) # 800030b2 <argstr>
    800060d8:	87aa                	mv	a5,a0
    return -1;
    800060da:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800060dc:	0a07c963          	bltz	a5,8000618e <sys_open+0xe4>

  begin_op();
    800060e0:	ffffe097          	auipc	ra,0xffffe
    800060e4:	7d2080e7          	jalr	2002(ra) # 800048b2 <begin_op>

  if(omode & O_CREATE){
    800060e8:	f4c42783          	lw	a5,-180(s0)
    800060ec:	2007f793          	andi	a5,a5,512
    800060f0:	cfc5                	beqz	a5,800061a8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800060f2:	4681                	li	a3,0
    800060f4:	4601                	li	a2,0
    800060f6:	4589                	li	a1,2
    800060f8:	f5040513          	addi	a0,s0,-176
    800060fc:	00000097          	auipc	ra,0x0
    80006100:	e24080e7          	jalr	-476(ra) # 80005f20 <create>
    80006104:	84aa                	mv	s1,a0
    if(ip == 0){
    80006106:	c959                	beqz	a0,8000619c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006108:	04449703          	lh	a4,68(s1)
    8000610c:	478d                	li	a5,3
    8000610e:	00f71763          	bne	a4,a5,8000611c <sys_open+0x72>
    80006112:	0464d703          	lhu	a4,70(s1)
    80006116:	47a5                	li	a5,9
    80006118:	0ce7ed63          	bltu	a5,a4,800061f2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000611c:	fffff097          	auipc	ra,0xfffff
    80006120:	ba6080e7          	jalr	-1114(ra) # 80004cc2 <filealloc>
    80006124:	89aa                	mv	s3,a0
    80006126:	10050363          	beqz	a0,8000622c <sys_open+0x182>
    8000612a:	00000097          	auipc	ra,0x0
    8000612e:	8e4080e7          	jalr	-1820(ra) # 80005a0e <fdalloc>
    80006132:	892a                	mv	s2,a0
    80006134:	0e054763          	bltz	a0,80006222 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006138:	04449703          	lh	a4,68(s1)
    8000613c:	478d                	li	a5,3
    8000613e:	0cf70563          	beq	a4,a5,80006208 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006142:	4789                	li	a5,2
    80006144:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006148:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000614c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006150:	f4c42783          	lw	a5,-180(s0)
    80006154:	0017c713          	xori	a4,a5,1
    80006158:	8b05                	andi	a4,a4,1
    8000615a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000615e:	0037f713          	andi	a4,a5,3
    80006162:	00e03733          	snez	a4,a4
    80006166:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000616a:	4007f793          	andi	a5,a5,1024
    8000616e:	c791                	beqz	a5,8000617a <sys_open+0xd0>
    80006170:	04449703          	lh	a4,68(s1)
    80006174:	4789                	li	a5,2
    80006176:	0af70063          	beq	a4,a5,80006216 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000617a:	8526                	mv	a0,s1
    8000617c:	ffffe097          	auipc	ra,0xffffe
    80006180:	b24080e7          	jalr	-1244(ra) # 80003ca0 <iunlock>
  end_op();
    80006184:	ffffe097          	auipc	ra,0xffffe
    80006188:	7ae080e7          	jalr	1966(ra) # 80004932 <end_op>

  return fd;
    8000618c:	854a                	mv	a0,s2
}
    8000618e:	70ea                	ld	ra,184(sp)
    80006190:	744a                	ld	s0,176(sp)
    80006192:	74aa                	ld	s1,168(sp)
    80006194:	790a                	ld	s2,160(sp)
    80006196:	69ea                	ld	s3,152(sp)
    80006198:	6129                	addi	sp,sp,192
    8000619a:	8082                	ret
      end_op();
    8000619c:	ffffe097          	auipc	ra,0xffffe
    800061a0:	796080e7          	jalr	1942(ra) # 80004932 <end_op>
      return -1;
    800061a4:	557d                	li	a0,-1
    800061a6:	b7e5                	j	8000618e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800061a8:	f5040513          	addi	a0,s0,-176
    800061ac:	ffffe097          	auipc	ra,0xffffe
    800061b0:	1d8080e7          	jalr	472(ra) # 80004384 <namei>
    800061b4:	84aa                	mv	s1,a0
    800061b6:	c905                	beqz	a0,800061e6 <sys_open+0x13c>
    ilock(ip);
    800061b8:	ffffe097          	auipc	ra,0xffffe
    800061bc:	a26080e7          	jalr	-1498(ra) # 80003bde <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800061c0:	04449703          	lh	a4,68(s1)
    800061c4:	4785                	li	a5,1
    800061c6:	f4f711e3          	bne	a4,a5,80006108 <sys_open+0x5e>
    800061ca:	f4c42783          	lw	a5,-180(s0)
    800061ce:	d7b9                	beqz	a5,8000611c <sys_open+0x72>
      iunlockput(ip);
    800061d0:	8526                	mv	a0,s1
    800061d2:	ffffe097          	auipc	ra,0xffffe
    800061d6:	c6e080e7          	jalr	-914(ra) # 80003e40 <iunlockput>
      end_op();
    800061da:	ffffe097          	auipc	ra,0xffffe
    800061de:	758080e7          	jalr	1880(ra) # 80004932 <end_op>
      return -1;
    800061e2:	557d                	li	a0,-1
    800061e4:	b76d                	j	8000618e <sys_open+0xe4>
      end_op();
    800061e6:	ffffe097          	auipc	ra,0xffffe
    800061ea:	74c080e7          	jalr	1868(ra) # 80004932 <end_op>
      return -1;
    800061ee:	557d                	li	a0,-1
    800061f0:	bf79                	j	8000618e <sys_open+0xe4>
    iunlockput(ip);
    800061f2:	8526                	mv	a0,s1
    800061f4:	ffffe097          	auipc	ra,0xffffe
    800061f8:	c4c080e7          	jalr	-948(ra) # 80003e40 <iunlockput>
    end_op();
    800061fc:	ffffe097          	auipc	ra,0xffffe
    80006200:	736080e7          	jalr	1846(ra) # 80004932 <end_op>
    return -1;
    80006204:	557d                	li	a0,-1
    80006206:	b761                	j	8000618e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006208:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000620c:	04649783          	lh	a5,70(s1)
    80006210:	02f99223          	sh	a5,36(s3)
    80006214:	bf25                	j	8000614c <sys_open+0xa2>
    itrunc(ip);
    80006216:	8526                	mv	a0,s1
    80006218:	ffffe097          	auipc	ra,0xffffe
    8000621c:	ad4080e7          	jalr	-1324(ra) # 80003cec <itrunc>
    80006220:	bfa9                	j	8000617a <sys_open+0xd0>
      fileclose(f);
    80006222:	854e                	mv	a0,s3
    80006224:	fffff097          	auipc	ra,0xfffff
    80006228:	b5a080e7          	jalr	-1190(ra) # 80004d7e <fileclose>
    iunlockput(ip);
    8000622c:	8526                	mv	a0,s1
    8000622e:	ffffe097          	auipc	ra,0xffffe
    80006232:	c12080e7          	jalr	-1006(ra) # 80003e40 <iunlockput>
    end_op();
    80006236:	ffffe097          	auipc	ra,0xffffe
    8000623a:	6fc080e7          	jalr	1788(ra) # 80004932 <end_op>
    return -1;
    8000623e:	557d                	li	a0,-1
    80006240:	b7b9                	j	8000618e <sys_open+0xe4>

0000000080006242 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006242:	7175                	addi	sp,sp,-144
    80006244:	e506                	sd	ra,136(sp)
    80006246:	e122                	sd	s0,128(sp)
    80006248:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000624a:	ffffe097          	auipc	ra,0xffffe
    8000624e:	668080e7          	jalr	1640(ra) # 800048b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006252:	08000613          	li	a2,128
    80006256:	f7040593          	addi	a1,s0,-144
    8000625a:	4501                	li	a0,0
    8000625c:	ffffd097          	auipc	ra,0xffffd
    80006260:	e56080e7          	jalr	-426(ra) # 800030b2 <argstr>
    80006264:	02054963          	bltz	a0,80006296 <sys_mkdir+0x54>
    80006268:	4681                	li	a3,0
    8000626a:	4601                	li	a2,0
    8000626c:	4585                	li	a1,1
    8000626e:	f7040513          	addi	a0,s0,-144
    80006272:	00000097          	auipc	ra,0x0
    80006276:	cae080e7          	jalr	-850(ra) # 80005f20 <create>
    8000627a:	cd11                	beqz	a0,80006296 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000627c:	ffffe097          	auipc	ra,0xffffe
    80006280:	bc4080e7          	jalr	-1084(ra) # 80003e40 <iunlockput>
  end_op();
    80006284:	ffffe097          	auipc	ra,0xffffe
    80006288:	6ae080e7          	jalr	1710(ra) # 80004932 <end_op>
  return 0;
    8000628c:	4501                	li	a0,0
}
    8000628e:	60aa                	ld	ra,136(sp)
    80006290:	640a                	ld	s0,128(sp)
    80006292:	6149                	addi	sp,sp,144
    80006294:	8082                	ret
    end_op();
    80006296:	ffffe097          	auipc	ra,0xffffe
    8000629a:	69c080e7          	jalr	1692(ra) # 80004932 <end_op>
    return -1;
    8000629e:	557d                	li	a0,-1
    800062a0:	b7fd                	j	8000628e <sys_mkdir+0x4c>

00000000800062a2 <sys_mknod>:

uint64
sys_mknod(void)
{
    800062a2:	7135                	addi	sp,sp,-160
    800062a4:	ed06                	sd	ra,152(sp)
    800062a6:	e922                	sd	s0,144(sp)
    800062a8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800062aa:	ffffe097          	auipc	ra,0xffffe
    800062ae:	608080e7          	jalr	1544(ra) # 800048b2 <begin_op>
  argint(1, &major);
    800062b2:	f6c40593          	addi	a1,s0,-148
    800062b6:	4505                	li	a0,1
    800062b8:	ffffd097          	auipc	ra,0xffffd
    800062bc:	dba080e7          	jalr	-582(ra) # 80003072 <argint>
  argint(2, &minor);
    800062c0:	f6840593          	addi	a1,s0,-152
    800062c4:	4509                	li	a0,2
    800062c6:	ffffd097          	auipc	ra,0xffffd
    800062ca:	dac080e7          	jalr	-596(ra) # 80003072 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800062ce:	08000613          	li	a2,128
    800062d2:	f7040593          	addi	a1,s0,-144
    800062d6:	4501                	li	a0,0
    800062d8:	ffffd097          	auipc	ra,0xffffd
    800062dc:	dda080e7          	jalr	-550(ra) # 800030b2 <argstr>
    800062e0:	02054b63          	bltz	a0,80006316 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800062e4:	f6841683          	lh	a3,-152(s0)
    800062e8:	f6c41603          	lh	a2,-148(s0)
    800062ec:	458d                	li	a1,3
    800062ee:	f7040513          	addi	a0,s0,-144
    800062f2:	00000097          	auipc	ra,0x0
    800062f6:	c2e080e7          	jalr	-978(ra) # 80005f20 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800062fa:	cd11                	beqz	a0,80006316 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800062fc:	ffffe097          	auipc	ra,0xffffe
    80006300:	b44080e7          	jalr	-1212(ra) # 80003e40 <iunlockput>
  end_op();
    80006304:	ffffe097          	auipc	ra,0xffffe
    80006308:	62e080e7          	jalr	1582(ra) # 80004932 <end_op>
  return 0;
    8000630c:	4501                	li	a0,0
}
    8000630e:	60ea                	ld	ra,152(sp)
    80006310:	644a                	ld	s0,144(sp)
    80006312:	610d                	addi	sp,sp,160
    80006314:	8082                	ret
    end_op();
    80006316:	ffffe097          	auipc	ra,0xffffe
    8000631a:	61c080e7          	jalr	1564(ra) # 80004932 <end_op>
    return -1;
    8000631e:	557d                	li	a0,-1
    80006320:	b7fd                	j	8000630e <sys_mknod+0x6c>

0000000080006322 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006322:	7135                	addi	sp,sp,-160
    80006324:	ed06                	sd	ra,152(sp)
    80006326:	e922                	sd	s0,144(sp)
    80006328:	e526                	sd	s1,136(sp)
    8000632a:	e14a                	sd	s2,128(sp)
    8000632c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000632e:	ffffc097          	auipc	ra,0xffffc
    80006332:	bfa080e7          	jalr	-1030(ra) # 80001f28 <myproc>
    80006336:	892a                	mv	s2,a0
  
  begin_op();
    80006338:	ffffe097          	auipc	ra,0xffffe
    8000633c:	57a080e7          	jalr	1402(ra) # 800048b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006340:	08000613          	li	a2,128
    80006344:	f6040593          	addi	a1,s0,-160
    80006348:	4501                	li	a0,0
    8000634a:	ffffd097          	auipc	ra,0xffffd
    8000634e:	d68080e7          	jalr	-664(ra) # 800030b2 <argstr>
    80006352:	04054b63          	bltz	a0,800063a8 <sys_chdir+0x86>
    80006356:	f6040513          	addi	a0,s0,-160
    8000635a:	ffffe097          	auipc	ra,0xffffe
    8000635e:	02a080e7          	jalr	42(ra) # 80004384 <namei>
    80006362:	84aa                	mv	s1,a0
    80006364:	c131                	beqz	a0,800063a8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006366:	ffffe097          	auipc	ra,0xffffe
    8000636a:	878080e7          	jalr	-1928(ra) # 80003bde <ilock>
  if(ip->type != T_DIR){
    8000636e:	04449703          	lh	a4,68(s1)
    80006372:	4785                	li	a5,1
    80006374:	04f71063          	bne	a4,a5,800063b4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006378:	8526                	mv	a0,s1
    8000637a:	ffffe097          	auipc	ra,0xffffe
    8000637e:	926080e7          	jalr	-1754(ra) # 80003ca0 <iunlock>
  iput(p->cwd);
    80006382:	15093503          	ld	a0,336(s2)
    80006386:	ffffe097          	auipc	ra,0xffffe
    8000638a:	a12080e7          	jalr	-1518(ra) # 80003d98 <iput>
  end_op();
    8000638e:	ffffe097          	auipc	ra,0xffffe
    80006392:	5a4080e7          	jalr	1444(ra) # 80004932 <end_op>
  p->cwd = ip;
    80006396:	14993823          	sd	s1,336(s2)
  return 0;
    8000639a:	4501                	li	a0,0
}
    8000639c:	60ea                	ld	ra,152(sp)
    8000639e:	644a                	ld	s0,144(sp)
    800063a0:	64aa                	ld	s1,136(sp)
    800063a2:	690a                	ld	s2,128(sp)
    800063a4:	610d                	addi	sp,sp,160
    800063a6:	8082                	ret
    end_op();
    800063a8:	ffffe097          	auipc	ra,0xffffe
    800063ac:	58a080e7          	jalr	1418(ra) # 80004932 <end_op>
    return -1;
    800063b0:	557d                	li	a0,-1
    800063b2:	b7ed                	j	8000639c <sys_chdir+0x7a>
    iunlockput(ip);
    800063b4:	8526                	mv	a0,s1
    800063b6:	ffffe097          	auipc	ra,0xffffe
    800063ba:	a8a080e7          	jalr	-1398(ra) # 80003e40 <iunlockput>
    end_op();
    800063be:	ffffe097          	auipc	ra,0xffffe
    800063c2:	574080e7          	jalr	1396(ra) # 80004932 <end_op>
    return -1;
    800063c6:	557d                	li	a0,-1
    800063c8:	bfd1                	j	8000639c <sys_chdir+0x7a>

00000000800063ca <sys_exec>:

uint64
sys_exec(void)
{
    800063ca:	7145                	addi	sp,sp,-464
    800063cc:	e786                	sd	ra,456(sp)
    800063ce:	e3a2                	sd	s0,448(sp)
    800063d0:	ff26                	sd	s1,440(sp)
    800063d2:	fb4a                	sd	s2,432(sp)
    800063d4:	f74e                	sd	s3,424(sp)
    800063d6:	f352                	sd	s4,416(sp)
    800063d8:	ef56                	sd	s5,408(sp)
    800063da:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800063dc:	e3840593          	addi	a1,s0,-456
    800063e0:	4505                	li	a0,1
    800063e2:	ffffd097          	auipc	ra,0xffffd
    800063e6:	cb0080e7          	jalr	-848(ra) # 80003092 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800063ea:	08000613          	li	a2,128
    800063ee:	f4040593          	addi	a1,s0,-192
    800063f2:	4501                	li	a0,0
    800063f4:	ffffd097          	auipc	ra,0xffffd
    800063f8:	cbe080e7          	jalr	-834(ra) # 800030b2 <argstr>
    800063fc:	87aa                	mv	a5,a0
    return -1;
    800063fe:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006400:	0c07c263          	bltz	a5,800064c4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006404:	10000613          	li	a2,256
    80006408:	4581                	li	a1,0
    8000640a:	e4040513          	addi	a0,s0,-448
    8000640e:	ffffb097          	auipc	ra,0xffffb
    80006412:	8c4080e7          	jalr	-1852(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006416:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000641a:	89a6                	mv	s3,s1
    8000641c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000641e:	02000a13          	li	s4,32
    80006422:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006426:	00391793          	slli	a5,s2,0x3
    8000642a:	e3040593          	addi	a1,s0,-464
    8000642e:	e3843503          	ld	a0,-456(s0)
    80006432:	953e                	add	a0,a0,a5
    80006434:	ffffd097          	auipc	ra,0xffffd
    80006438:	ba0080e7          	jalr	-1120(ra) # 80002fd4 <fetchaddr>
    8000643c:	02054a63          	bltz	a0,80006470 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006440:	e3043783          	ld	a5,-464(s0)
    80006444:	c3b9                	beqz	a5,8000648a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006446:	ffffa097          	auipc	ra,0xffffa
    8000644a:	6a0080e7          	jalr	1696(ra) # 80000ae6 <kalloc>
    8000644e:	85aa                	mv	a1,a0
    80006450:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006454:	cd11                	beqz	a0,80006470 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006456:	6605                	lui	a2,0x1
    80006458:	e3043503          	ld	a0,-464(s0)
    8000645c:	ffffd097          	auipc	ra,0xffffd
    80006460:	bca080e7          	jalr	-1078(ra) # 80003026 <fetchstr>
    80006464:	00054663          	bltz	a0,80006470 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006468:	0905                	addi	s2,s2,1
    8000646a:	09a1                	addi	s3,s3,8
    8000646c:	fb491be3          	bne	s2,s4,80006422 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006470:	10048913          	addi	s2,s1,256
    80006474:	6088                	ld	a0,0(s1)
    80006476:	c531                	beqz	a0,800064c2 <sys_exec+0xf8>
    kfree(argv[i]);
    80006478:	ffffa097          	auipc	ra,0xffffa
    8000647c:	572080e7          	jalr	1394(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006480:	04a1                	addi	s1,s1,8
    80006482:	ff2499e3          	bne	s1,s2,80006474 <sys_exec+0xaa>
  return -1;
    80006486:	557d                	li	a0,-1
    80006488:	a835                	j	800064c4 <sys_exec+0xfa>
      argv[i] = 0;
    8000648a:	0a8e                	slli	s5,s5,0x3
    8000648c:	fc040793          	addi	a5,s0,-64
    80006490:	9abe                	add	s5,s5,a5
    80006492:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006496:	e4040593          	addi	a1,s0,-448
    8000649a:	f4040513          	addi	a0,s0,-192
    8000649e:	fffff097          	auipc	ra,0xfffff
    800064a2:	150080e7          	jalr	336(ra) # 800055ee <exec>
    800064a6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064a8:	10048993          	addi	s3,s1,256
    800064ac:	6088                	ld	a0,0(s1)
    800064ae:	c901                	beqz	a0,800064be <sys_exec+0xf4>
    kfree(argv[i]);
    800064b0:	ffffa097          	auipc	ra,0xffffa
    800064b4:	53a080e7          	jalr	1338(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800064b8:	04a1                	addi	s1,s1,8
    800064ba:	ff3499e3          	bne	s1,s3,800064ac <sys_exec+0xe2>
  return ret;
    800064be:	854a                	mv	a0,s2
    800064c0:	a011                	j	800064c4 <sys_exec+0xfa>
  return -1;
    800064c2:	557d                	li	a0,-1
}
    800064c4:	60be                	ld	ra,456(sp)
    800064c6:	641e                	ld	s0,448(sp)
    800064c8:	74fa                	ld	s1,440(sp)
    800064ca:	795a                	ld	s2,432(sp)
    800064cc:	79ba                	ld	s3,424(sp)
    800064ce:	7a1a                	ld	s4,416(sp)
    800064d0:	6afa                	ld	s5,408(sp)
    800064d2:	6179                	addi	sp,sp,464
    800064d4:	8082                	ret

00000000800064d6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800064d6:	7139                	addi	sp,sp,-64
    800064d8:	fc06                	sd	ra,56(sp)
    800064da:	f822                	sd	s0,48(sp)
    800064dc:	f426                	sd	s1,40(sp)
    800064de:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800064e0:	ffffc097          	auipc	ra,0xffffc
    800064e4:	a48080e7          	jalr	-1464(ra) # 80001f28 <myproc>
    800064e8:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800064ea:	fd840593          	addi	a1,s0,-40
    800064ee:	4501                	li	a0,0
    800064f0:	ffffd097          	auipc	ra,0xffffd
    800064f4:	ba2080e7          	jalr	-1118(ra) # 80003092 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800064f8:	fc840593          	addi	a1,s0,-56
    800064fc:	fd040513          	addi	a0,s0,-48
    80006500:	fffff097          	auipc	ra,0xfffff
    80006504:	da4080e7          	jalr	-604(ra) # 800052a4 <pipealloc>
    return -1;
    80006508:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000650a:	0c054463          	bltz	a0,800065d2 <sys_pipe+0xfc>
  fd0 = -1;
    8000650e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006512:	fd043503          	ld	a0,-48(s0)
    80006516:	fffff097          	auipc	ra,0xfffff
    8000651a:	4f8080e7          	jalr	1272(ra) # 80005a0e <fdalloc>
    8000651e:	fca42223          	sw	a0,-60(s0)
    80006522:	08054b63          	bltz	a0,800065b8 <sys_pipe+0xe2>
    80006526:	fc843503          	ld	a0,-56(s0)
    8000652a:	fffff097          	auipc	ra,0xfffff
    8000652e:	4e4080e7          	jalr	1252(ra) # 80005a0e <fdalloc>
    80006532:	fca42023          	sw	a0,-64(s0)
    80006536:	06054863          	bltz	a0,800065a6 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000653a:	4691                	li	a3,4
    8000653c:	fc440613          	addi	a2,s0,-60
    80006540:	fd843583          	ld	a1,-40(s0)
    80006544:	68a8                	ld	a0,80(s1)
    80006546:	ffffb097          	auipc	ra,0xffffb
    8000654a:	12a080e7          	jalr	298(ra) # 80001670 <copyout>
    8000654e:	02054063          	bltz	a0,8000656e <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006552:	4691                	li	a3,4
    80006554:	fc040613          	addi	a2,s0,-64
    80006558:	fd843583          	ld	a1,-40(s0)
    8000655c:	0591                	addi	a1,a1,4
    8000655e:	68a8                	ld	a0,80(s1)
    80006560:	ffffb097          	auipc	ra,0xffffb
    80006564:	110080e7          	jalr	272(ra) # 80001670 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006568:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000656a:	06055463          	bgez	a0,800065d2 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000656e:	fc442783          	lw	a5,-60(s0)
    80006572:	07e9                	addi	a5,a5,26
    80006574:	078e                	slli	a5,a5,0x3
    80006576:	97a6                	add	a5,a5,s1
    80006578:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000657c:	fc042503          	lw	a0,-64(s0)
    80006580:	0569                	addi	a0,a0,26
    80006582:	050e                	slli	a0,a0,0x3
    80006584:	94aa                	add	s1,s1,a0
    80006586:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000658a:	fd043503          	ld	a0,-48(s0)
    8000658e:	ffffe097          	auipc	ra,0xffffe
    80006592:	7f0080e7          	jalr	2032(ra) # 80004d7e <fileclose>
    fileclose(wf);
    80006596:	fc843503          	ld	a0,-56(s0)
    8000659a:	ffffe097          	auipc	ra,0xffffe
    8000659e:	7e4080e7          	jalr	2020(ra) # 80004d7e <fileclose>
    return -1;
    800065a2:	57fd                	li	a5,-1
    800065a4:	a03d                	j	800065d2 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800065a6:	fc442783          	lw	a5,-60(s0)
    800065aa:	0007c763          	bltz	a5,800065b8 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800065ae:	07e9                	addi	a5,a5,26
    800065b0:	078e                	slli	a5,a5,0x3
    800065b2:	94be                	add	s1,s1,a5
    800065b4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800065b8:	fd043503          	ld	a0,-48(s0)
    800065bc:	ffffe097          	auipc	ra,0xffffe
    800065c0:	7c2080e7          	jalr	1986(ra) # 80004d7e <fileclose>
    fileclose(wf);
    800065c4:	fc843503          	ld	a0,-56(s0)
    800065c8:	ffffe097          	auipc	ra,0xffffe
    800065cc:	7b6080e7          	jalr	1974(ra) # 80004d7e <fileclose>
    return -1;
    800065d0:	57fd                	li	a5,-1
}
    800065d2:	853e                	mv	a0,a5
    800065d4:	70e2                	ld	ra,56(sp)
    800065d6:	7442                	ld	s0,48(sp)
    800065d8:	74a2                	ld	s1,40(sp)
    800065da:	6121                	addi	sp,sp,64
    800065dc:	8082                	ret
	...

00000000800065e0 <kernelvec>:
    800065e0:	7111                	addi	sp,sp,-256
    800065e2:	e006                	sd	ra,0(sp)
    800065e4:	e40a                	sd	sp,8(sp)
    800065e6:	e80e                	sd	gp,16(sp)
    800065e8:	ec12                	sd	tp,24(sp)
    800065ea:	f016                	sd	t0,32(sp)
    800065ec:	f41a                	sd	t1,40(sp)
    800065ee:	f81e                	sd	t2,48(sp)
    800065f0:	fc22                	sd	s0,56(sp)
    800065f2:	e0a6                	sd	s1,64(sp)
    800065f4:	e4aa                	sd	a0,72(sp)
    800065f6:	e8ae                	sd	a1,80(sp)
    800065f8:	ecb2                	sd	a2,88(sp)
    800065fa:	f0b6                	sd	a3,96(sp)
    800065fc:	f4ba                	sd	a4,104(sp)
    800065fe:	f8be                	sd	a5,112(sp)
    80006600:	fcc2                	sd	a6,120(sp)
    80006602:	e146                	sd	a7,128(sp)
    80006604:	e54a                	sd	s2,136(sp)
    80006606:	e94e                	sd	s3,144(sp)
    80006608:	ed52                	sd	s4,152(sp)
    8000660a:	f156                	sd	s5,160(sp)
    8000660c:	f55a                	sd	s6,168(sp)
    8000660e:	f95e                	sd	s7,176(sp)
    80006610:	fd62                	sd	s8,184(sp)
    80006612:	e1e6                	sd	s9,192(sp)
    80006614:	e5ea                	sd	s10,200(sp)
    80006616:	e9ee                	sd	s11,208(sp)
    80006618:	edf2                	sd	t3,216(sp)
    8000661a:	f1f6                	sd	t4,224(sp)
    8000661c:	f5fa                	sd	t5,232(sp)
    8000661e:	f9fe                	sd	t6,240(sp)
    80006620:	881fc0ef          	jal	ra,80002ea0 <kerneltrap>
    80006624:	6082                	ld	ra,0(sp)
    80006626:	6122                	ld	sp,8(sp)
    80006628:	61c2                	ld	gp,16(sp)
    8000662a:	7282                	ld	t0,32(sp)
    8000662c:	7322                	ld	t1,40(sp)
    8000662e:	73c2                	ld	t2,48(sp)
    80006630:	7462                	ld	s0,56(sp)
    80006632:	6486                	ld	s1,64(sp)
    80006634:	6526                	ld	a0,72(sp)
    80006636:	65c6                	ld	a1,80(sp)
    80006638:	6666                	ld	a2,88(sp)
    8000663a:	7686                	ld	a3,96(sp)
    8000663c:	7726                	ld	a4,104(sp)
    8000663e:	77c6                	ld	a5,112(sp)
    80006640:	7866                	ld	a6,120(sp)
    80006642:	688a                	ld	a7,128(sp)
    80006644:	692a                	ld	s2,136(sp)
    80006646:	69ca                	ld	s3,144(sp)
    80006648:	6a6a                	ld	s4,152(sp)
    8000664a:	7a8a                	ld	s5,160(sp)
    8000664c:	7b2a                	ld	s6,168(sp)
    8000664e:	7bca                	ld	s7,176(sp)
    80006650:	7c6a                	ld	s8,184(sp)
    80006652:	6c8e                	ld	s9,192(sp)
    80006654:	6d2e                	ld	s10,200(sp)
    80006656:	6dce                	ld	s11,208(sp)
    80006658:	6e6e                	ld	t3,216(sp)
    8000665a:	7e8e                	ld	t4,224(sp)
    8000665c:	7f2e                	ld	t5,232(sp)
    8000665e:	7fce                	ld	t6,240(sp)
    80006660:	6111                	addi	sp,sp,256
    80006662:	10200073          	sret
    80006666:	00000013          	nop
    8000666a:	00000013          	nop
    8000666e:	0001                	nop

0000000080006670 <timervec>:
    80006670:	34051573          	csrrw	a0,mscratch,a0
    80006674:	e10c                	sd	a1,0(a0)
    80006676:	e510                	sd	a2,8(a0)
    80006678:	e914                	sd	a3,16(a0)
    8000667a:	6d0c                	ld	a1,24(a0)
    8000667c:	7110                	ld	a2,32(a0)
    8000667e:	6194                	ld	a3,0(a1)
    80006680:	96b2                	add	a3,a3,a2
    80006682:	e194                	sd	a3,0(a1)
    80006684:	4589                	li	a1,2
    80006686:	14459073          	csrw	sip,a1
    8000668a:	6914                	ld	a3,16(a0)
    8000668c:	6510                	ld	a2,8(a0)
    8000668e:	610c                	ld	a1,0(a0)
    80006690:	34051573          	csrrw	a0,mscratch,a0
    80006694:	30200073          	mret
	...

000000008000669a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000669a:	1141                	addi	sp,sp,-16
    8000669c:	e422                	sd	s0,8(sp)
    8000669e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800066a0:	0c0007b7          	lui	a5,0xc000
    800066a4:	4705                	li	a4,1
    800066a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800066a8:	c3d8                	sw	a4,4(a5)
}
    800066aa:	6422                	ld	s0,8(sp)
    800066ac:	0141                	addi	sp,sp,16
    800066ae:	8082                	ret

00000000800066b0 <plicinithart>:

void
plicinithart(void)
{
    800066b0:	1141                	addi	sp,sp,-16
    800066b2:	e406                	sd	ra,8(sp)
    800066b4:	e022                	sd	s0,0(sp)
    800066b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800066b8:	ffffc097          	auipc	ra,0xffffc
    800066bc:	844080e7          	jalr	-1980(ra) # 80001efc <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800066c0:	0085171b          	slliw	a4,a0,0x8
    800066c4:	0c0027b7          	lui	a5,0xc002
    800066c8:	97ba                	add	a5,a5,a4
    800066ca:	40200713          	li	a4,1026
    800066ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800066d2:	00d5151b          	slliw	a0,a0,0xd
    800066d6:	0c2017b7          	lui	a5,0xc201
    800066da:	953e                	add	a0,a0,a5
    800066dc:	00052023          	sw	zero,0(a0)
}
    800066e0:	60a2                	ld	ra,8(sp)
    800066e2:	6402                	ld	s0,0(sp)
    800066e4:	0141                	addi	sp,sp,16
    800066e6:	8082                	ret

00000000800066e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800066e8:	1141                	addi	sp,sp,-16
    800066ea:	e406                	sd	ra,8(sp)
    800066ec:	e022                	sd	s0,0(sp)
    800066ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800066f0:	ffffc097          	auipc	ra,0xffffc
    800066f4:	80c080e7          	jalr	-2036(ra) # 80001efc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800066f8:	00d5179b          	slliw	a5,a0,0xd
    800066fc:	0c201537          	lui	a0,0xc201
    80006700:	953e                	add	a0,a0,a5
  return irq;
}
    80006702:	4148                	lw	a0,4(a0)
    80006704:	60a2                	ld	ra,8(sp)
    80006706:	6402                	ld	s0,0(sp)
    80006708:	0141                	addi	sp,sp,16
    8000670a:	8082                	ret

000000008000670c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000670c:	1101                	addi	sp,sp,-32
    8000670e:	ec06                	sd	ra,24(sp)
    80006710:	e822                	sd	s0,16(sp)
    80006712:	e426                	sd	s1,8(sp)
    80006714:	1000                	addi	s0,sp,32
    80006716:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006718:	ffffb097          	auipc	ra,0xffffb
    8000671c:	7e4080e7          	jalr	2020(ra) # 80001efc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006720:	00d5151b          	slliw	a0,a0,0xd
    80006724:	0c2017b7          	lui	a5,0xc201
    80006728:	97aa                	add	a5,a5,a0
    8000672a:	c3c4                	sw	s1,4(a5)
}
    8000672c:	60e2                	ld	ra,24(sp)
    8000672e:	6442                	ld	s0,16(sp)
    80006730:	64a2                	ld	s1,8(sp)
    80006732:	6105                	addi	sp,sp,32
    80006734:	8082                	ret

0000000080006736 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006736:	1141                	addi	sp,sp,-16
    80006738:	e406                	sd	ra,8(sp)
    8000673a:	e022                	sd	s0,0(sp)
    8000673c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000673e:	479d                	li	a5,7
    80006740:	04a7cc63          	blt	a5,a0,80006798 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006744:	0002c797          	auipc	a5,0x2c
    80006748:	b5c78793          	addi	a5,a5,-1188 # 800322a0 <disk>
    8000674c:	97aa                	add	a5,a5,a0
    8000674e:	0187c783          	lbu	a5,24(a5)
    80006752:	ebb9                	bnez	a5,800067a8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006754:	00451613          	slli	a2,a0,0x4
    80006758:	0002c797          	auipc	a5,0x2c
    8000675c:	b4878793          	addi	a5,a5,-1208 # 800322a0 <disk>
    80006760:	6394                	ld	a3,0(a5)
    80006762:	96b2                	add	a3,a3,a2
    80006764:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006768:	6398                	ld	a4,0(a5)
    8000676a:	9732                	add	a4,a4,a2
    8000676c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006770:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006774:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006778:	953e                	add	a0,a0,a5
    8000677a:	4785                	li	a5,1
    8000677c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006780:	0002c517          	auipc	a0,0x2c
    80006784:	b3850513          	addi	a0,a0,-1224 # 800322b8 <disk+0x18>
    80006788:	ffffc097          	auipc	ra,0xffffc
    8000678c:	ecc080e7          	jalr	-308(ra) # 80002654 <wakeup>
}
    80006790:	60a2                	ld	ra,8(sp)
    80006792:	6402                	ld	s0,0(sp)
    80006794:	0141                	addi	sp,sp,16
    80006796:	8082                	ret
    panic("free_desc 1");
    80006798:	00002517          	auipc	a0,0x2
    8000679c:	02050513          	addi	a0,a0,32 # 800087b8 <syscalls+0x328>
    800067a0:	ffffa097          	auipc	ra,0xffffa
    800067a4:	d9e080e7          	jalr	-610(ra) # 8000053e <panic>
    panic("free_desc 2");
    800067a8:	00002517          	auipc	a0,0x2
    800067ac:	02050513          	addi	a0,a0,32 # 800087c8 <syscalls+0x338>
    800067b0:	ffffa097          	auipc	ra,0xffffa
    800067b4:	d8e080e7          	jalr	-626(ra) # 8000053e <panic>

00000000800067b8 <virtio_disk_init>:
{
    800067b8:	1101                	addi	sp,sp,-32
    800067ba:	ec06                	sd	ra,24(sp)
    800067bc:	e822                	sd	s0,16(sp)
    800067be:	e426                	sd	s1,8(sp)
    800067c0:	e04a                	sd	s2,0(sp)
    800067c2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800067c4:	00002597          	auipc	a1,0x2
    800067c8:	01458593          	addi	a1,a1,20 # 800087d8 <syscalls+0x348>
    800067cc:	0002c517          	auipc	a0,0x2c
    800067d0:	bfc50513          	addi	a0,a0,-1028 # 800323c8 <disk+0x128>
    800067d4:	ffffa097          	auipc	ra,0xffffa
    800067d8:	372080e7          	jalr	882(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067dc:	100017b7          	lui	a5,0x10001
    800067e0:	4398                	lw	a4,0(a5)
    800067e2:	2701                	sext.w	a4,a4
    800067e4:	747277b7          	lui	a5,0x74727
    800067e8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800067ec:	14f71c63          	bne	a4,a5,80006944 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800067f0:	100017b7          	lui	a5,0x10001
    800067f4:	43dc                	lw	a5,4(a5)
    800067f6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067f8:	4709                	li	a4,2
    800067fa:	14e79563          	bne	a5,a4,80006944 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800067fe:	100017b7          	lui	a5,0x10001
    80006802:	479c                	lw	a5,8(a5)
    80006804:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006806:	12e79f63          	bne	a5,a4,80006944 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000680a:	100017b7          	lui	a5,0x10001
    8000680e:	47d8                	lw	a4,12(a5)
    80006810:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006812:	554d47b7          	lui	a5,0x554d4
    80006816:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000681a:	12f71563          	bne	a4,a5,80006944 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000681e:	100017b7          	lui	a5,0x10001
    80006822:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006826:	4705                	li	a4,1
    80006828:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000682a:	470d                	li	a4,3
    8000682c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000682e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006830:	c7ffe737          	lui	a4,0xc7ffe
    80006834:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcc37f>
    80006838:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000683a:	2701                	sext.w	a4,a4
    8000683c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000683e:	472d                	li	a4,11
    80006840:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006842:	5bbc                	lw	a5,112(a5)
    80006844:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006848:	8ba1                	andi	a5,a5,8
    8000684a:	10078563          	beqz	a5,80006954 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000684e:	100017b7          	lui	a5,0x10001
    80006852:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006856:	43fc                	lw	a5,68(a5)
    80006858:	2781                	sext.w	a5,a5
    8000685a:	10079563          	bnez	a5,80006964 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000685e:	100017b7          	lui	a5,0x10001
    80006862:	5bdc                	lw	a5,52(a5)
    80006864:	2781                	sext.w	a5,a5
  if(max == 0)
    80006866:	10078763          	beqz	a5,80006974 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000686a:	471d                	li	a4,7
    8000686c:	10f77c63          	bgeu	a4,a5,80006984 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006870:	ffffa097          	auipc	ra,0xffffa
    80006874:	276080e7          	jalr	630(ra) # 80000ae6 <kalloc>
    80006878:	0002c497          	auipc	s1,0x2c
    8000687c:	a2848493          	addi	s1,s1,-1496 # 800322a0 <disk>
    80006880:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006882:	ffffa097          	auipc	ra,0xffffa
    80006886:	264080e7          	jalr	612(ra) # 80000ae6 <kalloc>
    8000688a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000688c:	ffffa097          	auipc	ra,0xffffa
    80006890:	25a080e7          	jalr	602(ra) # 80000ae6 <kalloc>
    80006894:	87aa                	mv	a5,a0
    80006896:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006898:	6088                	ld	a0,0(s1)
    8000689a:	cd6d                	beqz	a0,80006994 <virtio_disk_init+0x1dc>
    8000689c:	0002c717          	auipc	a4,0x2c
    800068a0:	a0c73703          	ld	a4,-1524(a4) # 800322a8 <disk+0x8>
    800068a4:	cb65                	beqz	a4,80006994 <virtio_disk_init+0x1dc>
    800068a6:	c7fd                	beqz	a5,80006994 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800068a8:	6605                	lui	a2,0x1
    800068aa:	4581                	li	a1,0
    800068ac:	ffffa097          	auipc	ra,0xffffa
    800068b0:	426080e7          	jalr	1062(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800068b4:	0002c497          	auipc	s1,0x2c
    800068b8:	9ec48493          	addi	s1,s1,-1556 # 800322a0 <disk>
    800068bc:	6605                	lui	a2,0x1
    800068be:	4581                	li	a1,0
    800068c0:	6488                	ld	a0,8(s1)
    800068c2:	ffffa097          	auipc	ra,0xffffa
    800068c6:	410080e7          	jalr	1040(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800068ca:	6605                	lui	a2,0x1
    800068cc:	4581                	li	a1,0
    800068ce:	6888                	ld	a0,16(s1)
    800068d0:	ffffa097          	auipc	ra,0xffffa
    800068d4:	402080e7          	jalr	1026(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800068d8:	100017b7          	lui	a5,0x10001
    800068dc:	4721                	li	a4,8
    800068de:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800068e0:	4098                	lw	a4,0(s1)
    800068e2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800068e6:	40d8                	lw	a4,4(s1)
    800068e8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800068ec:	6498                	ld	a4,8(s1)
    800068ee:	0007069b          	sext.w	a3,a4
    800068f2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800068f6:	9701                	srai	a4,a4,0x20
    800068f8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800068fc:	6898                	ld	a4,16(s1)
    800068fe:	0007069b          	sext.w	a3,a4
    80006902:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006906:	9701                	srai	a4,a4,0x20
    80006908:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000690c:	4705                	li	a4,1
    8000690e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006910:	00e48c23          	sb	a4,24(s1)
    80006914:	00e48ca3          	sb	a4,25(s1)
    80006918:	00e48d23          	sb	a4,26(s1)
    8000691c:	00e48da3          	sb	a4,27(s1)
    80006920:	00e48e23          	sb	a4,28(s1)
    80006924:	00e48ea3          	sb	a4,29(s1)
    80006928:	00e48f23          	sb	a4,30(s1)
    8000692c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006930:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006934:	0727a823          	sw	s2,112(a5)
}
    80006938:	60e2                	ld	ra,24(sp)
    8000693a:	6442                	ld	s0,16(sp)
    8000693c:	64a2                	ld	s1,8(sp)
    8000693e:	6902                	ld	s2,0(sp)
    80006940:	6105                	addi	sp,sp,32
    80006942:	8082                	ret
    panic("could not find virtio disk");
    80006944:	00002517          	auipc	a0,0x2
    80006948:	ea450513          	addi	a0,a0,-348 # 800087e8 <syscalls+0x358>
    8000694c:	ffffa097          	auipc	ra,0xffffa
    80006950:	bf2080e7          	jalr	-1038(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006954:	00002517          	auipc	a0,0x2
    80006958:	eb450513          	addi	a0,a0,-332 # 80008808 <syscalls+0x378>
    8000695c:	ffffa097          	auipc	ra,0xffffa
    80006960:	be2080e7          	jalr	-1054(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006964:	00002517          	auipc	a0,0x2
    80006968:	ec450513          	addi	a0,a0,-316 # 80008828 <syscalls+0x398>
    8000696c:	ffffa097          	auipc	ra,0xffffa
    80006970:	bd2080e7          	jalr	-1070(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006974:	00002517          	auipc	a0,0x2
    80006978:	ed450513          	addi	a0,a0,-300 # 80008848 <syscalls+0x3b8>
    8000697c:	ffffa097          	auipc	ra,0xffffa
    80006980:	bc2080e7          	jalr	-1086(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006984:	00002517          	auipc	a0,0x2
    80006988:	ee450513          	addi	a0,a0,-284 # 80008868 <syscalls+0x3d8>
    8000698c:	ffffa097          	auipc	ra,0xffffa
    80006990:	bb2080e7          	jalr	-1102(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006994:	00002517          	auipc	a0,0x2
    80006998:	ef450513          	addi	a0,a0,-268 # 80008888 <syscalls+0x3f8>
    8000699c:	ffffa097          	auipc	ra,0xffffa
    800069a0:	ba2080e7          	jalr	-1118(ra) # 8000053e <panic>

00000000800069a4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800069a4:	7119                	addi	sp,sp,-128
    800069a6:	fc86                	sd	ra,120(sp)
    800069a8:	f8a2                	sd	s0,112(sp)
    800069aa:	f4a6                	sd	s1,104(sp)
    800069ac:	f0ca                	sd	s2,96(sp)
    800069ae:	ecce                	sd	s3,88(sp)
    800069b0:	e8d2                	sd	s4,80(sp)
    800069b2:	e4d6                	sd	s5,72(sp)
    800069b4:	e0da                	sd	s6,64(sp)
    800069b6:	fc5e                	sd	s7,56(sp)
    800069b8:	f862                	sd	s8,48(sp)
    800069ba:	f466                	sd	s9,40(sp)
    800069bc:	f06a                	sd	s10,32(sp)
    800069be:	ec6e                	sd	s11,24(sp)
    800069c0:	0100                	addi	s0,sp,128
    800069c2:	8aaa                	mv	s5,a0
    800069c4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800069c6:	00c52d03          	lw	s10,12(a0)
    800069ca:	001d1d1b          	slliw	s10,s10,0x1
    800069ce:	1d02                	slli	s10,s10,0x20
    800069d0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800069d4:	0002c517          	auipc	a0,0x2c
    800069d8:	9f450513          	addi	a0,a0,-1548 # 800323c8 <disk+0x128>
    800069dc:	ffffa097          	auipc	ra,0xffffa
    800069e0:	1fa080e7          	jalr	506(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800069e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800069e6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800069e8:	0002cb97          	auipc	s7,0x2c
    800069ec:	8b8b8b93          	addi	s7,s7,-1864 # 800322a0 <disk>
  for(int i = 0; i < 3; i++){
    800069f0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800069f2:	0002cc97          	auipc	s9,0x2c
    800069f6:	9d6c8c93          	addi	s9,s9,-1578 # 800323c8 <disk+0x128>
    800069fa:	a08d                	j	80006a5c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800069fc:	00fb8733          	add	a4,s7,a5
    80006a00:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006a04:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006a06:	0207c563          	bltz	a5,80006a30 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006a0a:	2905                	addiw	s2,s2,1
    80006a0c:	0611                	addi	a2,a2,4
    80006a0e:	05690c63          	beq	s2,s6,80006a66 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006a12:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006a14:	0002c717          	auipc	a4,0x2c
    80006a18:	88c70713          	addi	a4,a4,-1908 # 800322a0 <disk>
    80006a1c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006a1e:	01874683          	lbu	a3,24(a4)
    80006a22:	fee9                	bnez	a3,800069fc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006a24:	2785                	addiw	a5,a5,1
    80006a26:	0705                	addi	a4,a4,1
    80006a28:	fe979be3          	bne	a5,s1,80006a1e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006a2c:	57fd                	li	a5,-1
    80006a2e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006a30:	01205d63          	blez	s2,80006a4a <virtio_disk_rw+0xa6>
    80006a34:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006a36:	000a2503          	lw	a0,0(s4)
    80006a3a:	00000097          	auipc	ra,0x0
    80006a3e:	cfc080e7          	jalr	-772(ra) # 80006736 <free_desc>
      for(int j = 0; j < i; j++)
    80006a42:	2d85                	addiw	s11,s11,1
    80006a44:	0a11                	addi	s4,s4,4
    80006a46:	ffb918e3          	bne	s2,s11,80006a36 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006a4a:	85e6                	mv	a1,s9
    80006a4c:	0002c517          	auipc	a0,0x2c
    80006a50:	86c50513          	addi	a0,a0,-1940 # 800322b8 <disk+0x18>
    80006a54:	ffffc097          	auipc	ra,0xffffc
    80006a58:	b9c080e7          	jalr	-1124(ra) # 800025f0 <sleep>
  for(int i = 0; i < 3; i++){
    80006a5c:	f8040a13          	addi	s4,s0,-128
{
    80006a60:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006a62:	894e                	mv	s2,s3
    80006a64:	b77d                	j	80006a12 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a66:	f8042583          	lw	a1,-128(s0)
    80006a6a:	00a58793          	addi	a5,a1,10
    80006a6e:	0792                	slli	a5,a5,0x4

  if(write)
    80006a70:	0002c617          	auipc	a2,0x2c
    80006a74:	83060613          	addi	a2,a2,-2000 # 800322a0 <disk>
    80006a78:	00f60733          	add	a4,a2,a5
    80006a7c:	018036b3          	snez	a3,s8
    80006a80:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006a82:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006a86:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006a8a:	f6078693          	addi	a3,a5,-160
    80006a8e:	6218                	ld	a4,0(a2)
    80006a90:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a92:	00878513          	addi	a0,a5,8
    80006a96:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006a98:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006a9a:	6208                	ld	a0,0(a2)
    80006a9c:	96aa                	add	a3,a3,a0
    80006a9e:	4741                	li	a4,16
    80006aa0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006aa2:	4705                	li	a4,1
    80006aa4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006aa8:	f8442703          	lw	a4,-124(s0)
    80006aac:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006ab0:	0712                	slli	a4,a4,0x4
    80006ab2:	953a                	add	a0,a0,a4
    80006ab4:	058a8693          	addi	a3,s5,88
    80006ab8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80006aba:	6208                	ld	a0,0(a2)
    80006abc:	972a                	add	a4,a4,a0
    80006abe:	40000693          	li	a3,1024
    80006ac2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006ac4:	001c3c13          	seqz	s8,s8
    80006ac8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006aca:	001c6c13          	ori	s8,s8,1
    80006ace:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006ad2:	f8842603          	lw	a2,-120(s0)
    80006ad6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006ada:	0002b697          	auipc	a3,0x2b
    80006ade:	7c668693          	addi	a3,a3,1990 # 800322a0 <disk>
    80006ae2:	00258713          	addi	a4,a1,2
    80006ae6:	0712                	slli	a4,a4,0x4
    80006ae8:	9736                	add	a4,a4,a3
    80006aea:	587d                	li	a6,-1
    80006aec:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006af0:	0612                	slli	a2,a2,0x4
    80006af2:	9532                	add	a0,a0,a2
    80006af4:	f9078793          	addi	a5,a5,-112
    80006af8:	97b6                	add	a5,a5,a3
    80006afa:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80006afc:	629c                	ld	a5,0(a3)
    80006afe:	97b2                	add	a5,a5,a2
    80006b00:	4605                	li	a2,1
    80006b02:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006b04:	4509                	li	a0,2
    80006b06:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    80006b0a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006b0e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006b12:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006b16:	6698                	ld	a4,8(a3)
    80006b18:	00275783          	lhu	a5,2(a4)
    80006b1c:	8b9d                	andi	a5,a5,7
    80006b1e:	0786                	slli	a5,a5,0x1
    80006b20:	97ba                	add	a5,a5,a4
    80006b22:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006b26:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006b2a:	6698                	ld	a4,8(a3)
    80006b2c:	00275783          	lhu	a5,2(a4)
    80006b30:	2785                	addiw	a5,a5,1
    80006b32:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006b36:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006b3a:	100017b7          	lui	a5,0x10001
    80006b3e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006b42:	004aa783          	lw	a5,4(s5)
    80006b46:	02c79163          	bne	a5,a2,80006b68 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006b4a:	0002c917          	auipc	s2,0x2c
    80006b4e:	87e90913          	addi	s2,s2,-1922 # 800323c8 <disk+0x128>
  while(b->disk == 1) {
    80006b52:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006b54:	85ca                	mv	a1,s2
    80006b56:	8556                	mv	a0,s5
    80006b58:	ffffc097          	auipc	ra,0xffffc
    80006b5c:	a98080e7          	jalr	-1384(ra) # 800025f0 <sleep>
  while(b->disk == 1) {
    80006b60:	004aa783          	lw	a5,4(s5)
    80006b64:	fe9788e3          	beq	a5,s1,80006b54 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006b68:	f8042903          	lw	s2,-128(s0)
    80006b6c:	00290793          	addi	a5,s2,2
    80006b70:	00479713          	slli	a4,a5,0x4
    80006b74:	0002b797          	auipc	a5,0x2b
    80006b78:	72c78793          	addi	a5,a5,1836 # 800322a0 <disk>
    80006b7c:	97ba                	add	a5,a5,a4
    80006b7e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006b82:	0002b997          	auipc	s3,0x2b
    80006b86:	71e98993          	addi	s3,s3,1822 # 800322a0 <disk>
    80006b8a:	00491713          	slli	a4,s2,0x4
    80006b8e:	0009b783          	ld	a5,0(s3)
    80006b92:	97ba                	add	a5,a5,a4
    80006b94:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006b98:	854a                	mv	a0,s2
    80006b9a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006b9e:	00000097          	auipc	ra,0x0
    80006ba2:	b98080e7          	jalr	-1128(ra) # 80006736 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006ba6:	8885                	andi	s1,s1,1
    80006ba8:	f0ed                	bnez	s1,80006b8a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006baa:	0002c517          	auipc	a0,0x2c
    80006bae:	81e50513          	addi	a0,a0,-2018 # 800323c8 <disk+0x128>
    80006bb2:	ffffa097          	auipc	ra,0xffffa
    80006bb6:	0d8080e7          	jalr	216(ra) # 80000c8a <release>
}
    80006bba:	70e6                	ld	ra,120(sp)
    80006bbc:	7446                	ld	s0,112(sp)
    80006bbe:	74a6                	ld	s1,104(sp)
    80006bc0:	7906                	ld	s2,96(sp)
    80006bc2:	69e6                	ld	s3,88(sp)
    80006bc4:	6a46                	ld	s4,80(sp)
    80006bc6:	6aa6                	ld	s5,72(sp)
    80006bc8:	6b06                	ld	s6,64(sp)
    80006bca:	7be2                	ld	s7,56(sp)
    80006bcc:	7c42                	ld	s8,48(sp)
    80006bce:	7ca2                	ld	s9,40(sp)
    80006bd0:	7d02                	ld	s10,32(sp)
    80006bd2:	6de2                	ld	s11,24(sp)
    80006bd4:	6109                	addi	sp,sp,128
    80006bd6:	8082                	ret

0000000080006bd8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006bd8:	1101                	addi	sp,sp,-32
    80006bda:	ec06                	sd	ra,24(sp)
    80006bdc:	e822                	sd	s0,16(sp)
    80006bde:	e426                	sd	s1,8(sp)
    80006be0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006be2:	0002b497          	auipc	s1,0x2b
    80006be6:	6be48493          	addi	s1,s1,1726 # 800322a0 <disk>
    80006bea:	0002b517          	auipc	a0,0x2b
    80006bee:	7de50513          	addi	a0,a0,2014 # 800323c8 <disk+0x128>
    80006bf2:	ffffa097          	auipc	ra,0xffffa
    80006bf6:	fe4080e7          	jalr	-28(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006bfa:	10001737          	lui	a4,0x10001
    80006bfe:	533c                	lw	a5,96(a4)
    80006c00:	8b8d                	andi	a5,a5,3
    80006c02:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006c04:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006c08:	689c                	ld	a5,16(s1)
    80006c0a:	0204d703          	lhu	a4,32(s1)
    80006c0e:	0027d783          	lhu	a5,2(a5)
    80006c12:	04f70863          	beq	a4,a5,80006c62 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006c16:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006c1a:	6898                	ld	a4,16(s1)
    80006c1c:	0204d783          	lhu	a5,32(s1)
    80006c20:	8b9d                	andi	a5,a5,7
    80006c22:	078e                	slli	a5,a5,0x3
    80006c24:	97ba                	add	a5,a5,a4
    80006c26:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006c28:	00278713          	addi	a4,a5,2
    80006c2c:	0712                	slli	a4,a4,0x4
    80006c2e:	9726                	add	a4,a4,s1
    80006c30:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006c34:	e721                	bnez	a4,80006c7c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006c36:	0789                	addi	a5,a5,2
    80006c38:	0792                	slli	a5,a5,0x4
    80006c3a:	97a6                	add	a5,a5,s1
    80006c3c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006c3e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006c42:	ffffc097          	auipc	ra,0xffffc
    80006c46:	a12080e7          	jalr	-1518(ra) # 80002654 <wakeup>

    disk.used_idx += 1;
    80006c4a:	0204d783          	lhu	a5,32(s1)
    80006c4e:	2785                	addiw	a5,a5,1
    80006c50:	17c2                	slli	a5,a5,0x30
    80006c52:	93c1                	srli	a5,a5,0x30
    80006c54:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006c58:	6898                	ld	a4,16(s1)
    80006c5a:	00275703          	lhu	a4,2(a4)
    80006c5e:	faf71ce3          	bne	a4,a5,80006c16 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006c62:	0002b517          	auipc	a0,0x2b
    80006c66:	76650513          	addi	a0,a0,1894 # 800323c8 <disk+0x128>
    80006c6a:	ffffa097          	auipc	ra,0xffffa
    80006c6e:	020080e7          	jalr	32(ra) # 80000c8a <release>
}
    80006c72:	60e2                	ld	ra,24(sp)
    80006c74:	6442                	ld	s0,16(sp)
    80006c76:	64a2                	ld	s1,8(sp)
    80006c78:	6105                	addi	sp,sp,32
    80006c7a:	8082                	ret
      panic("virtio_disk_intr status");
    80006c7c:	00002517          	auipc	a0,0x2
    80006c80:	c2450513          	addi	a0,a0,-988 # 800088a0 <syscalls+0x410>
    80006c84:	ffffa097          	auipc	ra,0xffffa
    80006c88:	8ba080e7          	jalr	-1862(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
