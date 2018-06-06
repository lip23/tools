
obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 c0 17 10 f0 	movl   $0xf01017c0,(%esp)
f0100055:	e8 83 08 00 00       	call   f01008dd <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 d0 06 00 00       	call   f0100757 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 dc 17 10 f0 	movl   $0xf01017dc,(%esp)
f0100092:	e8 46 08 00 00       	call   f01008dd <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 d2 12 00 00       	call   f0101397 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 7c 04 00 00       	call   f0100546 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 f7 17 10 f0 	movl   $0xf01017f7,(%esp)
f01000d9:	e8 ff 07 00 00       	call   f01008dd <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 6b 06 00 00       	call   f0100761 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 12 18 10 f0 	movl   $0xf0101812,(%esp)
f010012c:	e8 ac 07 00 00       	call   f01008dd <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 6d 07 00 00       	call   f01008aa <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 4e 18 10 f0 	movl   $0xf010184e,(%esp)
f0100144:	e8 94 07 00 00       	call   f01008dd <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 0c 06 00 00       	call   f0100761 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 2a 18 10 f0 	movl   $0xf010182a,(%esp)
f0100176:	e8 62 07 00 00       	call   f01008dd <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 20 07 00 00       	call   f01008aa <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 4e 18 10 f0 	movl   $0xf010184e,(%esp)
f0100191:	e8 47 07 00 00       	call   f01008dd <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    

f010019c <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f010019c:	55                   	push   %ebp
f010019d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010019f:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a4:	ec                   	in     (%dx),%al
f01001a5:	ec                   	in     (%dx),%al
f01001a6:	ec                   	in     (%dx),%al
f01001a7:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001a8:	5d                   	pop    %ebp
f01001a9:	c3                   	ret    

f01001aa <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001aa:	55                   	push   %ebp
f01001ab:	89 e5                	mov    %esp,%ebp
f01001ad:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b2:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b3:	a8 01                	test   $0x1,%al
f01001b5:	74 08                	je     f01001bf <serial_proc_data+0x15>
f01001b7:	b2 f8                	mov    $0xf8,%dl
f01001b9:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001ba:	0f b6 c0             	movzbl %al,%eax
f01001bd:	eb 05                	jmp    f01001c4 <serial_proc_data+0x1a>
		return -1;
f01001bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f01001c4:	5d                   	pop    %ebp
f01001c5:	c3                   	ret    

f01001c6 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001c6:	55                   	push   %ebp
f01001c7:	89 e5                	mov    %esp,%ebp
f01001c9:	53                   	push   %ebx
f01001ca:	83 ec 04             	sub    $0x4,%esp
f01001cd:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001cf:	eb 29                	jmp    f01001fa <cons_intr+0x34>
		if (c == 0)
f01001d1:	85 c0                	test   %eax,%eax
f01001d3:	74 25                	je     f01001fa <cons_intr+0x34>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d5:	8b 15 24 25 11 f0    	mov    0xf0112524,%edx
f01001db:	88 82 20 23 11 f0    	mov    %al,-0xfeedce0(%edx)
f01001e1:	42                   	inc    %edx
f01001e2:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
		if (cons.wpos == CONSBUFSIZE)
f01001e8:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ee:	75 0a                	jne    f01001fa <cons_intr+0x34>
			cons.wpos = 0;
f01001f0:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001f7:	00 00 00 
	while ((c = (*proc)()) != -1) {
f01001fa:	ff d3                	call   *%ebx
f01001fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ff:	75 d0                	jne    f01001d1 <cons_intr+0xb>
	}
}
f0100201:	83 c4 04             	add    $0x4,%esp
f0100204:	5b                   	pop    %ebx
f0100205:	5d                   	pop    %ebp
f0100206:	c3                   	ret    

f0100207 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100207:	55                   	push   %ebp
f0100208:	89 e5                	mov    %esp,%ebp
f010020a:	57                   	push   %edi
f010020b:	56                   	push   %esi
f010020c:	53                   	push   %ebx
f010020d:	83 ec 2c             	sub    $0x2c,%esp
f0100210:	89 c7                	mov    %eax,%edi
f0100212:	bb 01 32 00 00       	mov    $0x3201,%ebx
f0100217:	be fd 03 00 00       	mov    $0x3fd,%esi
f010021c:	eb 05                	jmp    f0100223 <cons_putc+0x1c>
		delay();
f010021e:	e8 79 ff ff ff       	call   f010019c <delay>
f0100223:	89 f2                	mov    %esi,%edx
f0100225:	ec                   	in     (%dx),%al
	for (i = 0;
f0100226:	a8 20                	test   $0x20,%al
f0100228:	75 03                	jne    f010022d <cons_putc+0x26>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010022a:	4b                   	dec    %ebx
f010022b:	75 f1                	jne    f010021e <cons_putc+0x17>
f010022d:	89 fa                	mov    %edi,%edx
f010022f:	89 f8                	mov    %edi,%eax
f0100231:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100234:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100239:	ee                   	out    %al,(%dx)
f010023a:	bb 01 32 00 00       	mov    $0x3201,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010023f:	be 79 03 00 00       	mov    $0x379,%esi
f0100244:	eb 05                	jmp    f010024b <cons_putc+0x44>
		delay();
f0100246:	e8 51 ff ff ff       	call   f010019c <delay>
f010024b:	89 f2                	mov    %esi,%edx
f010024d:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010024e:	84 c0                	test   %al,%al
f0100250:	78 03                	js     f0100255 <cons_putc+0x4e>
f0100252:	4b                   	dec    %ebx
f0100253:	75 f1                	jne    f0100246 <cons_putc+0x3f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100255:	ba 78 03 00 00       	mov    $0x378,%edx
f010025a:	8a 45 e7             	mov    -0x19(%ebp),%al
f010025d:	ee                   	out    %al,(%dx)
f010025e:	b2 7a                	mov    $0x7a,%dl
f0100260:	b0 0d                	mov    $0xd,%al
f0100262:	ee                   	out    %al,(%dx)
f0100263:	b0 08                	mov    $0x8,%al
f0100265:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100266:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f010026c:	75 06                	jne    f0100274 <cons_putc+0x6d>
		c |= 0x0700;
f010026e:	81 cf 00 07 00 00    	or     $0x700,%edi
	switch (c & 0xff) {
f0100274:	89 f8                	mov    %edi,%eax
f0100276:	25 ff 00 00 00       	and    $0xff,%eax
f010027b:	83 f8 09             	cmp    $0x9,%eax
f010027e:	74 77                	je     f01002f7 <cons_putc+0xf0>
f0100280:	83 f8 09             	cmp    $0x9,%eax
f0100283:	7f 0b                	jg     f0100290 <cons_putc+0x89>
f0100285:	83 f8 08             	cmp    $0x8,%eax
f0100288:	0f 85 9d 00 00 00    	jne    f010032b <cons_putc+0x124>
f010028e:	eb 10                	jmp    f01002a0 <cons_putc+0x99>
f0100290:	83 f8 0a             	cmp    $0xa,%eax
f0100293:	74 39                	je     f01002ce <cons_putc+0xc7>
f0100295:	83 f8 0d             	cmp    $0xd,%eax
f0100298:	0f 85 8d 00 00 00    	jne    f010032b <cons_putc+0x124>
f010029e:	eb 36                	jmp    f01002d6 <cons_putc+0xcf>
		if (crt_pos > 0) {
f01002a0:	66 a1 34 25 11 f0    	mov    0xf0112534,%ax
f01002a6:	66 85 c0             	test   %ax,%ax
f01002a9:	0f 84 e1 00 00 00    	je     f0100390 <cons_putc+0x189>
			crt_pos--;
f01002af:	48                   	dec    %eax
f01002b0:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002b6:	0f b7 c0             	movzwl %ax,%eax
f01002b9:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01002bf:	83 cf 20             	or     $0x20,%edi
f01002c2:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f01002c8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002cc:	eb 77                	jmp    f0100345 <cons_putc+0x13e>
		crt_pos += CRT_COLS;
f01002ce:	66 83 05 34 25 11 f0 	addw   $0x50,0xf0112534
f01002d5:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f01002d6:	66 8b 0d 34 25 11 f0 	mov    0xf0112534,%cx
f01002dd:	bb 50 00 00 00       	mov    $0x50,%ebx
f01002e2:	89 c8                	mov    %ecx,%eax
f01002e4:	ba 00 00 00 00       	mov    $0x0,%edx
f01002e9:	66 f7 f3             	div    %bx
f01002ec:	29 d1                	sub    %edx,%ecx
f01002ee:	66 89 0d 34 25 11 f0 	mov    %cx,0xf0112534
f01002f5:	eb 4e                	jmp    f0100345 <cons_putc+0x13e>
		cons_putc(' ');
f01002f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01002fc:	e8 06 ff ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100301:	b8 20 00 00 00       	mov    $0x20,%eax
f0100306:	e8 fc fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010030b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100310:	e8 f2 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100315:	b8 20 00 00 00       	mov    $0x20,%eax
f010031a:	e8 e8 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010031f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100324:	e8 de fe ff ff       	call   f0100207 <cons_putc>
f0100329:	eb 1a                	jmp    f0100345 <cons_putc+0x13e>
		crt_buf[crt_pos++] = c;		/* write the character */
f010032b:	66 a1 34 25 11 f0    	mov    0xf0112534,%ax
f0100331:	0f b7 c8             	movzwl %ax,%ecx
f0100334:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f010033a:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f010033e:	40                   	inc    %eax
f010033f:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
	if (crt_pos >= CRT_SIZE) {
f0100345:	66 81 3d 34 25 11 f0 	cmpw   $0x7cf,0xf0112534
f010034c:	cf 07 
f010034e:	76 40                	jbe    f0100390 <cons_putc+0x189>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100350:	a1 30 25 11 f0       	mov    0xf0112530,%eax
f0100355:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010035c:	00 
f010035d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100363:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100367:	89 04 24             	mov    %eax,(%esp)
f010036a:	e8 75 10 00 00       	call   f01013e4 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010036f:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100375:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010037a:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100380:	40                   	inc    %eax
f0100381:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100386:	75 f2                	jne    f010037a <cons_putc+0x173>
		crt_pos -= CRT_COLS;
f0100388:	66 83 2d 34 25 11 f0 	subw   $0x50,0xf0112534
f010038f:	50 
	outb(addr_6845, 14);
f0100390:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f0100396:	b0 0e                	mov    $0xe,%al
f0100398:	89 ca                	mov    %ecx,%edx
f010039a:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010039b:	8d 59 01             	lea    0x1(%ecx),%ebx
f010039e:	66 a1 34 25 11 f0    	mov    0xf0112534,%ax
f01003a4:	66 c1 e8 08          	shr    $0x8,%ax
f01003a8:	89 da                	mov    %ebx,%edx
f01003aa:	ee                   	out    %al,(%dx)
f01003ab:	b0 0f                	mov    $0xf,%al
f01003ad:	89 ca                	mov    %ecx,%edx
f01003af:	ee                   	out    %al,(%dx)
f01003b0:	a0 34 25 11 f0       	mov    0xf0112534,%al
f01003b5:	89 da                	mov    %ebx,%edx
f01003b7:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003b8:	83 c4 2c             	add    $0x2c,%esp
f01003bb:	5b                   	pop    %ebx
f01003bc:	5e                   	pop    %esi
f01003bd:	5f                   	pop    %edi
f01003be:	5d                   	pop    %ebp
f01003bf:	c3                   	ret    

f01003c0 <kbd_proc_data>:
{
f01003c0:	55                   	push   %ebp
f01003c1:	89 e5                	mov    %esp,%ebp
f01003c3:	53                   	push   %ebx
f01003c4:	83 ec 14             	sub    $0x14,%esp
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003c7:	ba 64 00 00 00       	mov    $0x64,%edx
f01003cc:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01003cd:	a8 01                	test   $0x1,%al
f01003cf:	0f 84 e7 00 00 00    	je     f01004bc <kbd_proc_data+0xfc>
	if (stat & KBS_TERR)
f01003d5:	a8 20                	test   $0x20,%al
f01003d7:	0f 85 e6 00 00 00    	jne    f01004c3 <kbd_proc_data+0x103>
f01003dd:	b2 60                	mov    $0x60,%dl
f01003df:	ec                   	in     (%dx),%al
f01003e0:	88 c2                	mov    %al,%dl
	if (data == 0xE0) {
f01003e2:	3c e0                	cmp    $0xe0,%al
f01003e4:	75 11                	jne    f01003f7 <kbd_proc_data+0x37>
		shift |= E0ESC;
f01003e6:	83 0d 28 25 11 f0 40 	orl    $0x40,0xf0112528
		return 0;
f01003ed:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f2:	e9 d1 00 00 00       	jmp    f01004c8 <kbd_proc_data+0x108>
	} else if (data & 0x80) {
f01003f7:	84 c0                	test   %al,%al
f01003f9:	79 33                	jns    f010042e <kbd_proc_data+0x6e>
		data = (shift & E0ESC ? data : data & 0x7F);
f01003fb:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f0100401:	f6 c1 40             	test   $0x40,%cl
f0100404:	75 05                	jne    f010040b <kbd_proc_data+0x4b>
f0100406:	88 c2                	mov    %al,%dl
f0100408:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010040b:	0f b6 d2             	movzbl %dl,%edx
f010040e:	8a 82 80 18 10 f0    	mov    -0xfefe780(%edx),%al
f0100414:	83 c8 40             	or     $0x40,%eax
f0100417:	0f b6 c0             	movzbl %al,%eax
f010041a:	f7 d0                	not    %eax
f010041c:	21 c1                	and    %eax,%ecx
f010041e:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
		return 0;
f0100424:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100429:	e9 9a 00 00 00       	jmp    f01004c8 <kbd_proc_data+0x108>
	} else if (shift & E0ESC) {
f010042e:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f0100434:	f6 c1 40             	test   $0x40,%cl
f0100437:	74 0e                	je     f0100447 <kbd_proc_data+0x87>
		data |= 0x80;
f0100439:	88 c2                	mov    %al,%dl
f010043b:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010043e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100441:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
	shift |= shiftcode[data];
f0100447:	0f b6 c2             	movzbl %dl,%eax
f010044a:	0f b6 90 80 18 10 f0 	movzbl -0xfefe780(%eax),%edx
f0100451:	0b 15 28 25 11 f0    	or     0xf0112528,%edx
	shift ^= togglecode[data];
f0100457:	0f b6 88 80 19 10 f0 	movzbl -0xfefe680(%eax),%ecx
f010045e:	31 ca                	xor    %ecx,%edx
f0100460:	89 15 28 25 11 f0    	mov    %edx,0xf0112528
	c = charcode[shift & (CTL | SHIFT)][data];
f0100466:	89 d1                	mov    %edx,%ecx
f0100468:	83 e1 03             	and    $0x3,%ecx
f010046b:	8b 0c 8d 80 1a 10 f0 	mov    -0xfefe580(,%ecx,4),%ecx
f0100472:	8a 04 01             	mov    (%ecx,%eax,1),%al
f0100475:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100478:	f6 c2 08             	test   $0x8,%dl
f010047b:	74 1a                	je     f0100497 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f010047d:	89 d8                	mov    %ebx,%eax
f010047f:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100482:	83 f9 19             	cmp    $0x19,%ecx
f0100485:	77 05                	ja     f010048c <kbd_proc_data+0xcc>
			c += 'A' - 'a';
f0100487:	83 eb 20             	sub    $0x20,%ebx
f010048a:	eb 0b                	jmp    f0100497 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f010048c:	83 e8 41             	sub    $0x41,%eax
f010048f:	83 f8 19             	cmp    $0x19,%eax
f0100492:	77 03                	ja     f0100497 <kbd_proc_data+0xd7>
			c += 'a' - 'A';
f0100494:	83 c3 20             	add    $0x20,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100497:	f7 d2                	not    %edx
f0100499:	f6 c2 06             	test   $0x6,%dl
f010049c:	75 2a                	jne    f01004c8 <kbd_proc_data+0x108>
f010049e:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004a4:	75 22                	jne    f01004c8 <kbd_proc_data+0x108>
		cprintf("Rebooting!\n");
f01004a6:	c7 04 24 44 18 10 f0 	movl   $0xf0101844,(%esp)
f01004ad:	e8 2b 04 00 00       	call   f01008dd <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004b2:	ba 92 00 00 00       	mov    $0x92,%edx
f01004b7:	b0 03                	mov    $0x3,%al
f01004b9:	ee                   	out    %al,(%dx)
f01004ba:	eb 0c                	jmp    f01004c8 <kbd_proc_data+0x108>
		return -1;
f01004bc:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01004c1:	eb 05                	jmp    f01004c8 <kbd_proc_data+0x108>
		return -1;
f01004c3:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
}
f01004c8:	89 d8                	mov    %ebx,%eax
f01004ca:	83 c4 14             	add    $0x14,%esp
f01004cd:	5b                   	pop    %ebx
f01004ce:	5d                   	pop    %ebp
f01004cf:	c3                   	ret    

f01004d0 <serial_intr>:
	if (serial_exists)
f01004d0:	80 3d 00 23 11 f0 00 	cmpb   $0x0,0xf0112300
f01004d7:	74 11                	je     f01004ea <serial_intr+0x1a>
{
f01004d9:	55                   	push   %ebp
f01004da:	89 e5                	mov    %esp,%ebp
f01004dc:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004df:	b8 aa 01 10 f0       	mov    $0xf01001aa,%eax
f01004e4:	e8 dd fc ff ff       	call   f01001c6 <cons_intr>
}
f01004e9:	c9                   	leave  
f01004ea:	c3                   	ret    

f01004eb <kbd_intr>:
{
f01004eb:	55                   	push   %ebp
f01004ec:	89 e5                	mov    %esp,%ebp
f01004ee:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004f1:	b8 c0 03 10 f0       	mov    $0xf01003c0,%eax
f01004f6:	e8 cb fc ff ff       	call   f01001c6 <cons_intr>
}
f01004fb:	c9                   	leave  
f01004fc:	c3                   	ret    

f01004fd <cons_getc>:
{
f01004fd:	55                   	push   %ebp
f01004fe:	89 e5                	mov    %esp,%ebp
f0100500:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f0100503:	e8 c8 ff ff ff       	call   f01004d0 <serial_intr>
	kbd_intr();
f0100508:	e8 de ff ff ff       	call   f01004eb <kbd_intr>
	if (cons.rpos != cons.wpos) {
f010050d:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
f0100513:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f0100519:	74 24                	je     f010053f <cons_getc+0x42>
		c = cons.buf[cons.rpos++];
f010051b:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
f0100522:	42                   	inc    %edx
		if (cons.rpos == CONSBUFSIZE)
f0100523:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100529:	74 08                	je     f0100533 <cons_getc+0x36>
		c = cons.buf[cons.rpos++];
f010052b:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100531:	eb 11                	jmp    f0100544 <cons_getc+0x47>
			cons.rpos = 0;
f0100533:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f010053a:	00 00 00 
f010053d:	eb 05                	jmp    f0100544 <cons_getc+0x47>
	return 0;
f010053f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100544:	c9                   	leave  
f0100545:	c3                   	ret    

f0100546 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100546:	55                   	push   %ebp
f0100547:	89 e5                	mov    %esp,%ebp
f0100549:	57                   	push   %edi
f010054a:	56                   	push   %esi
f010054b:	53                   	push   %ebx
f010054c:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f010054f:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f0100556:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010055d:	5a a5 
	if (*cp != 0xA55A) {
f010055f:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f0100565:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100569:	74 11                	je     f010057c <cons_init+0x36>
		addr_6845 = MONO_BASE;
f010056b:	c7 05 2c 25 11 f0 b4 	movl   $0x3b4,0xf011252c
f0100572:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100575:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010057a:	eb 16                	jmp    f0100592 <cons_init+0x4c>
		*cp = was;
f010057c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100583:	c7 05 2c 25 11 f0 d4 	movl   $0x3d4,0xf011252c
f010058a:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058d:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f0100592:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f0100598:	b0 0e                	mov    $0xe,%al
f010059a:	89 ca                	mov    %ecx,%edx
f010059c:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010059d:	8d 59 01             	lea    0x1(%ecx),%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a0:	89 da                	mov    %ebx,%edx
f01005a2:	ec                   	in     (%dx),%al
f01005a3:	0f b6 f0             	movzbl %al,%esi
f01005a6:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a9:	b0 0f                	mov    $0xf,%al
f01005ab:	89 ca                	mov    %ecx,%edx
f01005ad:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ae:	89 da                	mov    %ebx,%edx
f01005b0:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01005b1:	89 3d 30 25 11 f0    	mov    %edi,0xf0112530
	pos |= inb(addr_6845 + 1);
f01005b7:	0f b6 d8             	movzbl %al,%ebx
f01005ba:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f01005bc:	66 89 35 34 25 11 f0 	mov    %si,0xf0112534
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005c8:	b0 00                	mov    $0x0,%al
f01005ca:	89 f2                	mov    %esi,%edx
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 fb                	mov    $0xfb,%dl
f01005cf:	b0 80                	mov    $0x80,%al
f01005d1:	ee                   	out    %al,(%dx)
f01005d2:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005d7:	b0 0c                	mov    $0xc,%al
f01005d9:	89 da                	mov    %ebx,%edx
f01005db:	ee                   	out    %al,(%dx)
f01005dc:	b2 f9                	mov    $0xf9,%dl
f01005de:	b0 00                	mov    $0x0,%al
f01005e0:	ee                   	out    %al,(%dx)
f01005e1:	b2 fb                	mov    $0xfb,%dl
f01005e3:	b0 03                	mov    $0x3,%al
f01005e5:	ee                   	out    %al,(%dx)
f01005e6:	b2 fc                	mov    $0xfc,%dl
f01005e8:	b0 00                	mov    $0x0,%al
f01005ea:	ee                   	out    %al,(%dx)
f01005eb:	b2 f9                	mov    $0xf9,%dl
f01005ed:	b0 01                	mov    $0x1,%al
f01005ef:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f0:	b2 fd                	mov    $0xfd,%dl
f01005f2:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005f3:	3c ff                	cmp    $0xff,%al
f01005f5:	0f 95 c1             	setne  %cl
f01005f8:	88 0d 00 23 11 f0    	mov    %cl,0xf0112300
f01005fe:	89 f2                	mov    %esi,%edx
f0100600:	ec                   	in     (%dx),%al
f0100601:	89 da                	mov    %ebx,%edx
f0100603:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100604:	84 c9                	test   %cl,%cl
f0100606:	75 0c                	jne    f0100614 <cons_init+0xce>
		cprintf("Serial port does not exist!\n");
f0100608:	c7 04 24 50 18 10 f0 	movl   $0xf0101850,(%esp)
f010060f:	e8 c9 02 00 00       	call   f01008dd <cprintf>
}
f0100614:	83 c4 1c             	add    $0x1c,%esp
f0100617:	5b                   	pop    %ebx
f0100618:	5e                   	pop    %esi
f0100619:	5f                   	pop    %edi
f010061a:	5d                   	pop    %ebp
f010061b:	c3                   	ret    

f010061c <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010061c:	55                   	push   %ebp
f010061d:	89 e5                	mov    %esp,%ebp
f010061f:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100622:	8b 45 08             	mov    0x8(%ebp),%eax
f0100625:	e8 dd fb ff ff       	call   f0100207 <cons_putc>
}
f010062a:	c9                   	leave  
f010062b:	c3                   	ret    

f010062c <getchar>:

int
getchar(void)
{
f010062c:	55                   	push   %ebp
f010062d:	89 e5                	mov    %esp,%ebp
f010062f:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100632:	e8 c6 fe ff ff       	call   f01004fd <cons_getc>
f0100637:	85 c0                	test   %eax,%eax
f0100639:	74 f7                	je     f0100632 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010063b:	c9                   	leave  
f010063c:	c3                   	ret    

f010063d <iscons>:

int
iscons(int fdnum)
{
f010063d:	55                   	push   %ebp
f010063e:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100640:	b8 01 00 00 00       	mov    $0x1,%eax
f0100645:	5d                   	pop    %ebp
f0100646:	c3                   	ret    

f0100647 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100647:	55                   	push   %ebp
f0100648:	89 e5                	mov    %esp,%ebp
f010064a:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010064d:	c7 04 24 90 1a 10 f0 	movl   $0xf0101a90,(%esp)
f0100654:	e8 84 02 00 00       	call   f01008dd <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100659:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100660:	00 
f0100661:	c7 04 24 1c 1b 10 f0 	movl   $0xf0101b1c,(%esp)
f0100668:	e8 70 02 00 00       	call   f01008dd <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010066d:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100674:	00 
f0100675:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f010067c:	f0 
f010067d:	c7 04 24 44 1b 10 f0 	movl   $0xf0101b44,(%esp)
f0100684:	e8 54 02 00 00       	call   f01008dd <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100689:	c7 44 24 08 b4 17 10 	movl   $0x1017b4,0x8(%esp)
f0100690:	00 
f0100691:	c7 44 24 04 b4 17 10 	movl   $0xf01017b4,0x4(%esp)
f0100698:	f0 
f0100699:	c7 04 24 68 1b 10 f0 	movl   $0xf0101b68,(%esp)
f01006a0:	e8 38 02 00 00       	call   f01008dd <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a5:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006ac:	00 
f01006ad:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006b4:	f0 
f01006b5:	c7 04 24 8c 1b 10 f0 	movl   $0xf0101b8c,(%esp)
f01006bc:	e8 1c 02 00 00       	call   f01008dd <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006c1:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f01006c8:	00 
f01006c9:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f01006d0:	f0 
f01006d1:	c7 04 24 b0 1b 10 f0 	movl   $0xf0101bb0,(%esp)
f01006d8:	e8 00 02 00 00       	call   f01008dd <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006dd:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f01006e2:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01006e7:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006ec:	89 c2                	mov    %eax,%edx
f01006ee:	85 c0                	test   %eax,%eax
f01006f0:	79 06                	jns    f01006f8 <mon_kerninfo+0xb1>
f01006f2:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006f8:	c1 fa 0a             	sar    $0xa,%edx
f01006fb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01006ff:	c7 04 24 d4 1b 10 f0 	movl   $0xf0101bd4,(%esp)
f0100706:	e8 d2 01 00 00       	call   f01008dd <cprintf>
	return 0;
}
f010070b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100710:	c9                   	leave  
f0100711:	c3                   	ret    

f0100712 <mon_help>:
{
f0100712:	55                   	push   %ebp
f0100713:	89 e5                	mov    %esp,%ebp
f0100715:	83 ec 18             	sub    $0x18,%esp
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100718:	c7 44 24 08 a9 1a 10 	movl   $0xf0101aa9,0x8(%esp)
f010071f:	f0 
f0100720:	c7 44 24 04 c7 1a 10 	movl   $0xf0101ac7,0x4(%esp)
f0100727:	f0 
f0100728:	c7 04 24 cc 1a 10 f0 	movl   $0xf0101acc,(%esp)
f010072f:	e8 a9 01 00 00       	call   f01008dd <cprintf>
f0100734:	c7 44 24 08 00 1c 10 	movl   $0xf0101c00,0x8(%esp)
f010073b:	f0 
f010073c:	c7 44 24 04 d5 1a 10 	movl   $0xf0101ad5,0x4(%esp)
f0100743:	f0 
f0100744:	c7 04 24 cc 1a 10 f0 	movl   $0xf0101acc,(%esp)
f010074b:	e8 8d 01 00 00       	call   f01008dd <cprintf>
}
f0100750:	b8 00 00 00 00       	mov    $0x0,%eax
f0100755:	c9                   	leave  
f0100756:	c3                   	ret    

f0100757 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100757:	55                   	push   %ebp
f0100758:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f010075a:	b8 00 00 00 00       	mov    $0x0,%eax
f010075f:	5d                   	pop    %ebp
f0100760:	c3                   	ret    

f0100761 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100761:	55                   	push   %ebp
f0100762:	89 e5                	mov    %esp,%ebp
f0100764:	57                   	push   %edi
f0100765:	56                   	push   %esi
f0100766:	53                   	push   %ebx
f0100767:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010076a:	c7 04 24 28 1c 10 f0 	movl   $0xf0101c28,(%esp)
f0100771:	e8 67 01 00 00       	call   f01008dd <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100776:	c7 04 24 4c 1c 10 f0 	movl   $0xf0101c4c,(%esp)
f010077d:	e8 5b 01 00 00       	call   f01008dd <cprintf>
			return commands[i].func(argc, argv, tf);
f0100782:	8d 7d a8             	lea    -0x58(%ebp),%edi


	while (1) {
		buf = readline("K> ");
f0100785:	c7 04 24 de 1a 10 f0 	movl   $0xf0101ade,(%esp)
f010078c:	e8 dc 09 00 00       	call   f010116d <readline>
f0100791:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100793:	85 c0                	test   %eax,%eax
f0100795:	74 ee                	je     f0100785 <monitor+0x24>
	argv[argc] = 0;
f0100797:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f010079e:	be 00 00 00 00       	mov    $0x0,%esi
f01007a3:	eb 04                	jmp    f01007a9 <monitor+0x48>
			*buf++ = 0;
f01007a5:	c6 03 00             	movb   $0x0,(%ebx)
f01007a8:	43                   	inc    %ebx
		while (*buf && strchr(WHITESPACE, *buf))
f01007a9:	8a 03                	mov    (%ebx),%al
f01007ab:	84 c0                	test   %al,%al
f01007ad:	74 5e                	je     f010080d <monitor+0xac>
f01007af:	0f be c0             	movsbl %al,%eax
f01007b2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b6:	c7 04 24 e2 1a 10 f0 	movl   $0xf0101ae2,(%esp)
f01007bd:	e8 a0 0b 00 00       	call   f0101362 <strchr>
f01007c2:	85 c0                	test   %eax,%eax
f01007c4:	75 df                	jne    f01007a5 <monitor+0x44>
		if (*buf == 0)
f01007c6:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007c9:	74 42                	je     f010080d <monitor+0xac>
		if (argc == MAXARGS-1) {
f01007cb:	83 fe 0f             	cmp    $0xf,%esi
f01007ce:	75 16                	jne    f01007e6 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007d0:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01007d7:	00 
f01007d8:	c7 04 24 e7 1a 10 f0 	movl   $0xf0101ae7,(%esp)
f01007df:	e8 f9 00 00 00       	call   f01008dd <cprintf>
f01007e4:	eb 9f                	jmp    f0100785 <monitor+0x24>
		argv[argc++] = buf;
f01007e6:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007ea:	46                   	inc    %esi
f01007eb:	eb 01                	jmp    f01007ee <monitor+0x8d>
			buf++;
f01007ed:	43                   	inc    %ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f01007ee:	8a 03                	mov    (%ebx),%al
f01007f0:	84 c0                	test   %al,%al
f01007f2:	74 b5                	je     f01007a9 <monitor+0x48>
f01007f4:	0f be c0             	movsbl %al,%eax
f01007f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007fb:	c7 04 24 e2 1a 10 f0 	movl   $0xf0101ae2,(%esp)
f0100802:	e8 5b 0b 00 00       	call   f0101362 <strchr>
f0100807:	85 c0                	test   %eax,%eax
f0100809:	74 e2                	je     f01007ed <monitor+0x8c>
f010080b:	eb 9c                	jmp    f01007a9 <monitor+0x48>
	argv[argc] = 0;
f010080d:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100814:	00 
	if (argc == 0)
f0100815:	85 f6                	test   %esi,%esi
f0100817:	0f 84 68 ff ff ff    	je     f0100785 <monitor+0x24>
		if (strcmp(argv[0], commands[i].name) == 0)
f010081d:	c7 44 24 04 c7 1a 10 	movl   $0xf0101ac7,0x4(%esp)
f0100824:	f0 
f0100825:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100828:	89 04 24             	mov    %eax,(%esp)
f010082b:	e8 de 0a 00 00       	call   f010130e <strcmp>
f0100830:	85 c0                	test   %eax,%eax
f0100832:	74 1b                	je     f010084f <monitor+0xee>
f0100834:	c7 44 24 04 d5 1a 10 	movl   $0xf0101ad5,0x4(%esp)
f010083b:	f0 
f010083c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010083f:	89 04 24             	mov    %eax,(%esp)
f0100842:	e8 c7 0a 00 00       	call   f010130e <strcmp>
f0100847:	85 c0                	test   %eax,%eax
f0100849:	75 2c                	jne    f0100877 <monitor+0x116>
f010084b:	b0 01                	mov    $0x1,%al
f010084d:	eb 05                	jmp    f0100854 <monitor+0xf3>
f010084f:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100854:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100857:	01 d0                	add    %edx,%eax
f0100859:	8b 55 08             	mov    0x8(%ebp),%edx
f010085c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100860:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100864:	89 34 24             	mov    %esi,(%esp)
f0100867:	ff 14 85 7c 1c 10 f0 	call   *-0xfefe384(,%eax,4)
			if (runcmd(buf, tf) < 0)
f010086e:	85 c0                	test   %eax,%eax
f0100870:	78 1d                	js     f010088f <monitor+0x12e>
f0100872:	e9 0e ff ff ff       	jmp    f0100785 <monitor+0x24>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100877:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010087a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010087e:	c7 04 24 04 1b 10 f0 	movl   $0xf0101b04,(%esp)
f0100885:	e8 53 00 00 00       	call   f01008dd <cprintf>
f010088a:	e9 f6 fe ff ff       	jmp    f0100785 <monitor+0x24>
				break;
	}
}
f010088f:	83 c4 5c             	add    $0x5c,%esp
f0100892:	5b                   	pop    %ebx
f0100893:	5e                   	pop    %esi
f0100894:	5f                   	pop    %edi
f0100895:	5d                   	pop    %ebp
f0100896:	c3                   	ret    

f0100897 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100897:	55                   	push   %ebp
f0100898:	89 e5                	mov    %esp,%ebp
f010089a:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010089d:	8b 45 08             	mov    0x8(%ebp),%eax
f01008a0:	89 04 24             	mov    %eax,(%esp)
f01008a3:	e8 74 fd ff ff       	call   f010061c <cputchar>
	*cnt++;
}
f01008a8:	c9                   	leave  
f01008a9:	c3                   	ret    

f01008aa <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008aa:	55                   	push   %ebp
f01008ab:	89 e5                	mov    %esp,%ebp
f01008ad:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01008b0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008b7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01008ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008be:	8b 45 08             	mov    0x8(%ebp),%eax
f01008c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008c5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01008c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008cc:	c7 04 24 97 08 10 f0 	movl   $0xf0100897,(%esp)
f01008d3:	e8 2b 04 00 00       	call   f0100d03 <vprintfmt>
	return cnt;
}
f01008d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01008db:	c9                   	leave  
f01008dc:	c3                   	ret    

f01008dd <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01008dd:	55                   	push   %ebp
f01008de:	89 e5                	mov    %esp,%ebp
f01008e0:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01008e3:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01008e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01008ed:	89 04 24             	mov    %eax,(%esp)
f01008f0:	e8 b5 ff ff ff       	call   f01008aa <vcprintf>
	va_end(ap);

	return cnt;
}
f01008f5:	c9                   	leave  
f01008f6:	c3                   	ret    

f01008f7 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01008f7:	55                   	push   %ebp
f01008f8:	89 e5                	mov    %esp,%ebp
f01008fa:	57                   	push   %edi
f01008fb:	56                   	push   %esi
f01008fc:	53                   	push   %ebx
f01008fd:	83 ec 10             	sub    $0x10,%esp
f0100900:	89 c6                	mov    %eax,%esi
f0100902:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100905:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100908:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010090b:	8b 1a                	mov    (%edx),%ebx
f010090d:	8b 09                	mov    (%ecx),%ecx
f010090f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100912:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100919:	eb 77                	jmp    f0100992 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f010091b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010091e:	01 d8                	add    %ebx,%eax
f0100920:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100925:	99                   	cltd   
f0100926:	f7 f9                	idiv   %ecx
f0100928:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010092a:	eb 01                	jmp    f010092d <stab_binsearch+0x36>
			m--;
f010092c:	49                   	dec    %ecx
		while (m >= l && stabs[m].n_type != type)
f010092d:	39 d9                	cmp    %ebx,%ecx
f010092f:	7c 1d                	jl     f010094e <stab_binsearch+0x57>
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100931:	6b d1 0c             	imul   $0xc,%ecx,%edx
		while (m >= l && stabs[m].n_type != type)
f0100934:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100939:	39 fa                	cmp    %edi,%edx
f010093b:	75 ef                	jne    f010092c <stab_binsearch+0x35>
f010093d:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100940:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100943:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100947:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010094a:	73 18                	jae    f0100964 <stab_binsearch+0x6d>
f010094c:	eb 05                	jmp    f0100953 <stab_binsearch+0x5c>
			l = true_m + 1;
f010094e:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100951:	eb 3f                	jmp    f0100992 <stab_binsearch+0x9b>
			*region_left = m;
f0100953:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100956:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0100958:	8d 58 01             	lea    0x1(%eax),%ebx
		any_matches = 1;
f010095b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100962:	eb 2e                	jmp    f0100992 <stab_binsearch+0x9b>
		} else if (stabs[m].n_value > addr) {
f0100964:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100967:	73 15                	jae    f010097e <stab_binsearch+0x87>
			*region_right = m - 1;
f0100969:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010096c:	49                   	dec    %ecx
f010096d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100970:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100973:	89 08                	mov    %ecx,(%eax)
		any_matches = 1;
f0100975:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f010097c:	eb 14                	jmp    f0100992 <stab_binsearch+0x9b>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010097e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100981:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100984:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0100986:	ff 45 0c             	incl   0xc(%ebp)
f0100989:	89 cb                	mov    %ecx,%ebx
		any_matches = 1;
f010098b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	while (l <= r) {
f0100992:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100995:	7e 84                	jle    f010091b <stab_binsearch+0x24>
		}
	}

	if (!any_matches)
f0100997:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f010099b:	75 0d                	jne    f01009aa <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f010099d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009a0:	8b 02                	mov    (%edx),%eax
f01009a2:	48                   	dec    %eax
f01009a3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009a6:	89 01                	mov    %eax,(%ecx)
f01009a8:	eb 22                	jmp    f01009cc <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009aa:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009ad:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009af:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009b2:	8b 0a                	mov    (%edx),%ecx
		for (l = *region_right;
f01009b4:	eb 01                	jmp    f01009b7 <stab_binsearch+0xc0>
		     l--)
f01009b6:	48                   	dec    %eax
		for (l = *region_right;
f01009b7:	39 c1                	cmp    %eax,%ecx
f01009b9:	7d 0c                	jge    f01009c7 <stab_binsearch+0xd0>
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01009bb:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f01009be:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f01009c3:	39 fa                	cmp    %edi,%edx
f01009c5:	75 ef                	jne    f01009b6 <stab_binsearch+0xbf>
			/* do nothing */;
		*region_left = l;
f01009c7:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009ca:	89 02                	mov    %eax,(%edx)
	}
}
f01009cc:	83 c4 10             	add    $0x10,%esp
f01009cf:	5b                   	pop    %ebx
f01009d0:	5e                   	pop    %esi
f01009d1:	5f                   	pop    %edi
f01009d2:	5d                   	pop    %ebp
f01009d3:	c3                   	ret    

f01009d4 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01009d4:	55                   	push   %ebp
f01009d5:	89 e5                	mov    %esp,%ebp
f01009d7:	57                   	push   %edi
f01009d8:	56                   	push   %esi
f01009d9:	53                   	push   %ebx
f01009da:	83 ec 2c             	sub    $0x2c,%esp
f01009dd:	8b 75 08             	mov    0x8(%ebp),%esi
f01009e0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01009e3:	c7 03 8c 1c 10 f0    	movl   $0xf0101c8c,(%ebx)
	info->eip_line = 0;
f01009e9:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01009f0:	c7 43 08 8c 1c 10 f0 	movl   $0xf0101c8c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01009f7:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01009fe:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a01:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a08:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a0e:	76 12                	jbe    f0100a22 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a10:	b8 bb 71 10 f0       	mov    $0xf01071bb,%eax
f0100a15:	3d fd 58 10 f0       	cmp    $0xf01058fd,%eax
f0100a1a:	0f 86 63 01 00 00    	jbe    f0100b83 <debuginfo_eip+0x1af>
f0100a20:	eb 1c                	jmp    f0100a3e <debuginfo_eip+0x6a>
  	        panic("User address");
f0100a22:	c7 44 24 08 96 1c 10 	movl   $0xf0101c96,0x8(%esp)
f0100a29:	f0 
f0100a2a:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100a31:	00 
f0100a32:	c7 04 24 a3 1c 10 f0 	movl   $0xf0101ca3,(%esp)
f0100a39:	e8 ba f6 ff ff       	call   f01000f8 <_panic>
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a3e:	80 3d ba 71 10 f0 00 	cmpb   $0x0,0xf01071ba
f0100a45:	0f 85 3f 01 00 00    	jne    f0100b8a <debuginfo_eip+0x1b6>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a4b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a52:	b8 fc 58 10 f0       	mov    $0xf01058fc,%eax
f0100a57:	2d c4 1e 10 f0       	sub    $0xf0101ec4,%eax
f0100a5c:	c1 f8 02             	sar    $0x2,%eax
f0100a5f:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100a65:	48                   	dec    %eax
f0100a66:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100a69:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100a6d:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100a74:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100a77:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100a7a:	b8 c4 1e 10 f0       	mov    $0xf0101ec4,%eax
f0100a7f:	e8 73 fe ff ff       	call   f01008f7 <stab_binsearch>
	if (lfile == 0)
f0100a84:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a87:	85 c0                	test   %eax,%eax
f0100a89:	0f 84 02 01 00 00    	je     f0100b91 <debuginfo_eip+0x1bd>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100a8f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100a92:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a95:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100a98:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100a9c:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100aa3:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100aa6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100aa9:	b8 c4 1e 10 f0       	mov    $0xf0101ec4,%eax
f0100aae:	e8 44 fe ff ff       	call   f01008f7 <stab_binsearch>

	if (lfun <= rfun) {
f0100ab3:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100ab6:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100ab9:	7f 2e                	jg     f0100ae9 <debuginfo_eip+0x115>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100abb:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100abe:	8d 90 c4 1e 10 f0    	lea    -0xfefe13c(%eax),%edx
f0100ac4:	8b 80 c4 1e 10 f0    	mov    -0xfefe13c(%eax),%eax
f0100aca:	b9 bb 71 10 f0       	mov    $0xf01071bb,%ecx
f0100acf:	81 e9 fd 58 10 f0    	sub    $0xf01058fd,%ecx
f0100ad5:	39 c8                	cmp    %ecx,%eax
f0100ad7:	73 08                	jae    f0100ae1 <debuginfo_eip+0x10d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ad9:	05 fd 58 10 f0       	add    $0xf01058fd,%eax
f0100ade:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ae1:	8b 42 08             	mov    0x8(%edx),%eax
f0100ae4:	89 43 10             	mov    %eax,0x10(%ebx)
f0100ae7:	eb 06                	jmp    f0100aef <debuginfo_eip+0x11b>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100ae9:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100aec:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100aef:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100af6:	00 
f0100af7:	8b 43 08             	mov    0x8(%ebx),%eax
f0100afa:	89 04 24             	mov    %eax,(%esp)
f0100afd:	e8 7d 08 00 00       	call   f010137f <strfind>
f0100b02:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b05:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b08:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100b0b:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b0e:	05 c4 1e 10 f0       	add    $0xf0101ec4,%eax
	while (lline >= lfile
f0100b13:	eb 04                	jmp    f0100b19 <debuginfo_eip+0x145>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b15:	4f                   	dec    %edi
f0100b16:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100b19:	39 cf                	cmp    %ecx,%edi
f0100b1b:	7c 32                	jl     f0100b4f <debuginfo_eip+0x17b>
	       && stabs[lline].n_type != N_SOL
f0100b1d:	8a 50 04             	mov    0x4(%eax),%dl
f0100b20:	80 fa 84             	cmp    $0x84,%dl
f0100b23:	74 0b                	je     f0100b30 <debuginfo_eip+0x15c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b25:	80 fa 64             	cmp    $0x64,%dl
f0100b28:	75 eb                	jne    f0100b15 <debuginfo_eip+0x141>
f0100b2a:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b2e:	74 e5                	je     f0100b15 <debuginfo_eip+0x141>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b30:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100b33:	8b 87 c4 1e 10 f0    	mov    -0xfefe13c(%edi),%eax
f0100b39:	ba bb 71 10 f0       	mov    $0xf01071bb,%edx
f0100b3e:	81 ea fd 58 10 f0    	sub    $0xf01058fd,%edx
f0100b44:	39 d0                	cmp    %edx,%eax
f0100b46:	73 07                	jae    f0100b4f <debuginfo_eip+0x17b>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b48:	05 fd 58 10 f0       	add    $0xf01058fd,%eax
f0100b4d:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b4f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100b52:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100b55:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100b5a:	39 f1                	cmp    %esi,%ecx
f0100b5c:	7d 3f                	jge    f0100b9d <debuginfo_eip+0x1c9>
		for (lline = lfun + 1;
f0100b5e:	8d 51 01             	lea    0x1(%ecx),%edx
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100b61:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100b64:	05 c4 1e 10 f0       	add    $0xf0101ec4,%eax
		for (lline = lfun + 1;
f0100b69:	eb 04                	jmp    f0100b6f <debuginfo_eip+0x19b>
			info->eip_fn_narg++;
f0100b6b:	ff 43 14             	incl   0x14(%ebx)
		     lline++)
f0100b6e:	42                   	inc    %edx
		for (lline = lfun + 1;
f0100b6f:	39 f2                	cmp    %esi,%edx
f0100b71:	74 25                	je     f0100b98 <debuginfo_eip+0x1c4>
f0100b73:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100b76:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100b7a:	74 ef                	je     f0100b6b <debuginfo_eip+0x197>
	return 0;
f0100b7c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b81:	eb 1a                	jmp    f0100b9d <debuginfo_eip+0x1c9>
		return -1;
f0100b83:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b88:	eb 13                	jmp    f0100b9d <debuginfo_eip+0x1c9>
f0100b8a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b8f:	eb 0c                	jmp    f0100b9d <debuginfo_eip+0x1c9>
		return -1;
f0100b91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b96:	eb 05                	jmp    f0100b9d <debuginfo_eip+0x1c9>
	return 0;
f0100b98:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100b9d:	83 c4 2c             	add    $0x2c,%esp
f0100ba0:	5b                   	pop    %ebx
f0100ba1:	5e                   	pop    %esi
f0100ba2:	5f                   	pop    %edi
f0100ba3:	5d                   	pop    %ebp
f0100ba4:	c3                   	ret    

f0100ba5 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100ba5:	55                   	push   %ebp
f0100ba6:	89 e5                	mov    %esp,%ebp
f0100ba8:	57                   	push   %edi
f0100ba9:	56                   	push   %esi
f0100baa:	53                   	push   %ebx
f0100bab:	83 ec 4c             	sub    $0x4c,%esp
f0100bae:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100bb1:	89 d7                	mov    %edx,%edi
f0100bb3:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100bb6:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0100bb9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100bbc:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100bbf:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100bc2:	85 db                	test   %ebx,%ebx
f0100bc4:	75 08                	jne    f0100bce <printnum+0x29>
f0100bc6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100bc9:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0100bcc:	77 6a                	ja     f0100c38 <printnum+0x93>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100bce:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0100bd1:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0100bd5:	4e                   	dec    %esi
f0100bd6:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100bda:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100bdd:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100be1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100be5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100be9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100bec:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100bef:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100bf6:	00 
f0100bf7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100bfa:	89 1c 24             	mov    %ebx,(%esp)
f0100bfd:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100c00:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100c04:	e8 8d 09 00 00       	call   f0101596 <__udivdi3>
f0100c09:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100c0c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100c0f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100c13:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100c17:	89 04 24             	mov    %eax,(%esp)
f0100c1a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c1e:	89 fa                	mov    %edi,%edx
f0100c20:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c23:	e8 7d ff ff ff       	call   f0100ba5 <printnum>
f0100c28:	eb 19                	jmp    f0100c43 <printnum+0x9e>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c2a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c2e:	8b 45 18             	mov    0x18(%ebp),%eax
f0100c31:	89 04 24             	mov    %eax,(%esp)
f0100c34:	ff d3                	call   *%ebx
f0100c36:	eb 03                	jmp    f0100c3b <printnum+0x96>
f0100c38:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		while (--width > 0)
f0100c3b:	4e                   	dec    %esi
f0100c3c:	85 f6                	test   %esi,%esi
f0100c3e:	7f ea                	jg     f0100c2a <printnum+0x85>
f0100c40:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100c43:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c47:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100c4b:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100c4e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100c52:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100c59:	00 
f0100c5a:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100c5d:	89 1c 24             	mov    %ebx,(%esp)
f0100c60:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100c63:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100c67:	e8 30 0a 00 00       	call   f010169c <__umoddi3>
f0100c6c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c70:	0f be 80 b1 1c 10 f0 	movsbl -0xfefe34f(%eax),%eax
f0100c77:	89 04 24             	mov    %eax,(%esp)
f0100c7a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c7d:	ff d0                	call   *%eax
}
f0100c7f:	83 c4 4c             	add    $0x4c,%esp
f0100c82:	5b                   	pop    %ebx
f0100c83:	5e                   	pop    %esi
f0100c84:	5f                   	pop    %edi
f0100c85:	5d                   	pop    %ebp
f0100c86:	c3                   	ret    

f0100c87 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100c87:	55                   	push   %ebp
f0100c88:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100c8a:	83 fa 01             	cmp    $0x1,%edx
f0100c8d:	7e 0e                	jle    f0100c9d <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100c8f:	8b 10                	mov    (%eax),%edx
f0100c91:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100c94:	89 08                	mov    %ecx,(%eax)
f0100c96:	8b 02                	mov    (%edx),%eax
f0100c98:	8b 52 04             	mov    0x4(%edx),%edx
f0100c9b:	eb 22                	jmp    f0100cbf <getuint+0x38>
	else if (lflag)
f0100c9d:	85 d2                	test   %edx,%edx
f0100c9f:	74 10                	je     f0100cb1 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100ca1:	8b 10                	mov    (%eax),%edx
f0100ca3:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ca6:	89 08                	mov    %ecx,(%eax)
f0100ca8:	8b 02                	mov    (%edx),%eax
f0100caa:	ba 00 00 00 00       	mov    $0x0,%edx
f0100caf:	eb 0e                	jmp    f0100cbf <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100cb1:	8b 10                	mov    (%eax),%edx
f0100cb3:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100cb6:	89 08                	mov    %ecx,(%eax)
f0100cb8:	8b 02                	mov    (%edx),%eax
f0100cba:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100cbf:	5d                   	pop    %ebp
f0100cc0:	c3                   	ret    

f0100cc1 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100cc1:	55                   	push   %ebp
f0100cc2:	89 e5                	mov    %esp,%ebp
f0100cc4:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100cc7:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0100cca:	8b 10                	mov    (%eax),%edx
f0100ccc:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ccf:	73 08                	jae    f0100cd9 <sprintputch+0x18>
		*b->buf++ = ch;
f0100cd1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100cd4:	88 0a                	mov    %cl,(%edx)
f0100cd6:	42                   	inc    %edx
f0100cd7:	89 10                	mov    %edx,(%eax)
}
f0100cd9:	5d                   	pop    %ebp
f0100cda:	c3                   	ret    

f0100cdb <printfmt>:
{
f0100cdb:	55                   	push   %ebp
f0100cdc:	89 e5                	mov    %esp,%ebp
f0100cde:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f0100ce1:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ce4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ce8:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ceb:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cef:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100cf2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cf6:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cf9:	89 04 24             	mov    %eax,(%esp)
f0100cfc:	e8 02 00 00 00       	call   f0100d03 <vprintfmt>
}
f0100d01:	c9                   	leave  
f0100d02:	c3                   	ret    

f0100d03 <vprintfmt>:
{
f0100d03:	55                   	push   %ebp
f0100d04:	89 e5                	mov    %esp,%ebp
f0100d06:	57                   	push   %edi
f0100d07:	56                   	push   %esi
f0100d08:	53                   	push   %ebx
f0100d09:	83 ec 4c             	sub    $0x4c,%esp
f0100d0c:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d0f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d12:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d15:	eb 11                	jmp    f0100d28 <vprintfmt+0x25>
			if (ch == '\0')
f0100d17:	85 c0                	test   %eax,%eax
f0100d19:	0f 84 bf 03 00 00    	je     f01010de <vprintfmt+0x3db>
			putch(ch, putdat);
f0100d1f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100d23:	89 04 24             	mov    %eax,(%esp)
f0100d26:	ff d6                	call   *%esi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d28:	0f b6 07             	movzbl (%edi),%eax
f0100d2b:	47                   	inc    %edi
f0100d2c:	83 f8 25             	cmp    $0x25,%eax
f0100d2f:	75 e6                	jne    f0100d17 <vprintfmt+0x14>
f0100d31:	c6 45 d0 20          	movb   $0x20,-0x30(%ebp)
f0100d35:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0100d3c:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0100d43:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100d4a:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d4f:	eb 2b                	jmp    f0100d7c <vprintfmt+0x79>
		switch (ch = *(unsigned char *) fmt++) {
f0100d51:	8b 7d d8             	mov    -0x28(%ebp),%edi
			padc = '-';
f0100d54:	c6 45 d0 2d          	movb   $0x2d,-0x30(%ebp)
f0100d58:	eb 22                	jmp    f0100d7c <vprintfmt+0x79>
		switch (ch = *(unsigned char *) fmt++) {
f0100d5a:	8b 7d d8             	mov    -0x28(%ebp),%edi
			padc = '0';
f0100d5d:	c6 45 d0 30          	movb   $0x30,-0x30(%ebp)
f0100d61:	eb 19                	jmp    f0100d7c <vprintfmt+0x79>
		switch (ch = *(unsigned char *) fmt++) {
f0100d63:	8b 7d d8             	mov    -0x28(%ebp),%edi
				width = 0;
f0100d66:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100d6d:	eb 0d                	jmp    f0100d7c <vprintfmt+0x79>
				width = precision, precision = -1;
f0100d6f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100d72:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100d75:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100d7c:	0f b6 07             	movzbl (%edi),%eax
f0100d7f:	8d 4f 01             	lea    0x1(%edi),%ecx
f0100d82:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100d85:	8a 0f                	mov    (%edi),%cl
f0100d87:	83 e9 23             	sub    $0x23,%ecx
f0100d8a:	80 f9 55             	cmp    $0x55,%cl
f0100d8d:	0f 87 30 03 00 00    	ja     f01010c3 <vprintfmt+0x3c0>
f0100d93:	0f b6 c9             	movzbl %cl,%ecx
f0100d96:	ff 24 8d 40 1d 10 f0 	jmp    *-0xfefe2c0(,%ecx,4)
f0100d9d:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100da0:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f0100da7:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100daa:	ba 00 00 00 00       	mov    $0x0,%edx
				precision = precision * 10 + ch - '0';
f0100daf:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100db2:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100db6:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100db9:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100dbc:	83 f9 09             	cmp    $0x9,%ecx
f0100dbf:	77 2d                	ja     f0100dee <vprintfmt+0xeb>
			for (precision = 0; ; ++fmt) {
f0100dc1:	47                   	inc    %edi
			}
f0100dc2:	eb eb                	jmp    f0100daf <vprintfmt+0xac>
			precision = va_arg(ap, int);
f0100dc4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dc7:	8d 48 04             	lea    0x4(%eax),%ecx
f0100dca:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100dcd:	8b 00                	mov    (%eax),%eax
f0100dcf:	89 45 cc             	mov    %eax,-0x34(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100dd2:	8b 7d d8             	mov    -0x28(%ebp),%edi
			goto process_precision;
f0100dd5:	eb 1d                	jmp    f0100df4 <vprintfmt+0xf1>
			if (width < 0)
f0100dd7:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100ddb:	78 86                	js     f0100d63 <vprintfmt+0x60>
		switch (ch = *(unsigned char *) fmt++) {
f0100ddd:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100de0:	eb 9a                	jmp    f0100d7c <vprintfmt+0x79>
f0100de2:	8b 7d d8             	mov    -0x28(%ebp),%edi
			altflag = 1;
f0100de5:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			goto reswitch;
f0100dec:	eb 8e                	jmp    f0100d7c <vprintfmt+0x79>
f0100dee:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0100df1:	8b 55 e0             	mov    -0x20(%ebp),%edx
			if (width < 0)
f0100df4:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100df8:	79 82                	jns    f0100d7c <vprintfmt+0x79>
f0100dfa:	e9 70 ff ff ff       	jmp    f0100d6f <vprintfmt+0x6c>
			lflag++;
f0100dff:	42                   	inc    %edx
		switch (ch = *(unsigned char *) fmt++) {
f0100e00:	8b 7d d8             	mov    -0x28(%ebp),%edi
			goto reswitch;
f0100e03:	e9 74 ff ff ff       	jmp    f0100d7c <vprintfmt+0x79>
			putch(va_arg(ap, int), putdat);
f0100e08:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e0b:	8d 50 04             	lea    0x4(%eax),%edx
f0100e0e:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e11:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e15:	8b 00                	mov    (%eax),%eax
f0100e17:	89 04 24             	mov    %eax,(%esp)
f0100e1a:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f0100e1c:	8b 7d d8             	mov    -0x28(%ebp),%edi
			break;
f0100e1f:	e9 04 ff ff ff       	jmp    f0100d28 <vprintfmt+0x25>
			err = va_arg(ap, int);
f0100e24:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e27:	8d 50 04             	lea    0x4(%eax),%edx
f0100e2a:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e2d:	8b 00                	mov    (%eax),%eax
f0100e2f:	85 c0                	test   %eax,%eax
f0100e31:	79 02                	jns    f0100e35 <vprintfmt+0x132>
f0100e33:	f7 d8                	neg    %eax
f0100e35:	89 c2                	mov    %eax,%edx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e37:	83 f8 06             	cmp    $0x6,%eax
f0100e3a:	7f 0b                	jg     f0100e47 <vprintfmt+0x144>
f0100e3c:	8b 04 85 98 1e 10 f0 	mov    -0xfefe168(,%eax,4),%eax
f0100e43:	85 c0                	test   %eax,%eax
f0100e45:	75 20                	jne    f0100e67 <vprintfmt+0x164>
				printfmt(putch, putdat, "error %d", err);
f0100e47:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100e4b:	c7 44 24 08 c9 1c 10 	movl   $0xf0101cc9,0x8(%esp)
f0100e52:	f0 
f0100e53:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e57:	89 34 24             	mov    %esi,(%esp)
f0100e5a:	e8 7c fe ff ff       	call   f0100cdb <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
f0100e5f:	8b 7d d8             	mov    -0x28(%ebp),%edi
				printfmt(putch, putdat, "error %d", err);
f0100e62:	e9 c1 fe ff ff       	jmp    f0100d28 <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f0100e67:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e6b:	c7 44 24 08 d2 1c 10 	movl   $0xf0101cd2,0x8(%esp)
f0100e72:	f0 
f0100e73:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e77:	89 34 24             	mov    %esi,(%esp)
f0100e7a:	e8 5c fe ff ff       	call   f0100cdb <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
f0100e7f:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100e82:	e9 a1 fe ff ff       	jmp    f0100d28 <vprintfmt+0x25>
f0100e87:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100e8a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e8d:	89 45 e0             	mov    %eax,-0x20(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f0100e90:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e93:	8d 50 04             	lea    0x4(%eax),%edx
f0100e96:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e99:	8b 38                	mov    (%eax),%edi
f0100e9b:	85 ff                	test   %edi,%edi
f0100e9d:	75 05                	jne    f0100ea4 <vprintfmt+0x1a1>
				p = "(null)";
f0100e9f:	bf c2 1c 10 f0       	mov    $0xf0101cc2,%edi
			if (width > 0 && padc != '-')
f0100ea4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ea8:	0f 8e 90 00 00 00    	jle    f0100f3e <vprintfmt+0x23b>
f0100eae:	80 7d d0 2d          	cmpb   $0x2d,-0x30(%ebp)
f0100eb2:	0f 84 8e 00 00 00    	je     f0100f46 <vprintfmt+0x243>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100eb8:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100ebc:	89 3c 24             	mov    %edi,(%esp)
f0100ebf:	e8 85 03 00 00       	call   f0101249 <strnlen>
f0100ec4:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100ec7:	29 c2                	sub    %eax,%edx
f0100ec9:	89 55 dc             	mov    %edx,-0x24(%ebp)
					putch(padc, putdat);
f0100ecc:	0f be 4d d0          	movsbl -0x30(%ebp),%ecx
f0100ed0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100ed3:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0100ed6:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ed8:	eb 0d                	jmp    f0100ee7 <vprintfmt+0x1e4>
					putch(padc, putdat);
f0100eda:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ede:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ee1:	89 04 24             	mov    %eax,(%esp)
f0100ee4:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ee6:	4f                   	dec    %edi
f0100ee7:	85 ff                	test   %edi,%edi
f0100ee9:	7f ef                	jg     f0100eda <vprintfmt+0x1d7>
f0100eeb:	8b 7d d0             	mov    -0x30(%ebp),%edi
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f0100eee:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ef1:	85 c0                	test   %eax,%eax
f0100ef3:	79 05                	jns    f0100efa <vprintfmt+0x1f7>
f0100ef5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100efa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100efd:	29 c2                	sub    %eax,%edx
f0100eff:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100f02:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0100f05:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0100f08:	eb 42                	jmp    f0100f4c <vprintfmt+0x249>
				if (altflag && (ch < ' ' || ch > '~'))
f0100f0a:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100f0e:	74 1d                	je     f0100f2d <vprintfmt+0x22a>
f0100f10:	0f be d2             	movsbl %dl,%edx
f0100f13:	83 ea 20             	sub    $0x20,%edx
f0100f16:	83 fa 5e             	cmp    $0x5e,%edx
f0100f19:	76 12                	jbe    f0100f2d <vprintfmt+0x22a>
					putch('?', putdat);
f0100f1b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f1f:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100f26:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f29:	ff d1                	call   *%ecx
f0100f2b:	eb 0c                	jmp    f0100f39 <vprintfmt+0x236>
					putch(ch, putdat);
f0100f2d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f31:	89 04 24             	mov    %eax,(%esp)
f0100f34:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f37:	ff d0                	call   *%eax
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f39:	ff 4d dc             	decl   -0x24(%ebp)
f0100f3c:	eb 0e                	jmp    f0100f4c <vprintfmt+0x249>
f0100f3e:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0100f41:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0100f44:	eb 06                	jmp    f0100f4c <vprintfmt+0x249>
f0100f46:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0100f49:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0100f4c:	8a 17                	mov    (%edi),%dl
f0100f4e:	0f be c2             	movsbl %dl,%eax
f0100f51:	47                   	inc    %edi
f0100f52:	85 c0                	test   %eax,%eax
f0100f54:	74 1f                	je     f0100f75 <vprintfmt+0x272>
f0100f56:	85 f6                	test   %esi,%esi
f0100f58:	78 b0                	js     f0100f0a <vprintfmt+0x207>
f0100f5a:	4e                   	dec    %esi
f0100f5b:	79 ad                	jns    f0100f0a <vprintfmt+0x207>
f0100f5d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100f60:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100f63:	eb 16                	jmp    f0100f7b <vprintfmt+0x278>
				putch(' ', putdat);
f0100f65:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f69:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100f70:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0100f72:	4f                   	dec    %edi
f0100f73:	eb 06                	jmp    f0100f7b <vprintfmt+0x278>
f0100f75:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100f78:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100f7b:	85 ff                	test   %edi,%edi
f0100f7d:	7f e6                	jg     f0100f65 <vprintfmt+0x262>
		switch (ch = *(unsigned char *) fmt++) {
f0100f7f:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100f82:	e9 a1 fd ff ff       	jmp    f0100d28 <vprintfmt+0x25>
	if (lflag >= 2)
f0100f87:	83 fa 01             	cmp    $0x1,%edx
f0100f8a:	7e 16                	jle    f0100fa2 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0100f8c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f8f:	8d 50 08             	lea    0x8(%eax),%edx
f0100f92:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f95:	8b 10                	mov    (%eax),%edx
f0100f97:	8b 48 04             	mov    0x4(%eax),%ecx
f0100f9a:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100f9d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100fa0:	eb 2e                	jmp    f0100fd0 <vprintfmt+0x2cd>
	else if (lflag)
f0100fa2:	85 d2                	test   %edx,%edx
f0100fa4:	74 18                	je     f0100fbe <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0100fa6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa9:	8d 50 04             	lea    0x4(%eax),%edx
f0100fac:	89 55 14             	mov    %edx,0x14(%ebp)
f0100faf:	8b 00                	mov    (%eax),%eax
f0100fb1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fb4:	89 c1                	mov    %eax,%ecx
f0100fb6:	c1 f9 1f             	sar    $0x1f,%ecx
f0100fb9:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100fbc:	eb 12                	jmp    f0100fd0 <vprintfmt+0x2cd>
		return va_arg(*ap, int);
f0100fbe:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc1:	8d 50 04             	lea    0x4(%eax),%edx
f0100fc4:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fc7:	8b 00                	mov    (%eax),%eax
f0100fc9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fcc:	99                   	cltd   
f0100fcd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			num = getint(&ap, lflag);
f0100fd0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100fd3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
f0100fd6:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100fda:	0f 89 a2 00 00 00    	jns    f0101082 <vprintfmt+0x37f>
				putch('-', putdat);
f0100fe0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fe4:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0100feb:	ff d6                	call   *%esi
				num = -(long long) num;
f0100fed:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ff0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ff3:	f7 d8                	neg    %eax
f0100ff5:	83 d2 00             	adc    $0x0,%edx
f0100ff8:	f7 da                	neg    %edx
			base = 10;
f0100ffa:	bf 0a 00 00 00       	mov    $0xa,%edi
f0100fff:	e9 83 00 00 00       	jmp    f0101087 <vprintfmt+0x384>
			num = getuint(&ap, lflag);
f0101004:	8d 45 14             	lea    0x14(%ebp),%eax
f0101007:	e8 7b fc ff ff       	call   f0100c87 <getuint>
			base = 10;
f010100c:	bf 0a 00 00 00       	mov    $0xa,%edi
			goto number;
f0101011:	eb 74                	jmp    f0101087 <vprintfmt+0x384>
			putch('X', putdat);
f0101013:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101017:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010101e:	ff d6                	call   *%esi
			putch('X', putdat);
f0101020:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101024:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010102b:	ff d6                	call   *%esi
			putch('X', putdat);
f010102d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101031:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101038:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f010103a:	8b 7d d8             	mov    -0x28(%ebp),%edi
			break;
f010103d:	e9 e6 fc ff ff       	jmp    f0100d28 <vprintfmt+0x25>
			putch('0', putdat);
f0101042:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101046:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010104d:	ff d6                	call   *%esi
			putch('x', putdat);
f010104f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101053:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010105a:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
f010105c:	8b 45 14             	mov    0x14(%ebp),%eax
f010105f:	8d 50 04             	lea    0x4(%eax),%edx
f0101062:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f0101065:	8b 00                	mov    (%eax),%eax
f0101067:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f010106c:	bf 10 00 00 00       	mov    $0x10,%edi
			goto number;
f0101071:	eb 14                	jmp    f0101087 <vprintfmt+0x384>
			num = getuint(&ap, lflag);
f0101073:	8d 45 14             	lea    0x14(%ebp),%eax
f0101076:	e8 0c fc ff ff       	call   f0100c87 <getuint>
			base = 16;
f010107b:	bf 10 00 00 00       	mov    $0x10,%edi
f0101080:	eb 05                	jmp    f0101087 <vprintfmt+0x384>
			base = 10;
f0101082:	bf 0a 00 00 00       	mov    $0xa,%edi
			printnum(putch, putdat, num, base, width, padc);
f0101087:	0f be 4d d0          	movsbl -0x30(%ebp),%ecx
f010108b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010108f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101092:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0101096:	89 7c 24 08          	mov    %edi,0x8(%esp)
f010109a:	89 04 24             	mov    %eax,(%esp)
f010109d:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010a1:	89 da                	mov    %ebx,%edx
f01010a3:	89 f0                	mov    %esi,%eax
f01010a5:	e8 fb fa ff ff       	call   f0100ba5 <printnum>
			break;
f01010aa:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01010ad:	e9 76 fc ff ff       	jmp    f0100d28 <vprintfmt+0x25>
			putch(ch, putdat);
f01010b2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010b6:	89 04 24             	mov    %eax,(%esp)
f01010b9:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f01010bb:	8b 7d d8             	mov    -0x28(%ebp),%edi
			break;
f01010be:	e9 65 fc ff ff       	jmp    f0100d28 <vprintfmt+0x25>
			putch('%', putdat);
f01010c3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01010ce:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01010d0:	eb 01                	jmp    f01010d3 <vprintfmt+0x3d0>
f01010d2:	4f                   	dec    %edi
f01010d3:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01010d7:	75 f9                	jne    f01010d2 <vprintfmt+0x3cf>
f01010d9:	e9 4a fc ff ff       	jmp    f0100d28 <vprintfmt+0x25>
}
f01010de:	83 c4 4c             	add    $0x4c,%esp
f01010e1:	5b                   	pop    %ebx
f01010e2:	5e                   	pop    %esi
f01010e3:	5f                   	pop    %edi
f01010e4:	5d                   	pop    %ebp
f01010e5:	c3                   	ret    

f01010e6 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01010e6:	55                   	push   %ebp
f01010e7:	89 e5                	mov    %esp,%ebp
f01010e9:	83 ec 28             	sub    $0x28,%esp
f01010ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01010ef:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01010f2:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01010f5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01010f9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01010fc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101103:	85 c0                	test   %eax,%eax
f0101105:	74 30                	je     f0101137 <vsnprintf+0x51>
f0101107:	85 d2                	test   %edx,%edx
f0101109:	7e 33                	jle    f010113e <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010110b:	8b 45 14             	mov    0x14(%ebp),%eax
f010110e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101112:	8b 45 10             	mov    0x10(%ebp),%eax
f0101115:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101119:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010111c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101120:	c7 04 24 c1 0c 10 f0 	movl   $0xf0100cc1,(%esp)
f0101127:	e8 d7 fb ff ff       	call   f0100d03 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010112c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010112f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101132:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101135:	eb 0c                	jmp    f0101143 <vsnprintf+0x5d>
		return -E_INVAL;
f0101137:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010113c:	eb 05                	jmp    f0101143 <vsnprintf+0x5d>
f010113e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f0101143:	c9                   	leave  
f0101144:	c3                   	ret    

f0101145 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101145:	55                   	push   %ebp
f0101146:	89 e5                	mov    %esp,%ebp
f0101148:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010114b:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010114e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101152:	8b 45 10             	mov    0x10(%ebp),%eax
f0101155:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101159:	8b 45 0c             	mov    0xc(%ebp),%eax
f010115c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101160:	8b 45 08             	mov    0x8(%ebp),%eax
f0101163:	89 04 24             	mov    %eax,(%esp)
f0101166:	e8 7b ff ff ff       	call   f01010e6 <vsnprintf>
	va_end(ap);

	return rc;
}
f010116b:	c9                   	leave  
f010116c:	c3                   	ret    

f010116d <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010116d:	55                   	push   %ebp
f010116e:	89 e5                	mov    %esp,%ebp
f0101170:	57                   	push   %edi
f0101171:	56                   	push   %esi
f0101172:	53                   	push   %ebx
f0101173:	83 ec 1c             	sub    $0x1c,%esp
f0101176:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101179:	85 c0                	test   %eax,%eax
f010117b:	74 10                	je     f010118d <readline+0x20>
		cprintf("%s", prompt);
f010117d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101181:	c7 04 24 d2 1c 10 f0 	movl   $0xf0101cd2,(%esp)
f0101188:	e8 50 f7 ff ff       	call   f01008dd <cprintf>

	i = 0;
	echoing = iscons(0);
f010118d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101194:	e8 a4 f4 ff ff       	call   f010063d <iscons>
f0101199:	89 c7                	mov    %eax,%edi
	i = 0;
f010119b:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f01011a0:	e8 87 f4 ff ff       	call   f010062c <getchar>
f01011a5:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01011a7:	85 c0                	test   %eax,%eax
f01011a9:	79 17                	jns    f01011c2 <readline+0x55>
			cprintf("read error: %e\n", c);
f01011ab:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011af:	c7 04 24 b4 1e 10 f0 	movl   $0xf0101eb4,(%esp)
f01011b6:	e8 22 f7 ff ff       	call   f01008dd <cprintf>
			return NULL;
f01011bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01011c0:	eb 69                	jmp    f010122b <readline+0xbe>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01011c2:	83 f8 08             	cmp    $0x8,%eax
f01011c5:	74 05                	je     f01011cc <readline+0x5f>
f01011c7:	83 f8 7f             	cmp    $0x7f,%eax
f01011ca:	75 17                	jne    f01011e3 <readline+0x76>
f01011cc:	85 f6                	test   %esi,%esi
f01011ce:	7e 13                	jle    f01011e3 <readline+0x76>
			if (echoing)
f01011d0:	85 ff                	test   %edi,%edi
f01011d2:	74 0c                	je     f01011e0 <readline+0x73>
				cputchar('\b');
f01011d4:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01011db:	e8 3c f4 ff ff       	call   f010061c <cputchar>
			i--;
f01011e0:	4e                   	dec    %esi
f01011e1:	eb bd                	jmp    f01011a0 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01011e3:	83 fb 1f             	cmp    $0x1f,%ebx
f01011e6:	7e 1d                	jle    f0101205 <readline+0x98>
f01011e8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01011ee:	7f 15                	jg     f0101205 <readline+0x98>
			if (echoing)
f01011f0:	85 ff                	test   %edi,%edi
f01011f2:	74 08                	je     f01011fc <readline+0x8f>
				cputchar(c);
f01011f4:	89 1c 24             	mov    %ebx,(%esp)
f01011f7:	e8 20 f4 ff ff       	call   f010061c <cputchar>
			buf[i++] = c;
f01011fc:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101202:	46                   	inc    %esi
f0101203:	eb 9b                	jmp    f01011a0 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101205:	83 fb 0a             	cmp    $0xa,%ebx
f0101208:	74 05                	je     f010120f <readline+0xa2>
f010120a:	83 fb 0d             	cmp    $0xd,%ebx
f010120d:	75 91                	jne    f01011a0 <readline+0x33>
			if (echoing)
f010120f:	85 ff                	test   %edi,%edi
f0101211:	74 0c                	je     f010121f <readline+0xb2>
				cputchar('\n');
f0101213:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f010121a:	e8 fd f3 ff ff       	call   f010061c <cputchar>
			buf[i] = 0;
f010121f:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f0101226:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f010122b:	83 c4 1c             	add    $0x1c,%esp
f010122e:	5b                   	pop    %ebx
f010122f:	5e                   	pop    %esi
f0101230:	5f                   	pop    %edi
f0101231:	5d                   	pop    %ebp
f0101232:	c3                   	ret    

f0101233 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101233:	55                   	push   %ebp
f0101234:	89 e5                	mov    %esp,%ebp
f0101236:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101239:	b8 00 00 00 00       	mov    $0x0,%eax
f010123e:	eb 01                	jmp    f0101241 <strlen+0xe>
		n++;
f0101240:	40                   	inc    %eax
	for (n = 0; *s != '\0'; s++)
f0101241:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101245:	75 f9                	jne    f0101240 <strlen+0xd>
	return n;
}
f0101247:	5d                   	pop    %ebp
f0101248:	c3                   	ret    

f0101249 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101249:	55                   	push   %ebp
f010124a:	89 e5                	mov    %esp,%ebp
f010124c:	8b 4d 08             	mov    0x8(%ebp),%ecx
strnlen(const char *s, size_t size)
f010124f:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101252:	b8 00 00 00 00       	mov    $0x0,%eax
f0101257:	eb 01                	jmp    f010125a <strnlen+0x11>
		n++;
f0101259:	40                   	inc    %eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010125a:	39 d0                	cmp    %edx,%eax
f010125c:	74 06                	je     f0101264 <strnlen+0x1b>
f010125e:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101262:	75 f5                	jne    f0101259 <strnlen+0x10>
	return n;
}
f0101264:	5d                   	pop    %ebp
f0101265:	c3                   	ret    

f0101266 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101266:	55                   	push   %ebp
f0101267:	89 e5                	mov    %esp,%ebp
f0101269:	53                   	push   %ebx
f010126a:	8b 45 08             	mov    0x8(%ebp),%eax
f010126d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101270:	89 c2                	mov    %eax,%edx
f0101272:	8a 19                	mov    (%ecx),%bl
f0101274:	88 1a                	mov    %bl,(%edx)
f0101276:	42                   	inc    %edx
f0101277:	41                   	inc    %ecx
f0101278:	84 db                	test   %bl,%bl
f010127a:	75 f6                	jne    f0101272 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010127c:	5b                   	pop    %ebx
f010127d:	5d                   	pop    %ebp
f010127e:	c3                   	ret    

f010127f <strcat>:

char *
strcat(char *dst, const char *src)
{
f010127f:	55                   	push   %ebp
f0101280:	89 e5                	mov    %esp,%ebp
f0101282:	53                   	push   %ebx
f0101283:	83 ec 08             	sub    $0x8,%esp
f0101286:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101289:	89 1c 24             	mov    %ebx,(%esp)
f010128c:	e8 a2 ff ff ff       	call   f0101233 <strlen>
	strcpy(dst + len, src);
f0101291:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101294:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101298:	01 d8                	add    %ebx,%eax
f010129a:	89 04 24             	mov    %eax,(%esp)
f010129d:	e8 c4 ff ff ff       	call   f0101266 <strcpy>
	return dst;
}
f01012a2:	89 d8                	mov    %ebx,%eax
f01012a4:	83 c4 08             	add    $0x8,%esp
f01012a7:	5b                   	pop    %ebx
f01012a8:	5d                   	pop    %ebp
f01012a9:	c3                   	ret    

f01012aa <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01012aa:	55                   	push   %ebp
f01012ab:	89 e5                	mov    %esp,%ebp
f01012ad:	56                   	push   %esi
f01012ae:	53                   	push   %ebx
f01012af:	8b 75 08             	mov    0x8(%ebp),%esi
f01012b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01012b5:	89 f3                	mov    %esi,%ebx
f01012b7:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01012ba:	89 f2                	mov    %esi,%edx
f01012bc:	eb 0b                	jmp    f01012c9 <strncpy+0x1f>
		*dst++ = *src;
f01012be:	8a 01                	mov    (%ecx),%al
f01012c0:	88 02                	mov    %al,(%edx)
f01012c2:	42                   	inc    %edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01012c3:	80 39 01             	cmpb   $0x1,(%ecx)
f01012c6:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01012c9:	39 da                	cmp    %ebx,%edx
f01012cb:	75 f1                	jne    f01012be <strncpy+0x14>
	}
	return ret;
}
f01012cd:	89 f0                	mov    %esi,%eax
f01012cf:	5b                   	pop    %ebx
f01012d0:	5e                   	pop    %esi
f01012d1:	5d                   	pop    %ebp
f01012d2:	c3                   	ret    

f01012d3 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01012d3:	55                   	push   %ebp
f01012d4:	89 e5                	mov    %esp,%ebp
f01012d6:	56                   	push   %esi
f01012d7:	53                   	push   %ebx
f01012d8:	8b 75 08             	mov    0x8(%ebp),%esi
f01012db:	8b 55 0c             	mov    0xc(%ebp),%edx
f01012de:	8b 45 10             	mov    0x10(%ebp),%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01012e1:	85 c0                	test   %eax,%eax
f01012e3:	74 21                	je     f0101306 <strlcpy+0x33>
strlcpy(char *dst, const char *src, size_t size)
f01012e5:	8d 5c 06 ff          	lea    -0x1(%esi,%eax,1),%ebx
f01012e9:	89 f0                	mov    %esi,%eax
f01012eb:	eb 04                	jmp    f01012f1 <strlcpy+0x1e>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01012ed:	88 08                	mov    %cl,(%eax)
f01012ef:	40                   	inc    %eax
f01012f0:	42                   	inc    %edx
		while (--size > 0 && *src != '\0')
f01012f1:	39 d8                	cmp    %ebx,%eax
f01012f3:	74 0a                	je     f01012ff <strlcpy+0x2c>
f01012f5:	8a 0a                	mov    (%edx),%cl
f01012f7:	84 c9                	test   %cl,%cl
f01012f9:	75 f2                	jne    f01012ed <strlcpy+0x1a>
f01012fb:	89 c2                	mov    %eax,%edx
f01012fd:	eb 02                	jmp    f0101301 <strlcpy+0x2e>
f01012ff:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f0101301:	c6 02 00             	movb   $0x0,(%edx)
f0101304:	eb 02                	jmp    f0101308 <strlcpy+0x35>
	if (size > 0) {
f0101306:	89 f0                	mov    %esi,%eax
	}
	return dst - dst_in;
f0101308:	29 f0                	sub    %esi,%eax
}
f010130a:	5b                   	pop    %ebx
f010130b:	5e                   	pop    %esi
f010130c:	5d                   	pop    %ebp
f010130d:	c3                   	ret    

f010130e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010130e:	55                   	push   %ebp
f010130f:	89 e5                	mov    %esp,%ebp
f0101311:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101314:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101317:	eb 02                	jmp    f010131b <strcmp+0xd>
		p++, q++;
f0101319:	41                   	inc    %ecx
f010131a:	42                   	inc    %edx
	while (*p && *p == *q)
f010131b:	8a 01                	mov    (%ecx),%al
f010131d:	84 c0                	test   %al,%al
f010131f:	74 04                	je     f0101325 <strcmp+0x17>
f0101321:	3a 02                	cmp    (%edx),%al
f0101323:	74 f4                	je     f0101319 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101325:	0f b6 c0             	movzbl %al,%eax
f0101328:	0f b6 12             	movzbl (%edx),%edx
f010132b:	29 d0                	sub    %edx,%eax
}
f010132d:	5d                   	pop    %ebp
f010132e:	c3                   	ret    

f010132f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010132f:	55                   	push   %ebp
f0101330:	89 e5                	mov    %esp,%ebp
f0101332:	53                   	push   %ebx
f0101333:	8b 45 08             	mov    0x8(%ebp),%eax
f0101336:	8b 55 0c             	mov    0xc(%ebp),%edx
strncmp(const char *p, const char *q, size_t n)
f0101339:	89 c3                	mov    %eax,%ebx
f010133b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010133e:	eb 02                	jmp    f0101342 <strncmp+0x13>
		n--, p++, q++;
f0101340:	40                   	inc    %eax
f0101341:	42                   	inc    %edx
	while (n > 0 && *p && *p == *q)
f0101342:	39 d8                	cmp    %ebx,%eax
f0101344:	74 14                	je     f010135a <strncmp+0x2b>
f0101346:	8a 08                	mov    (%eax),%cl
f0101348:	84 c9                	test   %cl,%cl
f010134a:	74 04                	je     f0101350 <strncmp+0x21>
f010134c:	3a 0a                	cmp    (%edx),%cl
f010134e:	74 f0                	je     f0101340 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101350:	0f b6 00             	movzbl (%eax),%eax
f0101353:	0f b6 12             	movzbl (%edx),%edx
f0101356:	29 d0                	sub    %edx,%eax
f0101358:	eb 05                	jmp    f010135f <strncmp+0x30>
		return 0;
f010135a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010135f:	5b                   	pop    %ebx
f0101360:	5d                   	pop    %ebp
f0101361:	c3                   	ret    

f0101362 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101362:	55                   	push   %ebp
f0101363:	89 e5                	mov    %esp,%ebp
f0101365:	8b 45 08             	mov    0x8(%ebp),%eax
f0101368:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010136b:	eb 05                	jmp    f0101372 <strchr+0x10>
		if (*s == c)
f010136d:	38 ca                	cmp    %cl,%dl
f010136f:	74 0c                	je     f010137d <strchr+0x1b>
	for (; *s; s++)
f0101371:	40                   	inc    %eax
f0101372:	8a 10                	mov    (%eax),%dl
f0101374:	84 d2                	test   %dl,%dl
f0101376:	75 f5                	jne    f010136d <strchr+0xb>
			return (char *) s;
	return 0;
f0101378:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010137d:	5d                   	pop    %ebp
f010137e:	c3                   	ret    

f010137f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010137f:	55                   	push   %ebp
f0101380:	89 e5                	mov    %esp,%ebp
f0101382:	8b 45 08             	mov    0x8(%ebp),%eax
f0101385:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f0101388:	eb 05                	jmp    f010138f <strfind+0x10>
		if (*s == c)
f010138a:	38 ca                	cmp    %cl,%dl
f010138c:	74 07                	je     f0101395 <strfind+0x16>
	for (; *s; s++)
f010138e:	40                   	inc    %eax
f010138f:	8a 10                	mov    (%eax),%dl
f0101391:	84 d2                	test   %dl,%dl
f0101393:	75 f5                	jne    f010138a <strfind+0xb>
			break;
	return (char *) s;
}
f0101395:	5d                   	pop    %ebp
f0101396:	c3                   	ret    

f0101397 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101397:	55                   	push   %ebp
f0101398:	89 e5                	mov    %esp,%ebp
f010139a:	57                   	push   %edi
f010139b:	56                   	push   %esi
f010139c:	53                   	push   %ebx
f010139d:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013a0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01013a3:	85 c9                	test   %ecx,%ecx
f01013a5:	74 36                	je     f01013dd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01013a7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01013ad:	75 28                	jne    f01013d7 <memset+0x40>
f01013af:	f6 c1 03             	test   $0x3,%cl
f01013b2:	75 23                	jne    f01013d7 <memset+0x40>
		c &= 0xFF;
f01013b4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01013b8:	89 d3                	mov    %edx,%ebx
f01013ba:	c1 e3 08             	shl    $0x8,%ebx
f01013bd:	89 d6                	mov    %edx,%esi
f01013bf:	c1 e6 18             	shl    $0x18,%esi
f01013c2:	89 d0                	mov    %edx,%eax
f01013c4:	c1 e0 10             	shl    $0x10,%eax
f01013c7:	09 f0                	or     %esi,%eax
f01013c9:	09 c2                	or     %eax,%edx
f01013cb:	89 d0                	mov    %edx,%eax
f01013cd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01013cf:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01013d2:	fc                   	cld    
f01013d3:	f3 ab                	rep stos %eax,%es:(%edi)
f01013d5:	eb 06                	jmp    f01013dd <memset+0x46>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01013d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013da:	fc                   	cld    
f01013db:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01013dd:	89 f8                	mov    %edi,%eax
f01013df:	5b                   	pop    %ebx
f01013e0:	5e                   	pop    %esi
f01013e1:	5f                   	pop    %edi
f01013e2:	5d                   	pop    %ebp
f01013e3:	c3                   	ret    

f01013e4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01013e4:	55                   	push   %ebp
f01013e5:	89 e5                	mov    %esp,%ebp
f01013e7:	57                   	push   %edi
f01013e8:	56                   	push   %esi
f01013e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ec:	8b 75 0c             	mov    0xc(%ebp),%esi
f01013ef:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01013f2:	39 c6                	cmp    %eax,%esi
f01013f4:	73 34                	jae    f010142a <memmove+0x46>
f01013f6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01013f9:	39 d0                	cmp    %edx,%eax
f01013fb:	73 2d                	jae    f010142a <memmove+0x46>
		s += n;
		d += n;
f01013fd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101400:	f6 c2 03             	test   $0x3,%dl
f0101403:	75 1b                	jne    f0101420 <memmove+0x3c>
f0101405:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010140b:	75 13                	jne    f0101420 <memmove+0x3c>
f010140d:	f6 c1 03             	test   $0x3,%cl
f0101410:	75 0e                	jne    f0101420 <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101412:	83 ef 04             	sub    $0x4,%edi
f0101415:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101418:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f010141b:	fd                   	std    
f010141c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010141e:	eb 07                	jmp    f0101427 <memmove+0x43>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101420:	4f                   	dec    %edi
f0101421:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101424:	fd                   	std    
f0101425:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101427:	fc                   	cld    
f0101428:	eb 20                	jmp    f010144a <memmove+0x66>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010142a:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101430:	75 13                	jne    f0101445 <memmove+0x61>
f0101432:	a8 03                	test   $0x3,%al
f0101434:	75 0f                	jne    f0101445 <memmove+0x61>
f0101436:	f6 c1 03             	test   $0x3,%cl
f0101439:	75 0a                	jne    f0101445 <memmove+0x61>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010143b:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f010143e:	89 c7                	mov    %eax,%edi
f0101440:	fc                   	cld    
f0101441:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101443:	eb 05                	jmp    f010144a <memmove+0x66>
		else
			asm volatile("cld; rep movsb\n"
f0101445:	89 c7                	mov    %eax,%edi
f0101447:	fc                   	cld    
f0101448:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010144a:	5e                   	pop    %esi
f010144b:	5f                   	pop    %edi
f010144c:	5d                   	pop    %ebp
f010144d:	c3                   	ret    

f010144e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010144e:	55                   	push   %ebp
f010144f:	89 e5                	mov    %esp,%ebp
f0101451:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101454:	8b 45 10             	mov    0x10(%ebp),%eax
f0101457:	89 44 24 08          	mov    %eax,0x8(%esp)
f010145b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010145e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101462:	8b 45 08             	mov    0x8(%ebp),%eax
f0101465:	89 04 24             	mov    %eax,(%esp)
f0101468:	e8 77 ff ff ff       	call   f01013e4 <memmove>
}
f010146d:	c9                   	leave  
f010146e:	c3                   	ret    

f010146f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010146f:	55                   	push   %ebp
f0101470:	89 e5                	mov    %esp,%ebp
f0101472:	56                   	push   %esi
f0101473:	53                   	push   %ebx
f0101474:	8b 55 08             	mov    0x8(%ebp),%edx
memcmp(const void *v1, const void *v2, size_t n)
f0101477:	89 d6                	mov    %edx,%esi
f0101479:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;
f010147c:	8b 4d 0c             	mov    0xc(%ebp),%ecx

	while (n-- > 0) {
f010147f:	eb 14                	jmp    f0101495 <memcmp+0x26>
		if (*s1 != *s2)
f0101481:	8a 02                	mov    (%edx),%al
f0101483:	8a 19                	mov    (%ecx),%bl
f0101485:	38 d8                	cmp    %bl,%al
f0101487:	74 0a                	je     f0101493 <memcmp+0x24>
			return (int) *s1 - (int) *s2;
f0101489:	0f b6 c0             	movzbl %al,%eax
f010148c:	0f b6 db             	movzbl %bl,%ebx
f010148f:	29 d8                	sub    %ebx,%eax
f0101491:	eb 0b                	jmp    f010149e <memcmp+0x2f>
		s1++, s2++;
f0101493:	42                   	inc    %edx
f0101494:	41                   	inc    %ecx
	while (n-- > 0) {
f0101495:	39 f2                	cmp    %esi,%edx
f0101497:	75 e8                	jne    f0101481 <memcmp+0x12>
	}

	return 0;
f0101499:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010149e:	5b                   	pop    %ebx
f010149f:	5e                   	pop    %esi
f01014a0:	5d                   	pop    %ebp
f01014a1:	c3                   	ret    

f01014a2 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01014a2:	55                   	push   %ebp
f01014a3:	89 e5                	mov    %esp,%ebp
f01014a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01014ab:	89 c2                	mov    %eax,%edx
f01014ad:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01014b0:	eb 05                	jmp    f01014b7 <memfind+0x15>
		if (*(const unsigned char *) s == (unsigned char) c)
f01014b2:	38 08                	cmp    %cl,(%eax)
f01014b4:	74 05                	je     f01014bb <memfind+0x19>
	for (; s < ends; s++)
f01014b6:	40                   	inc    %eax
f01014b7:	39 d0                	cmp    %edx,%eax
f01014b9:	72 f7                	jb     f01014b2 <memfind+0x10>
			break;
	return (void *) s;
}
f01014bb:	5d                   	pop    %ebp
f01014bc:	c3                   	ret    

f01014bd <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01014bd:	55                   	push   %ebp
f01014be:	89 e5                	mov    %esp,%ebp
f01014c0:	57                   	push   %edi
f01014c1:	56                   	push   %esi
f01014c2:	53                   	push   %ebx
f01014c3:	83 ec 04             	sub    $0x4,%esp
f01014c6:	8b 55 08             	mov    0x8(%ebp),%edx
f01014c9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01014cc:	eb 01                	jmp    f01014cf <strtol+0x12>
		s++;
f01014ce:	42                   	inc    %edx
	while (*s == ' ' || *s == '\t')
f01014cf:	8a 02                	mov    (%edx),%al
f01014d1:	3c 20                	cmp    $0x20,%al
f01014d3:	74 f9                	je     f01014ce <strtol+0x11>
f01014d5:	3c 09                	cmp    $0x9,%al
f01014d7:	74 f5                	je     f01014ce <strtol+0x11>

	// plus/minus sign
	if (*s == '+')
f01014d9:	3c 2b                	cmp    $0x2b,%al
f01014db:	75 08                	jne    f01014e5 <strtol+0x28>
		s++;
f01014dd:	42                   	inc    %edx
	int neg = 0;
f01014de:	bf 00 00 00 00       	mov    $0x0,%edi
f01014e3:	eb 13                	jmp    f01014f8 <strtol+0x3b>
	else if (*s == '-')
f01014e5:	3c 2d                	cmp    $0x2d,%al
f01014e7:	75 0a                	jne    f01014f3 <strtol+0x36>
		s++, neg = 1;
f01014e9:	8d 52 01             	lea    0x1(%edx),%edx
f01014ec:	bf 01 00 00 00       	mov    $0x1,%edi
f01014f1:	eb 05                	jmp    f01014f8 <strtol+0x3b>
	int neg = 0;
f01014f3:	bf 00 00 00 00       	mov    $0x0,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01014f8:	85 db                	test   %ebx,%ebx
f01014fa:	74 05                	je     f0101501 <strtol+0x44>
f01014fc:	83 fb 10             	cmp    $0x10,%ebx
f01014ff:	75 28                	jne    f0101529 <strtol+0x6c>
f0101501:	8a 02                	mov    (%edx),%al
f0101503:	3c 30                	cmp    $0x30,%al
f0101505:	75 10                	jne    f0101517 <strtol+0x5a>
f0101507:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010150b:	75 0a                	jne    f0101517 <strtol+0x5a>
		s += 2, base = 16;
f010150d:	83 c2 02             	add    $0x2,%edx
f0101510:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101515:	eb 12                	jmp    f0101529 <strtol+0x6c>
	else if (base == 0 && s[0] == '0')
f0101517:	85 db                	test   %ebx,%ebx
f0101519:	75 0e                	jne    f0101529 <strtol+0x6c>
f010151b:	3c 30                	cmp    $0x30,%al
f010151d:	75 05                	jne    f0101524 <strtol+0x67>
		s++, base = 8;
f010151f:	42                   	inc    %edx
f0101520:	b3 08                	mov    $0x8,%bl
f0101522:	eb 05                	jmp    f0101529 <strtol+0x6c>
	else if (base == 0)
		base = 10;
f0101524:	bb 0a 00 00 00       	mov    $0xa,%ebx
f0101529:	b8 00 00 00 00       	mov    $0x0,%eax
f010152e:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101531:	8a 0a                	mov    (%edx),%cl
f0101533:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101536:	89 f3                	mov    %esi,%ebx
f0101538:	80 fb 09             	cmp    $0x9,%bl
f010153b:	77 08                	ja     f0101545 <strtol+0x88>
			dig = *s - '0';
f010153d:	0f be c9             	movsbl %cl,%ecx
f0101540:	83 e9 30             	sub    $0x30,%ecx
f0101543:	eb 22                	jmp    f0101567 <strtol+0xaa>
		else if (*s >= 'a' && *s <= 'z')
f0101545:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0101548:	89 f3                	mov    %esi,%ebx
f010154a:	80 fb 19             	cmp    $0x19,%bl
f010154d:	77 08                	ja     f0101557 <strtol+0x9a>
			dig = *s - 'a' + 10;
f010154f:	0f be c9             	movsbl %cl,%ecx
f0101552:	83 e9 57             	sub    $0x57,%ecx
f0101555:	eb 10                	jmp    f0101567 <strtol+0xaa>
		else if (*s >= 'A' && *s <= 'Z')
f0101557:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010155a:	89 f3                	mov    %esi,%ebx
f010155c:	80 fb 19             	cmp    $0x19,%bl
f010155f:	77 14                	ja     f0101575 <strtol+0xb8>
			dig = *s - 'A' + 10;
f0101561:	0f be c9             	movsbl %cl,%ecx
f0101564:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101567:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f010156a:	7d 0d                	jge    f0101579 <strtol+0xbc>
			break;
		s++, val = (val * base) + dig;
f010156c:	42                   	inc    %edx
f010156d:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0101571:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101573:	eb bc                	jmp    f0101531 <strtol+0x74>
		else if (*s >= 'A' && *s <= 'Z')
f0101575:	89 c1                	mov    %eax,%ecx
f0101577:	eb 02                	jmp    f010157b <strtol+0xbe>
		if (dig >= base)
f0101579:	89 c1                	mov    %eax,%ecx

	if (endptr)
f010157b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010157f:	74 05                	je     f0101586 <strtol+0xc9>
		*endptr = (char *) s;
f0101581:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101584:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101586:	85 ff                	test   %edi,%edi
f0101588:	74 04                	je     f010158e <strtol+0xd1>
f010158a:	89 c8                	mov    %ecx,%eax
f010158c:	f7 d8                	neg    %eax
}
f010158e:	83 c4 04             	add    $0x4,%esp
f0101591:	5b                   	pop    %ebx
f0101592:	5e                   	pop    %esi
f0101593:	5f                   	pop    %edi
f0101594:	5d                   	pop    %ebp
f0101595:	c3                   	ret    

f0101596 <__udivdi3>:
f0101596:	55                   	push   %ebp
f0101597:	89 e5                	mov    %esp,%ebp
f0101599:	57                   	push   %edi
f010159a:	56                   	push   %esi
f010159b:	83 ec 10             	sub    $0x10,%esp
f010159e:	8b 75 08             	mov    0x8(%ebp),%esi
f01015a1:	8b 55 10             	mov    0x10(%ebp),%edx
f01015a4:	89 75 ec             	mov    %esi,-0x14(%ebp)
f01015a7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01015aa:	89 55 f0             	mov    %edx,-0x10(%ebp)
f01015ad:	8b 45 14             	mov    0x14(%ebp),%eax
f01015b0:	89 55 f4             	mov    %edx,-0xc(%ebp)
f01015b3:	85 c0                	test   %eax,%eax
f01015b5:	75 3a                	jne    f01015f1 <__udivdi3+0x5b>
f01015b7:	39 fa                	cmp    %edi,%edx
f01015b9:	76 0e                	jbe    f01015c9 <__udivdi3+0x33>
f01015bb:	89 fa                	mov    %edi,%edx
f01015bd:	89 f0                	mov    %esi,%eax
f01015bf:	f7 75 f0             	divl   -0x10(%ebp)
f01015c2:	89 c6                	mov    %eax,%esi
f01015c4:	e9 c6 00 00 00       	jmp    f010168f <__udivdi3+0xf9>
f01015c9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f01015cd:	75 0d                	jne    f01015dc <__udivdi3+0x46>
f01015cf:	b8 01 00 00 00       	mov    $0x1,%eax
f01015d4:	31 d2                	xor    %edx,%edx
f01015d6:	f7 75 f4             	divl   -0xc(%ebp)
f01015d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01015dc:	31 d2                	xor    %edx,%edx
f01015de:	89 f8                	mov    %edi,%eax
f01015e0:	f7 75 f4             	divl   -0xc(%ebp)
f01015e3:	89 c1                	mov    %eax,%ecx
f01015e5:	89 f0                	mov    %esi,%eax
f01015e7:	f7 75 f4             	divl   -0xc(%ebp)
f01015ea:	89 c6                	mov    %eax,%esi
f01015ec:	e9 a0 00 00 00       	jmp    f0101691 <__udivdi3+0xfb>
f01015f1:	39 f8                	cmp    %edi,%eax
f01015f3:	0f 87 90 00 00 00    	ja     f0101689 <__udivdi3+0xf3>
f01015f9:	0f bd c8             	bsr    %eax,%ecx
f01015fc:	83 f1 1f             	xor    $0x1f,%ecx
f01015ff:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f0101602:	75 15                	jne    f0101619 <__udivdi3+0x83>
f0101604:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101607:	31 c9                	xor    %ecx,%ecx
f0101609:	39 55 ec             	cmp    %edx,-0x14(%ebp)
f010160c:	73 04                	jae    f0101612 <__udivdi3+0x7c>
f010160e:	39 c7                	cmp    %eax,%edi
f0101610:	76 79                	jbe    f010168b <__udivdi3+0xf5>
f0101612:	be 01 00 00 00       	mov    $0x1,%esi
f0101617:	eb 78                	jmp    f0101691 <__udivdi3+0xfb>
f0101619:	89 c2                	mov    %eax,%edx
f010161b:	8a 4d f4             	mov    -0xc(%ebp),%cl
f010161e:	d3 e2                	shl    %cl,%edx
f0101620:	b8 20 00 00 00       	mov    $0x20,%eax
f0101625:	2b 45 f4             	sub    -0xc(%ebp),%eax
f0101628:	8b 75 f0             	mov    -0x10(%ebp),%esi
f010162b:	88 c1                	mov    %al,%cl
f010162d:	d3 ee                	shr    %cl,%esi
f010162f:	09 d6                	or     %edx,%esi
f0101631:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101634:	8a 4d f4             	mov    -0xc(%ebp),%cl
f0101637:	d3 e2                	shl    %cl,%edx
f0101639:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010163c:	89 fa                	mov    %edi,%edx
f010163e:	88 c1                	mov    %al,%cl
f0101640:	d3 ea                	shr    %cl,%edx
f0101642:	89 55 f0             	mov    %edx,-0x10(%ebp)
f0101645:	89 fa                	mov    %edi,%edx
f0101647:	8a 4d f4             	mov    -0xc(%ebp),%cl
f010164a:	d3 e2                	shl    %cl,%edx
f010164c:	8b 7d ec             	mov    -0x14(%ebp),%edi
f010164f:	88 c1                	mov    %al,%cl
f0101651:	d3 ef                	shr    %cl,%edi
f0101653:	09 d7                	or     %edx,%edi
f0101655:	89 f8                	mov    %edi,%eax
f0101657:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010165a:	f7 f6                	div    %esi
f010165c:	89 55 f0             	mov    %edx,-0x10(%ebp)
f010165f:	89 c7                	mov    %eax,%edi
f0101661:	89 c6                	mov    %eax,%esi
f0101663:	f7 65 e8             	mull   -0x18(%ebp)
f0101666:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0101669:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f010166c:	39 ca                	cmp    %ecx,%edx
f010166e:	77 14                	ja     f0101684 <__udivdi3+0xee>
f0101670:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101673:	8a 4d f4             	mov    -0xc(%ebp),%cl
f0101676:	d3 e2                	shl    %cl,%edx
f0101678:	39 d0                	cmp    %edx,%eax
f010167a:	76 13                	jbe    f010168f <__udivdi3+0xf9>
f010167c:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010167f:	39 55 e8             	cmp    %edx,-0x18(%ebp)
f0101682:	75 0b                	jne    f010168f <__udivdi3+0xf9>
f0101684:	8d 77 ff             	lea    -0x1(%edi),%esi
f0101687:	eb 06                	jmp    f010168f <__udivdi3+0xf9>
f0101689:	31 c9                	xor    %ecx,%ecx
f010168b:	31 f6                	xor    %esi,%esi
f010168d:	eb 02                	jmp    f0101691 <__udivdi3+0xfb>
f010168f:	31 c9                	xor    %ecx,%ecx
f0101691:	89 f0                	mov    %esi,%eax
f0101693:	89 ca                	mov    %ecx,%edx
f0101695:	83 c4 10             	add    $0x10,%esp
f0101698:	5e                   	pop    %esi
f0101699:	5f                   	pop    %edi
f010169a:	5d                   	pop    %ebp
f010169b:	c3                   	ret    

f010169c <__umoddi3>:
f010169c:	55                   	push   %ebp
f010169d:	89 e5                	mov    %esp,%ebp
f010169f:	57                   	push   %edi
f01016a0:	56                   	push   %esi
f01016a1:	83 ec 20             	sub    $0x20,%esp
f01016a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01016a7:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01016aa:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01016ad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01016b0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016b3:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01016b6:	8b 55 14             	mov    0x14(%ebp),%edx
f01016b9:	89 55 ec             	mov    %edx,-0x14(%ebp)
f01016bc:	89 c7                	mov    %eax,%edi
f01016be:	89 f2                	mov    %esi,%edx
f01016c0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01016c4:	75 28                	jne    f01016ee <__umoddi3+0x52>
f01016c6:	39 f1                	cmp    %esi,%ecx
f01016c8:	76 02                	jbe    f01016cc <__umoddi3+0x30>
f01016ca:	eb 17                	jmp    f01016e3 <__umoddi3+0x47>
f01016cc:	85 c9                	test   %ecx,%ecx
f01016ce:	75 0b                	jne    f01016db <__umoddi3+0x3f>
f01016d0:	b8 01 00 00 00       	mov    $0x1,%eax
f01016d5:	31 d2                	xor    %edx,%edx
f01016d7:	f7 f1                	div    %ecx
f01016d9:	89 c1                	mov    %eax,%ecx
f01016db:	89 f0                	mov    %esi,%eax
f01016dd:	31 d2                	xor    %edx,%edx
f01016df:	f7 f1                	div    %ecx
f01016e1:	89 f8                	mov    %edi,%eax
f01016e3:	f7 f1                	div    %ecx
f01016e5:	89 d0                	mov    %edx,%eax
f01016e7:	31 d2                	xor    %edx,%edx
f01016e9:	e9 bf 00 00 00       	jmp    f01017ad <__umoddi3+0x111>
f01016ee:	39 75 ec             	cmp    %esi,-0x14(%ebp)
f01016f1:	76 0a                	jbe    f01016fd <__umoddi3+0x61>
f01016f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01016f6:	89 f2                	mov    %esi,%edx
f01016f8:	e9 b0 00 00 00       	jmp    f01017ad <__umoddi3+0x111>
f01016fd:	0f bd 45 ec          	bsr    -0x14(%ebp),%eax
f0101701:	83 f0 1f             	xor    $0x1f,%eax
f0101704:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101707:	75 17                	jne    f0101720 <__umoddi3+0x84>
f0101709:	39 cf                	cmp    %ecx,%edi
f010170b:	73 05                	jae    f0101712 <__umoddi3+0x76>
f010170d:	3b 75 ec             	cmp    -0x14(%ebp),%esi
f0101710:	76 07                	jbe    f0101719 <__umoddi3+0x7d>
f0101712:	89 f2                	mov    %esi,%edx
f0101714:	29 cf                	sub    %ecx,%edi
f0101716:	1b 55 ec             	sbb    -0x14(%ebp),%edx
f0101719:	89 f8                	mov    %edi,%eax
f010171b:	e9 8d 00 00 00       	jmp    f01017ad <__umoddi3+0x111>
f0101720:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101723:	8a 4d f4             	mov    -0xc(%ebp),%cl
f0101726:	d3 e0                	shl    %cl,%eax
f0101728:	c7 45 ec 20 00 00 00 	movl   $0x20,-0x14(%ebp)
f010172f:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f0101732:	29 4d ec             	sub    %ecx,-0x14(%ebp)
f0101735:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101738:	8a 4d ec             	mov    -0x14(%ebp),%cl
f010173b:	d3 ea                	shr    %cl,%edx
f010173d:	09 c2                	or     %eax,%edx
f010173f:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0101742:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101745:	8a 4d f4             	mov    -0xc(%ebp),%cl
f0101748:	d3 e0                	shl    %cl,%eax
f010174a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010174d:	89 f2                	mov    %esi,%edx
f010174f:	8a 4d ec             	mov    -0x14(%ebp),%cl
f0101752:	d3 ea                	shr    %cl,%edx
f0101754:	8a 4d f4             	mov    -0xc(%ebp),%cl
f0101757:	d3 e6                	shl    %cl,%esi
f0101759:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010175c:	8a 4d ec             	mov    -0x14(%ebp),%cl
f010175f:	d3 e8                	shr    %cl,%eax
f0101761:	09 f0                	or     %esi,%eax
f0101763:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101766:	8a 4d f4             	mov    -0xc(%ebp),%cl
f0101769:	d3 e6                	shl    %cl,%esi
f010176b:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f010176e:	f7 75 e8             	divl   -0x18(%ebp)
f0101771:	89 d6                	mov    %edx,%esi
f0101773:	f7 65 f0             	mull   -0x10(%ebp)
f0101776:	89 c7                	mov    %eax,%edi
f0101778:	89 d1                	mov    %edx,%ecx
f010177a:	39 f2                	cmp    %esi,%edx
f010177c:	77 09                	ja     f0101787 <__umoddi3+0xeb>
f010177e:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f0101781:	76 0e                	jbe    f0101791 <__umoddi3+0xf5>
f0101783:	39 f2                	cmp    %esi,%edx
f0101785:	75 0a                	jne    f0101791 <__umoddi3+0xf5>
f0101787:	89 d1                	mov    %edx,%ecx
f0101789:	89 c7                	mov    %eax,%edi
f010178b:	2b 7d f0             	sub    -0x10(%ebp),%edi
f010178e:	1b 4d e8             	sbb    -0x18(%ebp),%ecx
f0101791:	89 f2                	mov    %esi,%edx
f0101793:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101796:	29 f8                	sub    %edi,%eax
f0101798:	19 ca                	sbb    %ecx,%edx
f010179a:	8a 4d f4             	mov    -0xc(%ebp),%cl
f010179d:	d3 e8                	shr    %cl,%eax
f010179f:	89 d6                	mov    %edx,%esi
f01017a1:	8a 4d ec             	mov    -0x14(%ebp),%cl
f01017a4:	d3 e6                	shl    %cl,%esi
f01017a6:	09 f0                	or     %esi,%eax
f01017a8:	8a 4d f4             	mov    -0xc(%ebp),%cl
f01017ab:	d3 ea                	shr    %cl,%edx
f01017ad:	83 c4 20             	add    $0x20,%esp
f01017b0:	5e                   	pop    %esi
f01017b1:	5f                   	pop    %edi
f01017b2:	5d                   	pop    %ebp
f01017b3:	c3                   	ret    
