
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
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

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
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 00 19 10 f0       	push   $0xf0101900
f0100050:	e8 33 09 00 00       	call   f0100988 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 0a 07 00 00       	call   f0100785 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 1c 19 10 f0       	push   $0xf010191c
f0100087:	e8 fc 08 00 00       	call   f0100988 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 40 29 11 f0       	mov    $0xf0112940,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 b9 13 00 00       	call   f010146a <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 9d 04 00 00       	call   f0100553 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 37 19 10 f0       	push   $0xf0101937
f01000c3:	e8 c0 08 00 00       	call   f0100988 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 3a 07 00 00       	call   f010081b <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 44 29 11 f0 00 	cmpl   $0x0,0xf0112944
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 44 29 11 f0    	mov    %esi,0xf0112944

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 52 19 10 f0       	push   $0xf0101952
f0100110:	e8 73 08 00 00       	call   f0100988 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 43 08 00 00       	call   f0100962 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 8e 19 10 f0 	movl   $0xf010198e,(%esp)
f0100126:	e8 5d 08 00 00       	call   f0100988 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 e3 06 00 00       	call   f010081b <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 6a 19 10 f0       	push   $0xf010196a
f0100152:	e8 31 08 00 00       	call   f0100988 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 ff 07 00 00       	call   f0100962 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 8e 19 10 f0 	movl   $0xf010198e,(%esp)
f010016a:	e8 19 08 00 00       	call   f0100988 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f8 00 00 00    	je     f01002df <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001e7:	a8 20                	test   $0x20,%al
f01001e9:	0f 85 f6 00 00 00    	jne    f01002e5 <kbd_proc_data+0x10c>
f01001ef:	ba 60 00 00 00       	mov    $0x60,%edx
f01001f4:	ec                   	in     (%dx),%al
f01001f5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001f7:	3c e0                	cmp    $0xe0,%al
f01001f9:	75 0d                	jne    f0100208 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001fb:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100202:	b8 00 00 00 00       	mov    $0x0,%eax
f0100207:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100208:	55                   	push   %ebp
f0100209:	89 e5                	mov    %esp,%ebp
f010020b:	53                   	push   %ebx
f010020c:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010020f:	84 c0                	test   %al,%al
f0100211:	79 36                	jns    f0100249 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100213:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100219:	89 cb                	mov    %ecx,%ebx
f010021b:	83 e3 40             	and    $0x40,%ebx
f010021e:	83 e0 7f             	and    $0x7f,%eax
f0100221:	85 db                	test   %ebx,%ebx
f0100223:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100226:	0f b6 d2             	movzbl %dl,%edx
f0100229:	0f b6 82 e0 1a 10 f0 	movzbl -0xfefe520(%edx),%eax
f0100230:	83 c8 40             	or     $0x40,%eax
f0100233:	0f b6 c0             	movzbl %al,%eax
f0100236:	f7 d0                	not    %eax
f0100238:	21 c8                	and    %ecx,%eax
f010023a:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f010023f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100244:	e9 a4 00 00 00       	jmp    f01002ed <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100249:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010024f:	f6 c1 40             	test   $0x40,%cl
f0100252:	74 0e                	je     f0100262 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100254:	83 c8 80             	or     $0xffffff80,%eax
f0100257:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100259:	83 e1 bf             	and    $0xffffffbf,%ecx
f010025c:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100262:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 82 e0 1a 10 f0 	movzbl -0xfefe520(%edx),%eax
f010026c:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100272:	0f b6 8a e0 19 10 f0 	movzbl -0xfefe620(%edx),%ecx
f0100279:	31 c8                	xor    %ecx,%eax
f010027b:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100280:	89 c1                	mov    %eax,%ecx
f0100282:	83 e1 03             	and    $0x3,%ecx
f0100285:	8b 0c 8d c0 19 10 f0 	mov    -0xfefe640(,%ecx,4),%ecx
f010028c:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100290:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100293:	a8 08                	test   $0x8,%al
f0100295:	74 1b                	je     f01002b2 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100297:	89 da                	mov    %ebx,%edx
f0100299:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010029c:	83 f9 19             	cmp    $0x19,%ecx
f010029f:	77 05                	ja     f01002a6 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01002a1:	83 eb 20             	sub    $0x20,%ebx
f01002a4:	eb 0c                	jmp    f01002b2 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01002a6:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a9:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002ac:	83 fa 19             	cmp    $0x19,%edx
f01002af:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002b2:	f7 d0                	not    %eax
f01002b4:	a8 06                	test   $0x6,%al
f01002b6:	75 33                	jne    f01002eb <kbd_proc_data+0x112>
f01002b8:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002be:	75 2b                	jne    f01002eb <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01002c0:	83 ec 0c             	sub    $0xc,%esp
f01002c3:	68 84 19 10 f0       	push   $0xf0101984
f01002c8:	e8 bb 06 00 00       	call   f0100988 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002cd:	ba 92 00 00 00       	mov    $0x92,%edx
f01002d2:	b8 03 00 00 00       	mov    $0x3,%eax
f01002d7:	ee                   	out    %al,(%dx)
f01002d8:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
f01002dd:	eb 0e                	jmp    f01002ed <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002e4:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ea:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002eb:	89 d8                	mov    %ebx,%eax
}
f01002ed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002f0:	c9                   	leave  
f01002f1:	c3                   	ret    

f01002f2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002f2:	55                   	push   %ebp
f01002f3:	89 e5                	mov    %esp,%ebp
f01002f5:	57                   	push   %edi
f01002f6:	56                   	push   %esi
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 1c             	sub    $0x1c,%esp
f01002fb:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002fd:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100302:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100307:	b9 84 00 00 00       	mov    $0x84,%ecx
f010030c:	eb 09                	jmp    f0100317 <cons_putc+0x25>
f010030e:	89 ca                	mov    %ecx,%edx
f0100310:	ec                   	in     (%dx),%al
f0100311:	ec                   	in     (%dx),%al
f0100312:	ec                   	in     (%dx),%al
f0100313:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100314:	83 c3 01             	add    $0x1,%ebx
f0100317:	89 f2                	mov    %esi,%edx
f0100319:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 08                	jne    f0100326 <cons_putc+0x34>
f010031e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100324:	7e e8                	jle    f010030e <cons_putc+0x1c>
f0100326:	89 f8                	mov    %edi,%eax
f0100328:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010032b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100330:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100331:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100336:	be 79 03 00 00       	mov    $0x379,%esi
f010033b:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100340:	eb 09                	jmp    f010034b <cons_putc+0x59>
f0100342:	89 ca                	mov    %ecx,%edx
f0100344:	ec                   	in     (%dx),%al
f0100345:	ec                   	in     (%dx),%al
f0100346:	ec                   	in     (%dx),%al
f0100347:	ec                   	in     (%dx),%al
f0100348:	83 c3 01             	add    $0x1,%ebx
f010034b:	89 f2                	mov    %esi,%edx
f010034d:	ec                   	in     (%dx),%al
f010034e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100354:	7f 04                	jg     f010035a <cons_putc+0x68>
f0100356:	84 c0                	test   %al,%al
f0100358:	79 e8                	jns    f0100342 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010035a:	ba 78 03 00 00       	mov    $0x378,%edx
f010035f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100363:	ee                   	out    %al,(%dx)
f0100364:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100369:	b8 0d 00 00 00       	mov    $0xd,%eax
f010036e:	ee                   	out    %al,(%dx)
f010036f:	b8 08 00 00 00       	mov    $0x8,%eax
f0100374:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100375:	89 fa                	mov    %edi,%edx
f0100377:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010037d:	89 f8                	mov    %edi,%eax
f010037f:	80 cc 07             	or     $0x7,%ah
f0100382:	85 d2                	test   %edx,%edx
f0100384:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100387:	89 f8                	mov    %edi,%eax
f0100389:	0f b6 c0             	movzbl %al,%eax
f010038c:	83 f8 09             	cmp    $0x9,%eax
f010038f:	74 74                	je     f0100405 <cons_putc+0x113>
f0100391:	83 f8 09             	cmp    $0x9,%eax
f0100394:	7f 0a                	jg     f01003a0 <cons_putc+0xae>
f0100396:	83 f8 08             	cmp    $0x8,%eax
f0100399:	74 14                	je     f01003af <cons_putc+0xbd>
f010039b:	e9 99 00 00 00       	jmp    f0100439 <cons_putc+0x147>
f01003a0:	83 f8 0a             	cmp    $0xa,%eax
f01003a3:	74 3a                	je     f01003df <cons_putc+0xed>
f01003a5:	83 f8 0d             	cmp    $0xd,%eax
f01003a8:	74 3d                	je     f01003e7 <cons_putc+0xf5>
f01003aa:	e9 8a 00 00 00       	jmp    f0100439 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003af:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003b6:	66 85 c0             	test   %ax,%ax
f01003b9:	0f 84 e6 00 00 00    	je     f01004a5 <cons_putc+0x1b3>
			crt_pos--;
f01003bf:	83 e8 01             	sub    $0x1,%eax
f01003c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003c8:	0f b7 c0             	movzwl %ax,%eax
f01003cb:	66 81 e7 00 ff       	and    $0xff00,%di
f01003d0:	83 cf 20             	or     $0x20,%edi
f01003d3:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003d9:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003dd:	eb 78                	jmp    f0100457 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003df:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003e6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003e7:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003ee:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003f4:	c1 e8 16             	shr    $0x16,%eax
f01003f7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003fa:	c1 e0 04             	shl    $0x4,%eax
f01003fd:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100403:	eb 52                	jmp    f0100457 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f0100405:	b8 20 00 00 00       	mov    $0x20,%eax
f010040a:	e8 e3 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010040f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100414:	e8 d9 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100419:	b8 20 00 00 00       	mov    $0x20,%eax
f010041e:	e8 cf fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100423:	b8 20 00 00 00       	mov    $0x20,%eax
f0100428:	e8 c5 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010042d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100432:	e8 bb fe ff ff       	call   f01002f2 <cons_putc>
f0100437:	eb 1e                	jmp    f0100457 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100439:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100440:	8d 50 01             	lea    0x1(%eax),%edx
f0100443:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010044a:	0f b7 c0             	movzwl %ax,%eax
f010044d:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100453:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100457:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010045e:	cf 07 
f0100460:	76 43                	jbe    f01004a5 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100462:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100467:	83 ec 04             	sub    $0x4,%esp
f010046a:	68 00 0f 00 00       	push   $0xf00
f010046f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100475:	52                   	push   %edx
f0100476:	50                   	push   %eax
f0100477:	e8 3b 10 00 00       	call   f01014b7 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010047c:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100482:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100488:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010048e:	83 c4 10             	add    $0x10,%esp
f0100491:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100496:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100499:	39 d0                	cmp    %edx,%eax
f010049b:	75 f4                	jne    f0100491 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010049d:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004a4:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004a5:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004ab:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004b0:	89 ca                	mov    %ecx,%edx
f01004b2:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004b3:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ba:	8d 71 01             	lea    0x1(%ecx),%esi
f01004bd:	89 d8                	mov    %ebx,%eax
f01004bf:	66 c1 e8 08          	shr    $0x8,%ax
f01004c3:	89 f2                	mov    %esi,%edx
f01004c5:	ee                   	out    %al,(%dx)
f01004c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004cb:	89 ca                	mov    %ecx,%edx
f01004cd:	ee                   	out    %al,(%dx)
f01004ce:	89 d8                	mov    %ebx,%eax
f01004d0:	89 f2                	mov    %esi,%edx
f01004d2:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004d6:	5b                   	pop    %ebx
f01004d7:	5e                   	pop    %esi
f01004d8:	5f                   	pop    %edi
f01004d9:	5d                   	pop    %ebp
f01004da:	c3                   	ret    

f01004db <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004db:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004e2:	74 11                	je     f01004f5 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004e4:	55                   	push   %ebp
f01004e5:	89 e5                	mov    %esp,%ebp
f01004e7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004ea:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004ef:	e8 a2 fc ff ff       	call   f0100196 <cons_intr>
}
f01004f4:	c9                   	leave  
f01004f5:	f3 c3                	repz ret 

f01004f7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004f7:	55                   	push   %ebp
f01004f8:	89 e5                	mov    %esp,%ebp
f01004fa:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004fd:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f0100502:	e8 8f fc ff ff       	call   f0100196 <cons_intr>
}
f0100507:	c9                   	leave  
f0100508:	c3                   	ret    

f0100509 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100509:	55                   	push   %ebp
f010050a:	89 e5                	mov    %esp,%ebp
f010050c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010050f:	e8 c7 ff ff ff       	call   f01004db <serial_intr>
	kbd_intr();
f0100514:	e8 de ff ff ff       	call   f01004f7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100519:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010051e:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100524:	74 26                	je     f010054c <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100526:	8d 50 01             	lea    0x1(%eax),%edx
f0100529:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010052f:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100536:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100538:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010053e:	75 11                	jne    f0100551 <cons_getc+0x48>
			cons.rpos = 0;
f0100540:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100547:	00 00 00 
f010054a:	eb 05                	jmp    f0100551 <cons_getc+0x48>
		return c;
	}
	return 0;
f010054c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100551:	c9                   	leave  
f0100552:	c3                   	ret    

f0100553 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100553:	55                   	push   %ebp
f0100554:	89 e5                	mov    %esp,%ebp
f0100556:	57                   	push   %edi
f0100557:	56                   	push   %esi
f0100558:	53                   	push   %ebx
f0100559:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010055c:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100563:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010056a:	5a a5 
	if (*cp != 0xA55A) {
f010056c:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100573:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100577:	74 11                	je     f010058a <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100579:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100580:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100583:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100588:	eb 16                	jmp    f01005a0 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010058a:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100591:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f0100598:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010059b:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a0:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f01005a6:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ab:	89 fa                	mov    %edi,%edx
f01005ad:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ae:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b1:	89 da                	mov    %ebx,%edx
f01005b3:	ec                   	in     (%dx),%al
f01005b4:	0f b6 c8             	movzbl %al,%ecx
f01005b7:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ba:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005bf:	89 fa                	mov    %edi,%edx
f01005c1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005c5:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005cb:	0f b6 c0             	movzbl %al,%eax
f01005ce:	09 c8                	or     %ecx,%eax
f01005d0:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005db:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e0:	89 f2                	mov    %esi,%edx
f01005e2:	ee                   	out    %al,(%dx)
f01005e3:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005e8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ed:	ee                   	out    %al,(%dx)
f01005ee:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005f3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005f8:	89 da                	mov    %ebx,%edx
f01005fa:	ee                   	out    %al,(%dx)
f01005fb:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100600:	b8 00 00 00 00       	mov    $0x0,%eax
f0100605:	ee                   	out    %al,(%dx)
f0100606:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010060b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100610:	ee                   	out    %al,(%dx)
f0100611:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100616:	b8 00 00 00 00       	mov    $0x0,%eax
f010061b:	ee                   	out    %al,(%dx)
f010061c:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100621:	b8 01 00 00 00       	mov    $0x1,%eax
f0100626:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100627:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010062f:	3c ff                	cmp    $0xff,%al
f0100631:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100638:	89 f2                	mov    %esi,%edx
f010063a:	ec                   	in     (%dx),%al
f010063b:	89 da                	mov    %ebx,%edx
f010063d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010063e:	80 f9 ff             	cmp    $0xff,%cl
f0100641:	75 10                	jne    f0100653 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100643:	83 ec 0c             	sub    $0xc,%esp
f0100646:	68 90 19 10 f0       	push   $0xf0101990
f010064b:	e8 38 03 00 00       	call   f0100988 <cprintf>
f0100650:	83 c4 10             	add    $0x10,%esp
}
f0100653:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100656:	5b                   	pop    %ebx
f0100657:	5e                   	pop    %esi
f0100658:	5f                   	pop    %edi
f0100659:	5d                   	pop    %ebp
f010065a:	c3                   	ret    

f010065b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010065b:	55                   	push   %ebp
f010065c:	89 e5                	mov    %esp,%ebp
f010065e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100661:	8b 45 08             	mov    0x8(%ebp),%eax
f0100664:	e8 89 fc ff ff       	call   f01002f2 <cons_putc>
}
f0100669:	c9                   	leave  
f010066a:	c3                   	ret    

f010066b <getchar>:

int
getchar(void)
{
f010066b:	55                   	push   %ebp
f010066c:	89 e5                	mov    %esp,%ebp
f010066e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100671:	e8 93 fe ff ff       	call   f0100509 <cons_getc>
f0100676:	85 c0                	test   %eax,%eax
f0100678:	74 f7                	je     f0100671 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010067a:	c9                   	leave  
f010067b:	c3                   	ret    

f010067c <iscons>:

int
iscons(int fdnum)
{
f010067c:	55                   	push   %ebp
f010067d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010067f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100684:	5d                   	pop    %ebp
f0100685:	c3                   	ret    

f0100686 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100686:	55                   	push   %ebp
f0100687:	89 e5                	mov    %esp,%ebp
f0100689:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010068c:	68 e0 1b 10 f0       	push   $0xf0101be0
f0100691:	68 fe 1b 10 f0       	push   $0xf0101bfe
f0100696:	68 03 1c 10 f0       	push   $0xf0101c03
f010069b:	e8 e8 02 00 00       	call   f0100988 <cprintf>
f01006a0:	83 c4 0c             	add    $0xc,%esp
f01006a3:	68 c0 1c 10 f0       	push   $0xf0101cc0
f01006a8:	68 0c 1c 10 f0       	push   $0xf0101c0c
f01006ad:	68 03 1c 10 f0       	push   $0xf0101c03
f01006b2:	e8 d1 02 00 00       	call   f0100988 <cprintf>
f01006b7:	83 c4 0c             	add    $0xc,%esp
f01006ba:	68 15 1c 10 f0       	push   $0xf0101c15
f01006bf:	68 33 1c 10 f0       	push   $0xf0101c33
f01006c4:	68 03 1c 10 f0       	push   $0xf0101c03
f01006c9:	e8 ba 02 00 00       	call   f0100988 <cprintf>
	return 0;
}
f01006ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d3:	c9                   	leave  
f01006d4:	c3                   	ret    

f01006d5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d5:	55                   	push   %ebp
f01006d6:	89 e5                	mov    %esp,%ebp
f01006d8:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006db:	68 3d 1c 10 f0       	push   $0xf0101c3d
f01006e0:	e8 a3 02 00 00       	call   f0100988 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006e5:	83 c4 08             	add    $0x8,%esp
f01006e8:	68 0c 00 10 00       	push   $0x10000c
f01006ed:	68 e8 1c 10 f0       	push   $0xf0101ce8
f01006f2:	e8 91 02 00 00       	call   f0100988 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006f7:	83 c4 0c             	add    $0xc,%esp
f01006fa:	68 0c 00 10 00       	push   $0x10000c
f01006ff:	68 0c 00 10 f0       	push   $0xf010000c
f0100704:	68 10 1d 10 f0       	push   $0xf0101d10
f0100709:	e8 7a 02 00 00       	call   f0100988 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010070e:	83 c4 0c             	add    $0xc,%esp
f0100711:	68 f1 18 10 00       	push   $0x1018f1
f0100716:	68 f1 18 10 f0       	push   $0xf01018f1
f010071b:	68 34 1d 10 f0       	push   $0xf0101d34
f0100720:	e8 63 02 00 00       	call   f0100988 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100725:	83 c4 0c             	add    $0xc,%esp
f0100728:	68 00 23 11 00       	push   $0x112300
f010072d:	68 00 23 11 f0       	push   $0xf0112300
f0100732:	68 58 1d 10 f0       	push   $0xf0101d58
f0100737:	e8 4c 02 00 00       	call   f0100988 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073c:	83 c4 0c             	add    $0xc,%esp
f010073f:	68 40 29 11 00       	push   $0x112940
f0100744:	68 40 29 11 f0       	push   $0xf0112940
f0100749:	68 7c 1d 10 f0       	push   $0xf0101d7c
f010074e:	e8 35 02 00 00       	call   f0100988 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100753:	b8 3f 2d 11 f0       	mov    $0xf0112d3f,%eax
f0100758:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010075d:	83 c4 08             	add    $0x8,%esp
f0100760:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100765:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010076b:	85 c0                	test   %eax,%eax
f010076d:	0f 48 c2             	cmovs  %edx,%eax
f0100770:	c1 f8 0a             	sar    $0xa,%eax
f0100773:	50                   	push   %eax
f0100774:	68 a0 1d 10 f0       	push   $0xf0101da0
f0100779:	e8 0a 02 00 00       	call   f0100988 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010077e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100783:	c9                   	leave  
f0100784:	c3                   	ret    

f0100785 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100785:	55                   	push   %ebp
f0100786:	89 e5                	mov    %esp,%ebp
f0100788:	57                   	push   %edi
f0100789:	56                   	push   %esi
f010078a:	53                   	push   %ebx
f010078b:	83 ec 3c             	sub    $0x3c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010078e:	89 ee                	mov    %ebp,%esi
	int i;
	uint32_t eip;
	uint32_t *ebp = (uint32_t *)read_ebp();
	struct Eipdebuginfo debug_info;
		
	while(ebp){
f0100790:	eb 78                	jmp    f010080a <mon_backtrace+0x85>
		eip = *(ebp + 1);
f0100792:	8b 46 04             	mov    0x4(%esi),%eax
f0100795:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		cprintf("ebp  %x  eip  %x  args", ebp, eip);
f0100798:	83 ec 04             	sub    $0x4,%esp
f010079b:	50                   	push   %eax
f010079c:	56                   	push   %esi
f010079d:	68 56 1c 10 f0       	push   $0xf0101c56
f01007a2:	e8 e1 01 00 00       	call   f0100988 <cprintf>
f01007a7:	8d 5e 08             	lea    0x8(%esi),%ebx
f01007aa:	8d 7e 1c             	lea    0x1c(%esi),%edi
f01007ad:	83 c4 10             	add    $0x10,%esp
		for(i=0; i<5; i++){
			cprintf(" %08x", *(ebp+i+2));
f01007b0:	83 ec 08             	sub    $0x8,%esp
f01007b3:	ff 33                	pushl  (%ebx)
f01007b5:	68 6d 1c 10 f0       	push   $0xf0101c6d
f01007ba:	e8 c9 01 00 00       	call   f0100988 <cprintf>
f01007bf:	83 c3 04             	add    $0x4,%ebx
	struct Eipdebuginfo debug_info;
		
	while(ebp){
		eip = *(ebp + 1);
		cprintf("ebp  %x  eip  %x  args", ebp, eip);
		for(i=0; i<5; i++){
f01007c2:	83 c4 10             	add    $0x10,%esp
f01007c5:	39 fb                	cmp    %edi,%ebx
f01007c7:	75 e7                	jne    f01007b0 <mon_backtrace+0x2b>
			cprintf(" %08x", *(ebp+i+2));
		}
		debuginfo_eip(eip, &debug_info);
f01007c9:	83 ec 08             	sub    $0x8,%esp
f01007cc:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007cf:	50                   	push   %eax
f01007d0:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01007d3:	57                   	push   %edi
f01007d4:	e8 b9 02 00 00       	call   f0100a92 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d", debug_info.eip_file, debug_info.eip_line, debug_info.eip_fn_namelen,  
f01007d9:	83 c4 08             	add    $0x8,%esp
f01007dc:	89 f8                	mov    %edi,%eax
f01007de:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007e1:	50                   	push   %eax
f01007e2:	ff 75 d8             	pushl  -0x28(%ebp)
f01007e5:	ff 75 dc             	pushl  -0x24(%ebp)
f01007e8:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007eb:	ff 75 d0             	pushl  -0x30(%ebp)
f01007ee:	68 73 1c 10 f0       	push   $0xf0101c73
f01007f3:	e8 90 01 00 00       	call   f0100988 <cprintf>
					  debug_info.eip_fn_name, eip - debug_info.eip_fn_addr);
		cprintf("\n");
f01007f8:	83 c4 14             	add    $0x14,%esp
f01007fb:	68 8e 19 10 f0       	push   $0xf010198e
f0100800:	e8 83 01 00 00       	call   f0100988 <cprintf>
		ebp = (uint32_t *)(* ebp);
f0100805:	8b 36                	mov    (%esi),%esi
f0100807:	83 c4 10             	add    $0x10,%esp
	int i;
	uint32_t eip;
	uint32_t *ebp = (uint32_t *)read_ebp();
	struct Eipdebuginfo debug_info;
		
	while(ebp){
f010080a:	85 f6                	test   %esi,%esi
f010080c:	75 84                	jne    f0100792 <mon_backtrace+0xd>
					  debug_info.eip_fn_name, eip - debug_info.eip_fn_addr);
		cprintf("\n");
		ebp = (uint32_t *)(* ebp);
	}
	return 0;
}
f010080e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100813:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100816:	5b                   	pop    %ebx
f0100817:	5e                   	pop    %esi
f0100818:	5f                   	pop    %edi
f0100819:	5d                   	pop    %ebp
f010081a:	c3                   	ret    

f010081b <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010081b:	55                   	push   %ebp
f010081c:	89 e5                	mov    %esp,%ebp
f010081e:	57                   	push   %edi
f010081f:	56                   	push   %esi
f0100820:	53                   	push   %ebx
f0100821:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100824:	68 cc 1d 10 f0       	push   $0xf0101dcc
f0100829:	e8 5a 01 00 00       	call   f0100988 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010082e:	c7 04 24 f0 1d 10 f0 	movl   $0xf0101df0,(%esp)
f0100835:	e8 4e 01 00 00       	call   f0100988 <cprintf>
f010083a:	83 c4 10             	add    $0x10,%esp

	
	while (1) {
		buf = readline("K> ");
f010083d:	83 ec 0c             	sub    $0xc,%esp
f0100840:	68 83 1c 10 f0       	push   $0xf0101c83
f0100845:	e8 c9 09 00 00       	call   f0101213 <readline>
f010084a:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010084c:	83 c4 10             	add    $0x10,%esp
f010084f:	85 c0                	test   %eax,%eax
f0100851:	74 ea                	je     f010083d <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100853:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010085a:	be 00 00 00 00       	mov    $0x0,%esi
f010085f:	eb 0a                	jmp    f010086b <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100861:	c6 03 00             	movb   $0x0,(%ebx)
f0100864:	89 f7                	mov    %esi,%edi
f0100866:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100869:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010086b:	0f b6 03             	movzbl (%ebx),%eax
f010086e:	84 c0                	test   %al,%al
f0100870:	74 63                	je     f01008d5 <monitor+0xba>
f0100872:	83 ec 08             	sub    $0x8,%esp
f0100875:	0f be c0             	movsbl %al,%eax
f0100878:	50                   	push   %eax
f0100879:	68 87 1c 10 f0       	push   $0xf0101c87
f010087e:	e8 aa 0b 00 00       	call   f010142d <strchr>
f0100883:	83 c4 10             	add    $0x10,%esp
f0100886:	85 c0                	test   %eax,%eax
f0100888:	75 d7                	jne    f0100861 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010088a:	80 3b 00             	cmpb   $0x0,(%ebx)
f010088d:	74 46                	je     f01008d5 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010088f:	83 fe 0f             	cmp    $0xf,%esi
f0100892:	75 14                	jne    f01008a8 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100894:	83 ec 08             	sub    $0x8,%esp
f0100897:	6a 10                	push   $0x10
f0100899:	68 8c 1c 10 f0       	push   $0xf0101c8c
f010089e:	e8 e5 00 00 00       	call   f0100988 <cprintf>
f01008a3:	83 c4 10             	add    $0x10,%esp
f01008a6:	eb 95                	jmp    f010083d <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f01008a8:	8d 7e 01             	lea    0x1(%esi),%edi
f01008ab:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008af:	eb 03                	jmp    f01008b4 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008b1:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008b4:	0f b6 03             	movzbl (%ebx),%eax
f01008b7:	84 c0                	test   %al,%al
f01008b9:	74 ae                	je     f0100869 <monitor+0x4e>
f01008bb:	83 ec 08             	sub    $0x8,%esp
f01008be:	0f be c0             	movsbl %al,%eax
f01008c1:	50                   	push   %eax
f01008c2:	68 87 1c 10 f0       	push   $0xf0101c87
f01008c7:	e8 61 0b 00 00       	call   f010142d <strchr>
f01008cc:	83 c4 10             	add    $0x10,%esp
f01008cf:	85 c0                	test   %eax,%eax
f01008d1:	74 de                	je     f01008b1 <monitor+0x96>
f01008d3:	eb 94                	jmp    f0100869 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008d5:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008dc:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008dd:	85 f6                	test   %esi,%esi
f01008df:	0f 84 58 ff ff ff    	je     f010083d <monitor+0x22>
f01008e5:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008ea:	83 ec 08             	sub    $0x8,%esp
f01008ed:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008f0:	ff 34 85 20 1e 10 f0 	pushl  -0xfefe1e0(,%eax,4)
f01008f7:	ff 75 a8             	pushl  -0x58(%ebp)
f01008fa:	e8 d0 0a 00 00       	call   f01013cf <strcmp>
f01008ff:	83 c4 10             	add    $0x10,%esp
f0100902:	85 c0                	test   %eax,%eax
f0100904:	75 21                	jne    f0100927 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100906:	83 ec 04             	sub    $0x4,%esp
f0100909:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010090c:	ff 75 08             	pushl  0x8(%ebp)
f010090f:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100912:	52                   	push   %edx
f0100913:	56                   	push   %esi
f0100914:	ff 14 85 28 1e 10 f0 	call   *-0xfefe1d8(,%eax,4)

	
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010091b:	83 c4 10             	add    $0x10,%esp
f010091e:	85 c0                	test   %eax,%eax
f0100920:	78 25                	js     f0100947 <monitor+0x12c>
f0100922:	e9 16 ff ff ff       	jmp    f010083d <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100927:	83 c3 01             	add    $0x1,%ebx
f010092a:	83 fb 03             	cmp    $0x3,%ebx
f010092d:	75 bb                	jne    f01008ea <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010092f:	83 ec 08             	sub    $0x8,%esp
f0100932:	ff 75 a8             	pushl  -0x58(%ebp)
f0100935:	68 a9 1c 10 f0       	push   $0xf0101ca9
f010093a:	e8 49 00 00 00       	call   f0100988 <cprintf>
f010093f:	83 c4 10             	add    $0x10,%esp
f0100942:	e9 f6 fe ff ff       	jmp    f010083d <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100947:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010094a:	5b                   	pop    %ebx
f010094b:	5e                   	pop    %esi
f010094c:	5f                   	pop    %edi
f010094d:	5d                   	pop    %ebp
f010094e:	c3                   	ret    

f010094f <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010094f:	55                   	push   %ebp
f0100950:	89 e5                	mov    %esp,%ebp
f0100952:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100955:	ff 75 08             	pushl  0x8(%ebp)
f0100958:	e8 fe fc ff ff       	call   f010065b <cputchar>
	*cnt++;
}
f010095d:	83 c4 10             	add    $0x10,%esp
f0100960:	c9                   	leave  
f0100961:	c3                   	ret    

f0100962 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100962:	55                   	push   %ebp
f0100963:	89 e5                	mov    %esp,%ebp
f0100965:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100968:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010096f:	ff 75 0c             	pushl  0xc(%ebp)
f0100972:	ff 75 08             	pushl  0x8(%ebp)
f0100975:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100978:	50                   	push   %eax
f0100979:	68 4f 09 10 f0       	push   $0xf010094f
f010097e:	e8 5d 04 00 00       	call   f0100de0 <vprintfmt>
	return cnt;
}
f0100983:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100986:	c9                   	leave  
f0100987:	c3                   	ret    

f0100988 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100988:	55                   	push   %ebp
f0100989:	89 e5                	mov    %esp,%ebp
f010098b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010098e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100991:	50                   	push   %eax
f0100992:	ff 75 08             	pushl  0x8(%ebp)
f0100995:	e8 c8 ff ff ff       	call   f0100962 <vcprintf>
	va_end(ap);

	return cnt;
}
f010099a:	c9                   	leave  
f010099b:	c3                   	ret    

f010099c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010099c:	55                   	push   %ebp
f010099d:	89 e5                	mov    %esp,%ebp
f010099f:	57                   	push   %edi
f01009a0:	56                   	push   %esi
f01009a1:	53                   	push   %ebx
f01009a2:	83 ec 14             	sub    $0x14,%esp
f01009a5:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01009a8:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01009ab:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01009ae:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009b1:	8b 1a                	mov    (%edx),%ebx
f01009b3:	8b 01                	mov    (%ecx),%eax
f01009b5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009b8:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01009bf:	eb 7f                	jmp    f0100a40 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01009c1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009c4:	01 d8                	add    %ebx,%eax
f01009c6:	89 c6                	mov    %eax,%esi
f01009c8:	c1 ee 1f             	shr    $0x1f,%esi
f01009cb:	01 c6                	add    %eax,%esi
f01009cd:	d1 fe                	sar    %esi
f01009cf:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009d2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009d5:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009d8:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009da:	eb 03                	jmp    f01009df <stab_binsearch+0x43>
			m--;
f01009dc:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009df:	39 c3                	cmp    %eax,%ebx
f01009e1:	7f 0d                	jg     f01009f0 <stab_binsearch+0x54>
f01009e3:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009e7:	83 ea 0c             	sub    $0xc,%edx
f01009ea:	39 f9                	cmp    %edi,%ecx
f01009ec:	75 ee                	jne    f01009dc <stab_binsearch+0x40>
f01009ee:	eb 05                	jmp    f01009f5 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009f0:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009f3:	eb 4b                	jmp    f0100a40 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009f5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009f8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009fb:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01009ff:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a02:	76 11                	jbe    f0100a15 <stab_binsearch+0x79>
			*region_left = m;
f0100a04:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a07:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a09:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a0c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a13:	eb 2b                	jmp    f0100a40 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a15:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a18:	73 14                	jae    f0100a2e <stab_binsearch+0x92>
			*region_right = m - 1;
f0100a1a:	83 e8 01             	sub    $0x1,%eax
f0100a1d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a20:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a23:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a25:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a2c:	eb 12                	jmp    f0100a40 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a2e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a31:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100a33:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a37:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a39:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a40:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a43:	0f 8e 78 ff ff ff    	jle    f01009c1 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a49:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a4d:	75 0f                	jne    f0100a5e <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a4f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a52:	8b 00                	mov    (%eax),%eax
f0100a54:	83 e8 01             	sub    $0x1,%eax
f0100a57:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a5a:	89 06                	mov    %eax,(%esi)
f0100a5c:	eb 2c                	jmp    f0100a8a <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a5e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a61:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a63:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a66:	8b 0e                	mov    (%esi),%ecx
f0100a68:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a6b:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a6e:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a71:	eb 03                	jmp    f0100a76 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a73:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a76:	39 c8                	cmp    %ecx,%eax
f0100a78:	7e 0b                	jle    f0100a85 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a7a:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a7e:	83 ea 0c             	sub    $0xc,%edx
f0100a81:	39 df                	cmp    %ebx,%edi
f0100a83:	75 ee                	jne    f0100a73 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a85:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a88:	89 06                	mov    %eax,(%esi)
	}
}
f0100a8a:	83 c4 14             	add    $0x14,%esp
f0100a8d:	5b                   	pop    %ebx
f0100a8e:	5e                   	pop    %esi
f0100a8f:	5f                   	pop    %edi
f0100a90:	5d                   	pop    %ebp
f0100a91:	c3                   	ret    

f0100a92 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a92:	55                   	push   %ebp
f0100a93:	89 e5                	mov    %esp,%ebp
f0100a95:	57                   	push   %edi
f0100a96:	56                   	push   %esi
f0100a97:	53                   	push   %ebx
f0100a98:	83 ec 3c             	sub    $0x3c,%esp
f0100a9b:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a9e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100aa1:	c7 03 44 1e 10 f0    	movl   $0xf0101e44,(%ebx)
	info->eip_line = 0;
f0100aa7:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100aae:	c7 43 08 44 1e 10 f0 	movl   $0xf0101e44,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ab5:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100abc:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100abf:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ac6:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100acc:	76 11                	jbe    f0100adf <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ace:	b8 24 73 10 f0       	mov    $0xf0107324,%eax
f0100ad3:	3d 0d 5a 10 f0       	cmp    $0xf0105a0d,%eax
f0100ad8:	77 19                	ja     f0100af3 <debuginfo_eip+0x61>
f0100ada:	e9 b5 01 00 00       	jmp    f0100c94 <debuginfo_eip+0x202>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100adf:	83 ec 04             	sub    $0x4,%esp
f0100ae2:	68 4e 1e 10 f0       	push   $0xf0101e4e
f0100ae7:	6a 7f                	push   $0x7f
f0100ae9:	68 5b 1e 10 f0       	push   $0xf0101e5b
f0100aee:	e8 f3 f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100af3:	80 3d 23 73 10 f0 00 	cmpb   $0x0,0xf0107323
f0100afa:	0f 85 9b 01 00 00    	jne    f0100c9b <debuginfo_eip+0x209>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b00:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b07:	b8 0c 5a 10 f0       	mov    $0xf0105a0c,%eax
f0100b0c:	2d 7c 20 10 f0       	sub    $0xf010207c,%eax
f0100b11:	c1 f8 02             	sar    $0x2,%eax
f0100b14:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b1a:	83 e8 01             	sub    $0x1,%eax
f0100b1d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b20:	83 ec 08             	sub    $0x8,%esp
f0100b23:	56                   	push   %esi
f0100b24:	6a 64                	push   $0x64
f0100b26:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b29:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b2c:	b8 7c 20 10 f0       	mov    $0xf010207c,%eax
f0100b31:	e8 66 fe ff ff       	call   f010099c <stab_binsearch>
	if (lfile == 0)
f0100b36:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b39:	83 c4 10             	add    $0x10,%esp
f0100b3c:	85 c0                	test   %eax,%eax
f0100b3e:	0f 84 5e 01 00 00    	je     f0100ca2 <debuginfo_eip+0x210>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b44:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b47:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b4a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b4d:	83 ec 08             	sub    $0x8,%esp
f0100b50:	56                   	push   %esi
f0100b51:	6a 24                	push   $0x24
f0100b53:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b56:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b59:	b8 7c 20 10 f0       	mov    $0xf010207c,%eax
f0100b5e:	e8 39 fe ff ff       	call   f010099c <stab_binsearch>

	if (lfun <= rfun) {
f0100b63:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b66:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b69:	83 c4 10             	add    $0x10,%esp
f0100b6c:	39 d0                	cmp    %edx,%eax
f0100b6e:	7f 40                	jg     f0100bb0 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b70:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b73:	c1 e1 02             	shl    $0x2,%ecx
f0100b76:	8d b9 7c 20 10 f0    	lea    -0xfefdf84(%ecx),%edi
f0100b7c:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b7f:	8b b9 7c 20 10 f0    	mov    -0xfefdf84(%ecx),%edi
f0100b85:	b9 24 73 10 f0       	mov    $0xf0107324,%ecx
f0100b8a:	81 e9 0d 5a 10 f0    	sub    $0xf0105a0d,%ecx
f0100b90:	39 cf                	cmp    %ecx,%edi
f0100b92:	73 09                	jae    f0100b9d <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b94:	81 c7 0d 5a 10 f0    	add    $0xf0105a0d,%edi
f0100b9a:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b9d:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ba0:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100ba3:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100ba6:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100ba8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bab:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bae:	eb 0f                	jmp    f0100bbf <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bb0:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bb3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bb6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bb9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bbc:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bbf:	83 ec 08             	sub    $0x8,%esp
f0100bc2:	6a 3a                	push   $0x3a
f0100bc4:	ff 73 08             	pushl  0x8(%ebx)
f0100bc7:	e8 82 08 00 00       	call   f010144e <strfind>
f0100bcc:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bcf:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100bd2:	83 c4 08             	add    $0x8,%esp
f0100bd5:	56                   	push   %esi
f0100bd6:	6a 44                	push   $0x44
f0100bd8:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100bdb:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100bde:	b8 7c 20 10 f0       	mov    $0xf010207c,%eax
f0100be3:	e8 b4 fd ff ff       	call   f010099c <stab_binsearch>
	if(lline <= rline){
f0100be8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100beb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100bee:	83 c4 10             	add    $0x10,%esp
f0100bf1:	39 d0                	cmp    %edx,%eax
f0100bf3:	0f 8f b0 00 00 00    	jg     f0100ca9 <debuginfo_eip+0x217>
		info->eip_line = stabs[rline].n_desc;
f0100bf9:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100bfc:	0f b7 14 95 82 20 10 	movzwl -0xfefdf7e(,%edx,4),%edx
f0100c03:	f0 
f0100c04:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c07:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c0a:	89 c2                	mov    %eax,%edx
f0100c0c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100c0f:	8d 04 85 7c 20 10 f0 	lea    -0xfefdf84(,%eax,4),%eax
f0100c16:	eb 06                	jmp    f0100c1e <debuginfo_eip+0x18c>
f0100c18:	83 ea 01             	sub    $0x1,%edx
f0100c1b:	83 e8 0c             	sub    $0xc,%eax
f0100c1e:	39 d7                	cmp    %edx,%edi
f0100c20:	7f 34                	jg     f0100c56 <debuginfo_eip+0x1c4>
	       && stabs[lline].n_type != N_SOL
f0100c22:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c26:	80 f9 84             	cmp    $0x84,%cl
f0100c29:	74 0b                	je     f0100c36 <debuginfo_eip+0x1a4>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c2b:	80 f9 64             	cmp    $0x64,%cl
f0100c2e:	75 e8                	jne    f0100c18 <debuginfo_eip+0x186>
f0100c30:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c34:	74 e2                	je     f0100c18 <debuginfo_eip+0x186>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c36:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c39:	8b 14 85 7c 20 10 f0 	mov    -0xfefdf84(,%eax,4),%edx
f0100c40:	b8 24 73 10 f0       	mov    $0xf0107324,%eax
f0100c45:	2d 0d 5a 10 f0       	sub    $0xf0105a0d,%eax
f0100c4a:	39 c2                	cmp    %eax,%edx
f0100c4c:	73 08                	jae    f0100c56 <debuginfo_eip+0x1c4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c4e:	81 c2 0d 5a 10 f0    	add    $0xf0105a0d,%edx
f0100c54:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c56:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c59:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c5c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c61:	39 f2                	cmp    %esi,%edx
f0100c63:	7d 50                	jge    f0100cb5 <debuginfo_eip+0x223>
		for (lline = lfun + 1;
f0100c65:	83 c2 01             	add    $0x1,%edx
f0100c68:	89 d0                	mov    %edx,%eax
f0100c6a:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c6d:	8d 14 95 7c 20 10 f0 	lea    -0xfefdf84(,%edx,4),%edx
f0100c74:	eb 04                	jmp    f0100c7a <debuginfo_eip+0x1e8>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c76:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c7a:	39 c6                	cmp    %eax,%esi
f0100c7c:	7e 32                	jle    f0100cb0 <debuginfo_eip+0x21e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c7e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c82:	83 c0 01             	add    $0x1,%eax
f0100c85:	83 c2 0c             	add    $0xc,%edx
f0100c88:	80 f9 a0             	cmp    $0xa0,%cl
f0100c8b:	74 e9                	je     f0100c76 <debuginfo_eip+0x1e4>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c8d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c92:	eb 21                	jmp    f0100cb5 <debuginfo_eip+0x223>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c99:	eb 1a                	jmp    f0100cb5 <debuginfo_eip+0x223>
f0100c9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca0:	eb 13                	jmp    f0100cb5 <debuginfo_eip+0x223>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ca2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca7:	eb 0c                	jmp    f0100cb5 <debuginfo_eip+0x223>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline <= rline){
		info->eip_line = stabs[rline].n_desc;
	}else{
		return -1;	
f0100ca9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cae:	eb 05                	jmp    f0100cb5 <debuginfo_eip+0x223>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cb0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cb5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cb8:	5b                   	pop    %ebx
f0100cb9:	5e                   	pop    %esi
f0100cba:	5f                   	pop    %edi
f0100cbb:	5d                   	pop    %ebp
f0100cbc:	c3                   	ret    

f0100cbd <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cbd:	55                   	push   %ebp
f0100cbe:	89 e5                	mov    %esp,%ebp
f0100cc0:	57                   	push   %edi
f0100cc1:	56                   	push   %esi
f0100cc2:	53                   	push   %ebx
f0100cc3:	83 ec 1c             	sub    $0x1c,%esp
f0100cc6:	89 c7                	mov    %eax,%edi
f0100cc8:	89 d6                	mov    %edx,%esi
f0100cca:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ccd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100cd0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cd3:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cd6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100cd9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100cde:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100ce1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100ce4:	39 d3                	cmp    %edx,%ebx
f0100ce6:	72 05                	jb     f0100ced <printnum+0x30>
f0100ce8:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100ceb:	77 45                	ja     f0100d32 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ced:	83 ec 0c             	sub    $0xc,%esp
f0100cf0:	ff 75 18             	pushl  0x18(%ebp)
f0100cf3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cf6:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cf9:	53                   	push   %ebx
f0100cfa:	ff 75 10             	pushl  0x10(%ebp)
f0100cfd:	83 ec 08             	sub    $0x8,%esp
f0100d00:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d03:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d06:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d09:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d0c:	e8 5f 09 00 00       	call   f0101670 <__udivdi3>
f0100d11:	83 c4 18             	add    $0x18,%esp
f0100d14:	52                   	push   %edx
f0100d15:	50                   	push   %eax
f0100d16:	89 f2                	mov    %esi,%edx
f0100d18:	89 f8                	mov    %edi,%eax
f0100d1a:	e8 9e ff ff ff       	call   f0100cbd <printnum>
f0100d1f:	83 c4 20             	add    $0x20,%esp
f0100d22:	eb 18                	jmp    f0100d3c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d24:	83 ec 08             	sub    $0x8,%esp
f0100d27:	56                   	push   %esi
f0100d28:	ff 75 18             	pushl  0x18(%ebp)
f0100d2b:	ff d7                	call   *%edi
f0100d2d:	83 c4 10             	add    $0x10,%esp
f0100d30:	eb 03                	jmp    f0100d35 <printnum+0x78>
f0100d32:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d35:	83 eb 01             	sub    $0x1,%ebx
f0100d38:	85 db                	test   %ebx,%ebx
f0100d3a:	7f e8                	jg     f0100d24 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d3c:	83 ec 08             	sub    $0x8,%esp
f0100d3f:	56                   	push   %esi
f0100d40:	83 ec 04             	sub    $0x4,%esp
f0100d43:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d46:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d49:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d4c:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d4f:	e8 4c 0a 00 00       	call   f01017a0 <__umoddi3>
f0100d54:	83 c4 14             	add    $0x14,%esp
f0100d57:	0f be 80 69 1e 10 f0 	movsbl -0xfefe197(%eax),%eax
f0100d5e:	50                   	push   %eax
f0100d5f:	ff d7                	call   *%edi
}
f0100d61:	83 c4 10             	add    $0x10,%esp
f0100d64:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d67:	5b                   	pop    %ebx
f0100d68:	5e                   	pop    %esi
f0100d69:	5f                   	pop    %edi
f0100d6a:	5d                   	pop    %ebp
f0100d6b:	c3                   	ret    

f0100d6c <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d6c:	55                   	push   %ebp
f0100d6d:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d6f:	83 fa 01             	cmp    $0x1,%edx
f0100d72:	7e 0e                	jle    f0100d82 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d74:	8b 10                	mov    (%eax),%edx
f0100d76:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d79:	89 08                	mov    %ecx,(%eax)
f0100d7b:	8b 02                	mov    (%edx),%eax
f0100d7d:	8b 52 04             	mov    0x4(%edx),%edx
f0100d80:	eb 22                	jmp    f0100da4 <getuint+0x38>
	else if (lflag)
f0100d82:	85 d2                	test   %edx,%edx
f0100d84:	74 10                	je     f0100d96 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d86:	8b 10                	mov    (%eax),%edx
f0100d88:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d8b:	89 08                	mov    %ecx,(%eax)
f0100d8d:	8b 02                	mov    (%edx),%eax
f0100d8f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d94:	eb 0e                	jmp    f0100da4 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d96:	8b 10                	mov    (%eax),%edx
f0100d98:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d9b:	89 08                	mov    %ecx,(%eax)
f0100d9d:	8b 02                	mov    (%edx),%eax
f0100d9f:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100da4:	5d                   	pop    %ebp
f0100da5:	c3                   	ret    

f0100da6 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100da6:	55                   	push   %ebp
f0100da7:	89 e5                	mov    %esp,%ebp
f0100da9:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100dac:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100db0:	8b 10                	mov    (%eax),%edx
f0100db2:	3b 50 04             	cmp    0x4(%eax),%edx
f0100db5:	73 0a                	jae    f0100dc1 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100db7:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100dba:	89 08                	mov    %ecx,(%eax)
f0100dbc:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dbf:	88 02                	mov    %al,(%edx)
}
f0100dc1:	5d                   	pop    %ebp
f0100dc2:	c3                   	ret    

f0100dc3 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100dc3:	55                   	push   %ebp
f0100dc4:	89 e5                	mov    %esp,%ebp
f0100dc6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100dc9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dcc:	50                   	push   %eax
f0100dcd:	ff 75 10             	pushl  0x10(%ebp)
f0100dd0:	ff 75 0c             	pushl  0xc(%ebp)
f0100dd3:	ff 75 08             	pushl  0x8(%ebp)
f0100dd6:	e8 05 00 00 00       	call   f0100de0 <vprintfmt>
	va_end(ap);
}
f0100ddb:	83 c4 10             	add    $0x10,%esp
f0100dde:	c9                   	leave  
f0100ddf:	c3                   	ret    

f0100de0 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100de0:	55                   	push   %ebp
f0100de1:	89 e5                	mov    %esp,%ebp
f0100de3:	57                   	push   %edi
f0100de4:	56                   	push   %esi
f0100de5:	53                   	push   %ebx
f0100de6:	83 ec 2c             	sub    $0x2c,%esp
f0100de9:	8b 75 08             	mov    0x8(%ebp),%esi
f0100dec:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100def:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100df2:	eb 12                	jmp    f0100e06 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100df4:	85 c0                	test   %eax,%eax
f0100df6:	0f 84 a7 03 00 00    	je     f01011a3 <vprintfmt+0x3c3>
				return;
			putch(ch, putdat);
f0100dfc:	83 ec 08             	sub    $0x8,%esp
f0100dff:	53                   	push   %ebx
f0100e00:	50                   	push   %eax
f0100e01:	ff d6                	call   *%esi
f0100e03:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e06:	83 c7 01             	add    $0x1,%edi
f0100e09:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e0d:	83 f8 25             	cmp    $0x25,%eax
f0100e10:	75 e2                	jne    f0100df4 <vprintfmt+0x14>
f0100e12:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e16:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e1d:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0100e24:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e2b:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0100e32:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e37:	eb 07                	jmp    f0100e40 <vprintfmt+0x60>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e39:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e3c:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e40:	8d 47 01             	lea    0x1(%edi),%eax
f0100e43:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e46:	0f b6 07             	movzbl (%edi),%eax
f0100e49:	0f b6 d0             	movzbl %al,%edx
f0100e4c:	83 e8 23             	sub    $0x23,%eax
f0100e4f:	3c 55                	cmp    $0x55,%al
f0100e51:	0f 87 31 03 00 00    	ja     f0101188 <vprintfmt+0x3a8>
f0100e57:	0f b6 c0             	movzbl %al,%eax
f0100e5a:	ff 24 85 f8 1e 10 f0 	jmp    *-0xfefe108(,%eax,4)
f0100e61:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e64:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e68:	eb d6                	jmp    f0100e40 <vprintfmt+0x60>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e6a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e72:	89 75 08             	mov    %esi,0x8(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e75:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100e78:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100e7c:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100e7f:	8d 72 d0             	lea    -0x30(%edx),%esi
f0100e82:	83 fe 09             	cmp    $0x9,%esi
f0100e85:	77 34                	ja     f0100ebb <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e87:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e8a:	eb e9                	jmp    f0100e75 <vprintfmt+0x95>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e8c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e8f:	8d 50 04             	lea    0x4(%eax),%edx
f0100e92:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e95:	8b 00                	mov    (%eax),%eax
f0100e97:	89 45 cc             	mov    %eax,-0x34(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e9a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e9d:	eb 22                	jmp    f0100ec1 <vprintfmt+0xe1>
f0100e9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ea2:	85 c0                	test   %eax,%eax
f0100ea4:	0f 48 c1             	cmovs  %ecx,%eax
f0100ea7:	89 45 e0             	mov    %eax,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eaa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ead:	eb 91                	jmp    f0100e40 <vprintfmt+0x60>
f0100eaf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100eb2:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100eb9:	eb 85                	jmp    f0100e40 <vprintfmt+0x60>
f0100ebb:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100ebe:	8b 75 08             	mov    0x8(%ebp),%esi

		process_precision:
			if (width < 0)
f0100ec1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ec5:	0f 89 75 ff ff ff    	jns    f0100e40 <vprintfmt+0x60>
				width = precision, precision = -1;
f0100ecb:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100ece:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ed1:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0100ed8:	e9 63 ff ff ff       	jmp    f0100e40 <vprintfmt+0x60>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100edd:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ee4:	e9 57 ff ff ff       	jmp    f0100e40 <vprintfmt+0x60>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ee9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eec:	8d 50 04             	lea    0x4(%eax),%edx
f0100eef:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ef2:	83 ec 08             	sub    $0x8,%esp
f0100ef5:	53                   	push   %ebx
f0100ef6:	ff 30                	pushl  (%eax)
f0100ef8:	ff d6                	call   *%esi
			break;
f0100efa:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100efd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f00:	e9 01 ff ff ff       	jmp    f0100e06 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f05:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f08:	8d 50 04             	lea    0x4(%eax),%edx
f0100f0b:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f0e:	8b 00                	mov    (%eax),%eax
f0100f10:	99                   	cltd   
f0100f11:	31 d0                	xor    %edx,%eax
f0100f13:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f15:	83 f8 06             	cmp    $0x6,%eax
f0100f18:	7f 0b                	jg     f0100f25 <vprintfmt+0x145>
f0100f1a:	8b 14 85 50 20 10 f0 	mov    -0xfefdfb0(,%eax,4),%edx
f0100f21:	85 d2                	test   %edx,%edx
f0100f23:	75 18                	jne    f0100f3d <vprintfmt+0x15d>
				printfmt(putch, putdat, "error %d", err);
f0100f25:	50                   	push   %eax
f0100f26:	68 81 1e 10 f0       	push   $0xf0101e81
f0100f2b:	53                   	push   %ebx
f0100f2c:	56                   	push   %esi
f0100f2d:	e8 91 fe ff ff       	call   f0100dc3 <printfmt>
f0100f32:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f38:	e9 c9 fe ff ff       	jmp    f0100e06 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100f3d:	52                   	push   %edx
f0100f3e:	68 8a 1e 10 f0       	push   $0xf0101e8a
f0100f43:	53                   	push   %ebx
f0100f44:	56                   	push   %esi
f0100f45:	e8 79 fe ff ff       	call   f0100dc3 <printfmt>
f0100f4a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f50:	e9 b1 fe ff ff       	jmp    f0100e06 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f55:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f58:	8d 50 04             	lea    0x4(%eax),%edx
f0100f5b:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f5e:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100f60:	85 ff                	test   %edi,%edi
f0100f62:	b8 7a 1e 10 f0       	mov    $0xf0101e7a,%eax
f0100f67:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100f6a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f6e:	0f 8e 94 00 00 00    	jle    f0101008 <vprintfmt+0x228>
f0100f74:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f78:	0f 84 98 00 00 00    	je     f0101016 <vprintfmt+0x236>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f7e:	83 ec 08             	sub    $0x8,%esp
f0100f81:	ff 75 cc             	pushl  -0x34(%ebp)
f0100f84:	57                   	push   %edi
f0100f85:	e8 7a 03 00 00       	call   f0101304 <strnlen>
f0100f8a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f8d:	29 c1                	sub    %eax,%ecx
f0100f8f:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0100f92:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f95:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f99:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f9c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f9f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fa1:	eb 0f                	jmp    f0100fb2 <vprintfmt+0x1d2>
					putch(padc, putdat);
f0100fa3:	83 ec 08             	sub    $0x8,%esp
f0100fa6:	53                   	push   %ebx
f0100fa7:	ff 75 e0             	pushl  -0x20(%ebp)
f0100faa:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fac:	83 ef 01             	sub    $0x1,%edi
f0100faf:	83 c4 10             	add    $0x10,%esp
f0100fb2:	85 ff                	test   %edi,%edi
f0100fb4:	7f ed                	jg     f0100fa3 <vprintfmt+0x1c3>
f0100fb6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100fb9:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100fbc:	85 c9                	test   %ecx,%ecx
f0100fbe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fc3:	0f 49 c1             	cmovns %ecx,%eax
f0100fc6:	29 c1                	sub    %eax,%ecx
f0100fc8:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fcb:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0100fce:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fd1:	89 cb                	mov    %ecx,%ebx
f0100fd3:	eb 4d                	jmp    f0101022 <vprintfmt+0x242>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100fd5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100fd9:	74 1b                	je     f0100ff6 <vprintfmt+0x216>
f0100fdb:	0f be c0             	movsbl %al,%eax
f0100fde:	83 e8 20             	sub    $0x20,%eax
f0100fe1:	83 f8 5e             	cmp    $0x5e,%eax
f0100fe4:	76 10                	jbe    f0100ff6 <vprintfmt+0x216>
					putch('?', putdat);
f0100fe6:	83 ec 08             	sub    $0x8,%esp
f0100fe9:	ff 75 0c             	pushl  0xc(%ebp)
f0100fec:	6a 3f                	push   $0x3f
f0100fee:	ff 55 08             	call   *0x8(%ebp)
f0100ff1:	83 c4 10             	add    $0x10,%esp
f0100ff4:	eb 0d                	jmp    f0101003 <vprintfmt+0x223>
				else
					putch(ch, putdat);
f0100ff6:	83 ec 08             	sub    $0x8,%esp
f0100ff9:	ff 75 0c             	pushl  0xc(%ebp)
f0100ffc:	52                   	push   %edx
f0100ffd:	ff 55 08             	call   *0x8(%ebp)
f0101000:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101003:	83 eb 01             	sub    $0x1,%ebx
f0101006:	eb 1a                	jmp    f0101022 <vprintfmt+0x242>
f0101008:	89 75 08             	mov    %esi,0x8(%ebp)
f010100b:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010100e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101011:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101014:	eb 0c                	jmp    f0101022 <vprintfmt+0x242>
f0101016:	89 75 08             	mov    %esi,0x8(%ebp)
f0101019:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010101c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010101f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101022:	83 c7 01             	add    $0x1,%edi
f0101025:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101029:	0f be d0             	movsbl %al,%edx
f010102c:	85 d2                	test   %edx,%edx
f010102e:	74 23                	je     f0101053 <vprintfmt+0x273>
f0101030:	85 f6                	test   %esi,%esi
f0101032:	78 a1                	js     f0100fd5 <vprintfmt+0x1f5>
f0101034:	83 ee 01             	sub    $0x1,%esi
f0101037:	79 9c                	jns    f0100fd5 <vprintfmt+0x1f5>
f0101039:	89 df                	mov    %ebx,%edi
f010103b:	8b 75 08             	mov    0x8(%ebp),%esi
f010103e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101041:	eb 18                	jmp    f010105b <vprintfmt+0x27b>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101043:	83 ec 08             	sub    $0x8,%esp
f0101046:	53                   	push   %ebx
f0101047:	6a 20                	push   $0x20
f0101049:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010104b:	83 ef 01             	sub    $0x1,%edi
f010104e:	83 c4 10             	add    $0x10,%esp
f0101051:	eb 08                	jmp    f010105b <vprintfmt+0x27b>
f0101053:	89 df                	mov    %ebx,%edi
f0101055:	8b 75 08             	mov    0x8(%ebp),%esi
f0101058:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010105b:	85 ff                	test   %edi,%edi
f010105d:	7f e4                	jg     f0101043 <vprintfmt+0x263>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010105f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101062:	e9 9f fd ff ff       	jmp    f0100e06 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101067:	83 7d d0 01          	cmpl   $0x1,-0x30(%ebp)
f010106b:	7e 16                	jle    f0101083 <vprintfmt+0x2a3>
		return va_arg(*ap, long long);
f010106d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101070:	8d 50 08             	lea    0x8(%eax),%edx
f0101073:	89 55 14             	mov    %edx,0x14(%ebp)
f0101076:	8b 50 04             	mov    0x4(%eax),%edx
f0101079:	8b 00                	mov    (%eax),%eax
f010107b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010107e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101081:	eb 34                	jmp    f01010b7 <vprintfmt+0x2d7>
	else if (lflag)
f0101083:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101087:	74 18                	je     f01010a1 <vprintfmt+0x2c1>
		return va_arg(*ap, long);
f0101089:	8b 45 14             	mov    0x14(%ebp),%eax
f010108c:	8d 50 04             	lea    0x4(%eax),%edx
f010108f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101092:	8b 00                	mov    (%eax),%eax
f0101094:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101097:	89 c1                	mov    %eax,%ecx
f0101099:	c1 f9 1f             	sar    $0x1f,%ecx
f010109c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010109f:	eb 16                	jmp    f01010b7 <vprintfmt+0x2d7>
	else
		return va_arg(*ap, int);
f01010a1:	8b 45 14             	mov    0x14(%ebp),%eax
f01010a4:	8d 50 04             	lea    0x4(%eax),%edx
f01010a7:	89 55 14             	mov    %edx,0x14(%ebp)
f01010aa:	8b 00                	mov    (%eax),%eax
f01010ac:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010af:	89 c1                	mov    %eax,%ecx
f01010b1:	c1 f9 1f             	sar    $0x1f,%ecx
f01010b4:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01010b7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010ba:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010bd:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010c2:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010c6:	0f 89 88 00 00 00    	jns    f0101154 <vprintfmt+0x374>
				putch('-', putdat);
f01010cc:	83 ec 08             	sub    $0x8,%esp
f01010cf:	53                   	push   %ebx
f01010d0:	6a 2d                	push   $0x2d
f01010d2:	ff d6                	call   *%esi
				num = -(long long) num;
f01010d4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010d7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010da:	f7 d8                	neg    %eax
f01010dc:	83 d2 00             	adc    $0x0,%edx
f01010df:	f7 da                	neg    %edx
f01010e1:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01010e4:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01010e9:	eb 69                	jmp    f0101154 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01010eb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01010ee:	8d 45 14             	lea    0x14(%ebp),%eax
f01010f1:	e8 76 fc ff ff       	call   f0100d6c <getuint>
			base = 10;
f01010f6:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010fb:	eb 57                	jmp    f0101154 <vprintfmt+0x374>
			//putch('X', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
	
			putch('0', putdat);	//八进制要打印一个0先
f01010fd:	83 ec 08             	sub    $0x8,%esp
f0101100:	53                   	push   %ebx
f0101101:	6a 30                	push   $0x30
f0101103:	ff d6                	call   *%esi
			num = getuint(&ap, lflag);
f0101105:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101108:	8d 45 14             	lea    0x14(%ebp),%eax
f010110b:	e8 5c fc ff ff       	call   f0100d6c <getuint>
			base = 8;
			goto number; 	
f0101110:	83 c4 10             	add    $0x10,%esp
			//putch('X', putdat);
			//break;
	
			putch('0', putdat);	//八进制要打印一个0先
			num = getuint(&ap, lflag);
			base = 8;
f0101113:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number; 	
f0101118:	eb 3a                	jmp    f0101154 <vprintfmt+0x374>
			

		// pointer
		case 'p':
			putch('0', putdat);
f010111a:	83 ec 08             	sub    $0x8,%esp
f010111d:	53                   	push   %ebx
f010111e:	6a 30                	push   $0x30
f0101120:	ff d6                	call   *%esi
			putch('x', putdat);
f0101122:	83 c4 08             	add    $0x8,%esp
f0101125:	53                   	push   %ebx
f0101126:	6a 78                	push   $0x78
f0101128:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010112a:	8b 45 14             	mov    0x14(%ebp),%eax
f010112d:	8d 50 04             	lea    0x4(%eax),%edx
f0101130:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101133:	8b 00                	mov    (%eax),%eax
f0101135:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010113a:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010113d:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101142:	eb 10                	jmp    f0101154 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101144:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101147:	8d 45 14             	lea    0x14(%ebp),%eax
f010114a:	e8 1d fc ff ff       	call   f0100d6c <getuint>
			base = 16;
f010114f:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101154:	83 ec 0c             	sub    $0xc,%esp
f0101157:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010115b:	57                   	push   %edi
f010115c:	ff 75 e0             	pushl  -0x20(%ebp)
f010115f:	51                   	push   %ecx
f0101160:	52                   	push   %edx
f0101161:	50                   	push   %eax
f0101162:	89 da                	mov    %ebx,%edx
f0101164:	89 f0                	mov    %esi,%eax
f0101166:	e8 52 fb ff ff       	call   f0100cbd <printnum>
			break;
f010116b:	83 c4 20             	add    $0x20,%esp
f010116e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101171:	e9 90 fc ff ff       	jmp    f0100e06 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101176:	83 ec 08             	sub    $0x8,%esp
f0101179:	53                   	push   %ebx
f010117a:	52                   	push   %edx
f010117b:	ff d6                	call   *%esi
			break;
f010117d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101180:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101183:	e9 7e fc ff ff       	jmp    f0100e06 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101188:	83 ec 08             	sub    $0x8,%esp
f010118b:	53                   	push   %ebx
f010118c:	6a 25                	push   $0x25
f010118e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101190:	83 c4 10             	add    $0x10,%esp
f0101193:	eb 03                	jmp    f0101198 <vprintfmt+0x3b8>
f0101195:	83 ef 01             	sub    $0x1,%edi
f0101198:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010119c:	75 f7                	jne    f0101195 <vprintfmt+0x3b5>
f010119e:	e9 63 fc ff ff       	jmp    f0100e06 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01011a3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011a6:	5b                   	pop    %ebx
f01011a7:	5e                   	pop    %esi
f01011a8:	5f                   	pop    %edi
f01011a9:	5d                   	pop    %ebp
f01011aa:	c3                   	ret    

f01011ab <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011ab:	55                   	push   %ebp
f01011ac:	89 e5                	mov    %esp,%ebp
f01011ae:	83 ec 18             	sub    $0x18,%esp
f01011b1:	8b 45 08             	mov    0x8(%ebp),%eax
f01011b4:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011b7:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011ba:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011be:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011c1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011c8:	85 c0                	test   %eax,%eax
f01011ca:	74 26                	je     f01011f2 <vsnprintf+0x47>
f01011cc:	85 d2                	test   %edx,%edx
f01011ce:	7e 22                	jle    f01011f2 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011d0:	ff 75 14             	pushl  0x14(%ebp)
f01011d3:	ff 75 10             	pushl  0x10(%ebp)
f01011d6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011d9:	50                   	push   %eax
f01011da:	68 a6 0d 10 f0       	push   $0xf0100da6
f01011df:	e8 fc fb ff ff       	call   f0100de0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011e7:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011ed:	83 c4 10             	add    $0x10,%esp
f01011f0:	eb 05                	jmp    f01011f7 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011f2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011f7:	c9                   	leave  
f01011f8:	c3                   	ret    

f01011f9 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011f9:	55                   	push   %ebp
f01011fa:	89 e5                	mov    %esp,%ebp
f01011fc:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011ff:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101202:	50                   	push   %eax
f0101203:	ff 75 10             	pushl  0x10(%ebp)
f0101206:	ff 75 0c             	pushl  0xc(%ebp)
f0101209:	ff 75 08             	pushl  0x8(%ebp)
f010120c:	e8 9a ff ff ff       	call   f01011ab <vsnprintf>
	va_end(ap);

	return rc;
}
f0101211:	c9                   	leave  
f0101212:	c3                   	ret    

f0101213 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101213:	55                   	push   %ebp
f0101214:	89 e5                	mov    %esp,%ebp
f0101216:	57                   	push   %edi
f0101217:	56                   	push   %esi
f0101218:	53                   	push   %ebx
f0101219:	83 ec 0c             	sub    $0xc,%esp
f010121c:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010121f:	85 c0                	test   %eax,%eax
f0101221:	74 11                	je     f0101234 <readline+0x21>
		cprintf("%s", prompt);
f0101223:	83 ec 08             	sub    $0x8,%esp
f0101226:	50                   	push   %eax
f0101227:	68 8a 1e 10 f0       	push   $0xf0101e8a
f010122c:	e8 57 f7 ff ff       	call   f0100988 <cprintf>
f0101231:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101234:	83 ec 0c             	sub    $0xc,%esp
f0101237:	6a 00                	push   $0x0
f0101239:	e8 3e f4 ff ff       	call   f010067c <iscons>
f010123e:	89 c7                	mov    %eax,%edi
f0101240:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101243:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101248:	e8 1e f4 ff ff       	call   f010066b <getchar>
f010124d:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010124f:	85 c0                	test   %eax,%eax
f0101251:	79 18                	jns    f010126b <readline+0x58>
			cprintf("read error: %e\n", c);
f0101253:	83 ec 08             	sub    $0x8,%esp
f0101256:	50                   	push   %eax
f0101257:	68 6c 20 10 f0       	push   $0xf010206c
f010125c:	e8 27 f7 ff ff       	call   f0100988 <cprintf>
			return NULL;
f0101261:	83 c4 10             	add    $0x10,%esp
f0101264:	b8 00 00 00 00       	mov    $0x0,%eax
f0101269:	eb 79                	jmp    f01012e4 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010126b:	83 f8 08             	cmp    $0x8,%eax
f010126e:	0f 94 c2             	sete   %dl
f0101271:	83 f8 7f             	cmp    $0x7f,%eax
f0101274:	0f 94 c0             	sete   %al
f0101277:	08 c2                	or     %al,%dl
f0101279:	74 1a                	je     f0101295 <readline+0x82>
f010127b:	85 f6                	test   %esi,%esi
f010127d:	7e 16                	jle    f0101295 <readline+0x82>
			if (echoing)
f010127f:	85 ff                	test   %edi,%edi
f0101281:	74 0d                	je     f0101290 <readline+0x7d>
				cputchar('\b');
f0101283:	83 ec 0c             	sub    $0xc,%esp
f0101286:	6a 08                	push   $0x8
f0101288:	e8 ce f3 ff ff       	call   f010065b <cputchar>
f010128d:	83 c4 10             	add    $0x10,%esp
			i--;
f0101290:	83 ee 01             	sub    $0x1,%esi
f0101293:	eb b3                	jmp    f0101248 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101295:	83 fb 1f             	cmp    $0x1f,%ebx
f0101298:	7e 23                	jle    f01012bd <readline+0xaa>
f010129a:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012a0:	7f 1b                	jg     f01012bd <readline+0xaa>
			if (echoing)
f01012a2:	85 ff                	test   %edi,%edi
f01012a4:	74 0c                	je     f01012b2 <readline+0x9f>
				cputchar(c);
f01012a6:	83 ec 0c             	sub    $0xc,%esp
f01012a9:	53                   	push   %ebx
f01012aa:	e8 ac f3 ff ff       	call   f010065b <cputchar>
f01012af:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012b2:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012b8:	8d 76 01             	lea    0x1(%esi),%esi
f01012bb:	eb 8b                	jmp    f0101248 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012bd:	83 fb 0a             	cmp    $0xa,%ebx
f01012c0:	74 05                	je     f01012c7 <readline+0xb4>
f01012c2:	83 fb 0d             	cmp    $0xd,%ebx
f01012c5:	75 81                	jne    f0101248 <readline+0x35>
			if (echoing)
f01012c7:	85 ff                	test   %edi,%edi
f01012c9:	74 0d                	je     f01012d8 <readline+0xc5>
				cputchar('\n');
f01012cb:	83 ec 0c             	sub    $0xc,%esp
f01012ce:	6a 0a                	push   $0xa
f01012d0:	e8 86 f3 ff ff       	call   f010065b <cputchar>
f01012d5:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012d8:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012df:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012e4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012e7:	5b                   	pop    %ebx
f01012e8:	5e                   	pop    %esi
f01012e9:	5f                   	pop    %edi
f01012ea:	5d                   	pop    %ebp
f01012eb:	c3                   	ret    

f01012ec <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012ec:	55                   	push   %ebp
f01012ed:	89 e5                	mov    %esp,%ebp
f01012ef:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01012f7:	eb 03                	jmp    f01012fc <strlen+0x10>
		n++;
f01012f9:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012fc:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101300:	75 f7                	jne    f01012f9 <strlen+0xd>
		n++;
	return n;
}
f0101302:	5d                   	pop    %ebp
f0101303:	c3                   	ret    

f0101304 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101304:	55                   	push   %ebp
f0101305:	89 e5                	mov    %esp,%ebp
f0101307:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010130a:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010130d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101312:	eb 03                	jmp    f0101317 <strnlen+0x13>
		n++;
f0101314:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101317:	39 c2                	cmp    %eax,%edx
f0101319:	74 08                	je     f0101323 <strnlen+0x1f>
f010131b:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010131f:	75 f3                	jne    f0101314 <strnlen+0x10>
f0101321:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101323:	5d                   	pop    %ebp
f0101324:	c3                   	ret    

f0101325 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101325:	55                   	push   %ebp
f0101326:	89 e5                	mov    %esp,%ebp
f0101328:	53                   	push   %ebx
f0101329:	8b 45 08             	mov    0x8(%ebp),%eax
f010132c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010132f:	89 c2                	mov    %eax,%edx
f0101331:	83 c2 01             	add    $0x1,%edx
f0101334:	83 c1 01             	add    $0x1,%ecx
f0101337:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010133b:	88 5a ff             	mov    %bl,-0x1(%edx)
f010133e:	84 db                	test   %bl,%bl
f0101340:	75 ef                	jne    f0101331 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101342:	5b                   	pop    %ebx
f0101343:	5d                   	pop    %ebp
f0101344:	c3                   	ret    

f0101345 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101345:	55                   	push   %ebp
f0101346:	89 e5                	mov    %esp,%ebp
f0101348:	53                   	push   %ebx
f0101349:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010134c:	53                   	push   %ebx
f010134d:	e8 9a ff ff ff       	call   f01012ec <strlen>
f0101352:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101355:	ff 75 0c             	pushl  0xc(%ebp)
f0101358:	01 d8                	add    %ebx,%eax
f010135a:	50                   	push   %eax
f010135b:	e8 c5 ff ff ff       	call   f0101325 <strcpy>
	return dst;
}
f0101360:	89 d8                	mov    %ebx,%eax
f0101362:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101365:	c9                   	leave  
f0101366:	c3                   	ret    

f0101367 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101367:	55                   	push   %ebp
f0101368:	89 e5                	mov    %esp,%ebp
f010136a:	56                   	push   %esi
f010136b:	53                   	push   %ebx
f010136c:	8b 75 08             	mov    0x8(%ebp),%esi
f010136f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101372:	89 f3                	mov    %esi,%ebx
f0101374:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101377:	89 f2                	mov    %esi,%edx
f0101379:	eb 0f                	jmp    f010138a <strncpy+0x23>
		*dst++ = *src;
f010137b:	83 c2 01             	add    $0x1,%edx
f010137e:	0f b6 01             	movzbl (%ecx),%eax
f0101381:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101384:	80 39 01             	cmpb   $0x1,(%ecx)
f0101387:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010138a:	39 da                	cmp    %ebx,%edx
f010138c:	75 ed                	jne    f010137b <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010138e:	89 f0                	mov    %esi,%eax
f0101390:	5b                   	pop    %ebx
f0101391:	5e                   	pop    %esi
f0101392:	5d                   	pop    %ebp
f0101393:	c3                   	ret    

f0101394 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101394:	55                   	push   %ebp
f0101395:	89 e5                	mov    %esp,%ebp
f0101397:	56                   	push   %esi
f0101398:	53                   	push   %ebx
f0101399:	8b 75 08             	mov    0x8(%ebp),%esi
f010139c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010139f:	8b 55 10             	mov    0x10(%ebp),%edx
f01013a2:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013a4:	85 d2                	test   %edx,%edx
f01013a6:	74 21                	je     f01013c9 <strlcpy+0x35>
f01013a8:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01013ac:	89 f2                	mov    %esi,%edx
f01013ae:	eb 09                	jmp    f01013b9 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013b0:	83 c2 01             	add    $0x1,%edx
f01013b3:	83 c1 01             	add    $0x1,%ecx
f01013b6:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013b9:	39 c2                	cmp    %eax,%edx
f01013bb:	74 09                	je     f01013c6 <strlcpy+0x32>
f01013bd:	0f b6 19             	movzbl (%ecx),%ebx
f01013c0:	84 db                	test   %bl,%bl
f01013c2:	75 ec                	jne    f01013b0 <strlcpy+0x1c>
f01013c4:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013c6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013c9:	29 f0                	sub    %esi,%eax
}
f01013cb:	5b                   	pop    %ebx
f01013cc:	5e                   	pop    %esi
f01013cd:	5d                   	pop    %ebp
f01013ce:	c3                   	ret    

f01013cf <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013cf:	55                   	push   %ebp
f01013d0:	89 e5                	mov    %esp,%ebp
f01013d2:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013d5:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013d8:	eb 06                	jmp    f01013e0 <strcmp+0x11>
		p++, q++;
f01013da:	83 c1 01             	add    $0x1,%ecx
f01013dd:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013e0:	0f b6 01             	movzbl (%ecx),%eax
f01013e3:	84 c0                	test   %al,%al
f01013e5:	74 04                	je     f01013eb <strcmp+0x1c>
f01013e7:	3a 02                	cmp    (%edx),%al
f01013e9:	74 ef                	je     f01013da <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013eb:	0f b6 c0             	movzbl %al,%eax
f01013ee:	0f b6 12             	movzbl (%edx),%edx
f01013f1:	29 d0                	sub    %edx,%eax
}
f01013f3:	5d                   	pop    %ebp
f01013f4:	c3                   	ret    

f01013f5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013f5:	55                   	push   %ebp
f01013f6:	89 e5                	mov    %esp,%ebp
f01013f8:	53                   	push   %ebx
f01013f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01013fc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013ff:	89 c3                	mov    %eax,%ebx
f0101401:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101404:	eb 06                	jmp    f010140c <strncmp+0x17>
		n--, p++, q++;
f0101406:	83 c0 01             	add    $0x1,%eax
f0101409:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010140c:	39 d8                	cmp    %ebx,%eax
f010140e:	74 15                	je     f0101425 <strncmp+0x30>
f0101410:	0f b6 08             	movzbl (%eax),%ecx
f0101413:	84 c9                	test   %cl,%cl
f0101415:	74 04                	je     f010141b <strncmp+0x26>
f0101417:	3a 0a                	cmp    (%edx),%cl
f0101419:	74 eb                	je     f0101406 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010141b:	0f b6 00             	movzbl (%eax),%eax
f010141e:	0f b6 12             	movzbl (%edx),%edx
f0101421:	29 d0                	sub    %edx,%eax
f0101423:	eb 05                	jmp    f010142a <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101425:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010142a:	5b                   	pop    %ebx
f010142b:	5d                   	pop    %ebp
f010142c:	c3                   	ret    

f010142d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010142d:	55                   	push   %ebp
f010142e:	89 e5                	mov    %esp,%ebp
f0101430:	8b 45 08             	mov    0x8(%ebp),%eax
f0101433:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101437:	eb 07                	jmp    f0101440 <strchr+0x13>
		if (*s == c)
f0101439:	38 ca                	cmp    %cl,%dl
f010143b:	74 0f                	je     f010144c <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010143d:	83 c0 01             	add    $0x1,%eax
f0101440:	0f b6 10             	movzbl (%eax),%edx
f0101443:	84 d2                	test   %dl,%dl
f0101445:	75 f2                	jne    f0101439 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101447:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010144c:	5d                   	pop    %ebp
f010144d:	c3                   	ret    

f010144e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010144e:	55                   	push   %ebp
f010144f:	89 e5                	mov    %esp,%ebp
f0101451:	8b 45 08             	mov    0x8(%ebp),%eax
f0101454:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101458:	eb 03                	jmp    f010145d <strfind+0xf>
f010145a:	83 c0 01             	add    $0x1,%eax
f010145d:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101460:	38 ca                	cmp    %cl,%dl
f0101462:	74 04                	je     f0101468 <strfind+0x1a>
f0101464:	84 d2                	test   %dl,%dl
f0101466:	75 f2                	jne    f010145a <strfind+0xc>
			break;
	return (char *) s;
}
f0101468:	5d                   	pop    %ebp
f0101469:	c3                   	ret    

f010146a <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010146a:	55                   	push   %ebp
f010146b:	89 e5                	mov    %esp,%ebp
f010146d:	57                   	push   %edi
f010146e:	56                   	push   %esi
f010146f:	53                   	push   %ebx
f0101470:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101473:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101476:	85 c9                	test   %ecx,%ecx
f0101478:	74 36                	je     f01014b0 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010147a:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101480:	75 28                	jne    f01014aa <memset+0x40>
f0101482:	f6 c1 03             	test   $0x3,%cl
f0101485:	75 23                	jne    f01014aa <memset+0x40>
		c &= 0xFF;
f0101487:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010148b:	89 d3                	mov    %edx,%ebx
f010148d:	c1 e3 08             	shl    $0x8,%ebx
f0101490:	89 d6                	mov    %edx,%esi
f0101492:	c1 e6 18             	shl    $0x18,%esi
f0101495:	89 d0                	mov    %edx,%eax
f0101497:	c1 e0 10             	shl    $0x10,%eax
f010149a:	09 f0                	or     %esi,%eax
f010149c:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f010149e:	89 d8                	mov    %ebx,%eax
f01014a0:	09 d0                	or     %edx,%eax
f01014a2:	c1 e9 02             	shr    $0x2,%ecx
f01014a5:	fc                   	cld    
f01014a6:	f3 ab                	rep stos %eax,%es:(%edi)
f01014a8:	eb 06                	jmp    f01014b0 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014aa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014ad:	fc                   	cld    
f01014ae:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014b0:	89 f8                	mov    %edi,%eax
f01014b2:	5b                   	pop    %ebx
f01014b3:	5e                   	pop    %esi
f01014b4:	5f                   	pop    %edi
f01014b5:	5d                   	pop    %ebp
f01014b6:	c3                   	ret    

f01014b7 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014b7:	55                   	push   %ebp
f01014b8:	89 e5                	mov    %esp,%ebp
f01014ba:	57                   	push   %edi
f01014bb:	56                   	push   %esi
f01014bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01014bf:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014c2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014c5:	39 c6                	cmp    %eax,%esi
f01014c7:	73 35                	jae    f01014fe <memmove+0x47>
f01014c9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014cc:	39 d0                	cmp    %edx,%eax
f01014ce:	73 2e                	jae    f01014fe <memmove+0x47>
		s += n;
		d += n;
f01014d0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014d3:	89 d6                	mov    %edx,%esi
f01014d5:	09 fe                	or     %edi,%esi
f01014d7:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014dd:	75 13                	jne    f01014f2 <memmove+0x3b>
f01014df:	f6 c1 03             	test   $0x3,%cl
f01014e2:	75 0e                	jne    f01014f2 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01014e4:	83 ef 04             	sub    $0x4,%edi
f01014e7:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014ea:	c1 e9 02             	shr    $0x2,%ecx
f01014ed:	fd                   	std    
f01014ee:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014f0:	eb 09                	jmp    f01014fb <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014f2:	83 ef 01             	sub    $0x1,%edi
f01014f5:	8d 72 ff             	lea    -0x1(%edx),%esi
f01014f8:	fd                   	std    
f01014f9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014fb:	fc                   	cld    
f01014fc:	eb 1d                	jmp    f010151b <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014fe:	89 f2                	mov    %esi,%edx
f0101500:	09 c2                	or     %eax,%edx
f0101502:	f6 c2 03             	test   $0x3,%dl
f0101505:	75 0f                	jne    f0101516 <memmove+0x5f>
f0101507:	f6 c1 03             	test   $0x3,%cl
f010150a:	75 0a                	jne    f0101516 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010150c:	c1 e9 02             	shr    $0x2,%ecx
f010150f:	89 c7                	mov    %eax,%edi
f0101511:	fc                   	cld    
f0101512:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101514:	eb 05                	jmp    f010151b <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101516:	89 c7                	mov    %eax,%edi
f0101518:	fc                   	cld    
f0101519:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010151b:	5e                   	pop    %esi
f010151c:	5f                   	pop    %edi
f010151d:	5d                   	pop    %ebp
f010151e:	c3                   	ret    

f010151f <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010151f:	55                   	push   %ebp
f0101520:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101522:	ff 75 10             	pushl  0x10(%ebp)
f0101525:	ff 75 0c             	pushl  0xc(%ebp)
f0101528:	ff 75 08             	pushl  0x8(%ebp)
f010152b:	e8 87 ff ff ff       	call   f01014b7 <memmove>
}
f0101530:	c9                   	leave  
f0101531:	c3                   	ret    

f0101532 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101532:	55                   	push   %ebp
f0101533:	89 e5                	mov    %esp,%ebp
f0101535:	56                   	push   %esi
f0101536:	53                   	push   %ebx
f0101537:	8b 45 08             	mov    0x8(%ebp),%eax
f010153a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010153d:	89 c6                	mov    %eax,%esi
f010153f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101542:	eb 1a                	jmp    f010155e <memcmp+0x2c>
		if (*s1 != *s2)
f0101544:	0f b6 08             	movzbl (%eax),%ecx
f0101547:	0f b6 1a             	movzbl (%edx),%ebx
f010154a:	38 d9                	cmp    %bl,%cl
f010154c:	74 0a                	je     f0101558 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010154e:	0f b6 c1             	movzbl %cl,%eax
f0101551:	0f b6 db             	movzbl %bl,%ebx
f0101554:	29 d8                	sub    %ebx,%eax
f0101556:	eb 0f                	jmp    f0101567 <memcmp+0x35>
		s1++, s2++;
f0101558:	83 c0 01             	add    $0x1,%eax
f010155b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010155e:	39 f0                	cmp    %esi,%eax
f0101560:	75 e2                	jne    f0101544 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101562:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101567:	5b                   	pop    %ebx
f0101568:	5e                   	pop    %esi
f0101569:	5d                   	pop    %ebp
f010156a:	c3                   	ret    

f010156b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010156b:	55                   	push   %ebp
f010156c:	89 e5                	mov    %esp,%ebp
f010156e:	53                   	push   %ebx
f010156f:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101572:	89 c1                	mov    %eax,%ecx
f0101574:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101577:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010157b:	eb 0a                	jmp    f0101587 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010157d:	0f b6 10             	movzbl (%eax),%edx
f0101580:	39 da                	cmp    %ebx,%edx
f0101582:	74 07                	je     f010158b <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101584:	83 c0 01             	add    $0x1,%eax
f0101587:	39 c8                	cmp    %ecx,%eax
f0101589:	72 f2                	jb     f010157d <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010158b:	5b                   	pop    %ebx
f010158c:	5d                   	pop    %ebp
f010158d:	c3                   	ret    

f010158e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010158e:	55                   	push   %ebp
f010158f:	89 e5                	mov    %esp,%ebp
f0101591:	57                   	push   %edi
f0101592:	56                   	push   %esi
f0101593:	53                   	push   %ebx
f0101594:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101597:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010159a:	eb 03                	jmp    f010159f <strtol+0x11>
		s++;
f010159c:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010159f:	0f b6 01             	movzbl (%ecx),%eax
f01015a2:	3c 20                	cmp    $0x20,%al
f01015a4:	74 f6                	je     f010159c <strtol+0xe>
f01015a6:	3c 09                	cmp    $0x9,%al
f01015a8:	74 f2                	je     f010159c <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015aa:	3c 2b                	cmp    $0x2b,%al
f01015ac:	75 0a                	jne    f01015b8 <strtol+0x2a>
		s++;
f01015ae:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015b1:	bf 00 00 00 00       	mov    $0x0,%edi
f01015b6:	eb 11                	jmp    f01015c9 <strtol+0x3b>
f01015b8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015bd:	3c 2d                	cmp    $0x2d,%al
f01015bf:	75 08                	jne    f01015c9 <strtol+0x3b>
		s++, neg = 1;
f01015c1:	83 c1 01             	add    $0x1,%ecx
f01015c4:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015c9:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015cf:	75 15                	jne    f01015e6 <strtol+0x58>
f01015d1:	80 39 30             	cmpb   $0x30,(%ecx)
f01015d4:	75 10                	jne    f01015e6 <strtol+0x58>
f01015d6:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01015da:	75 7c                	jne    f0101658 <strtol+0xca>
		s += 2, base = 16;
f01015dc:	83 c1 02             	add    $0x2,%ecx
f01015df:	bb 10 00 00 00       	mov    $0x10,%ebx
f01015e4:	eb 16                	jmp    f01015fc <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01015e6:	85 db                	test   %ebx,%ebx
f01015e8:	75 12                	jne    f01015fc <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01015ea:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01015ef:	80 39 30             	cmpb   $0x30,(%ecx)
f01015f2:	75 08                	jne    f01015fc <strtol+0x6e>
		s++, base = 8;
f01015f4:	83 c1 01             	add    $0x1,%ecx
f01015f7:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01015fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0101601:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101604:	0f b6 11             	movzbl (%ecx),%edx
f0101607:	8d 72 d0             	lea    -0x30(%edx),%esi
f010160a:	89 f3                	mov    %esi,%ebx
f010160c:	80 fb 09             	cmp    $0x9,%bl
f010160f:	77 08                	ja     f0101619 <strtol+0x8b>
			dig = *s - '0';
f0101611:	0f be d2             	movsbl %dl,%edx
f0101614:	83 ea 30             	sub    $0x30,%edx
f0101617:	eb 22                	jmp    f010163b <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0101619:	8d 72 9f             	lea    -0x61(%edx),%esi
f010161c:	89 f3                	mov    %esi,%ebx
f010161e:	80 fb 19             	cmp    $0x19,%bl
f0101621:	77 08                	ja     f010162b <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101623:	0f be d2             	movsbl %dl,%edx
f0101626:	83 ea 57             	sub    $0x57,%edx
f0101629:	eb 10                	jmp    f010163b <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010162b:	8d 72 bf             	lea    -0x41(%edx),%esi
f010162e:	89 f3                	mov    %esi,%ebx
f0101630:	80 fb 19             	cmp    $0x19,%bl
f0101633:	77 16                	ja     f010164b <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101635:	0f be d2             	movsbl %dl,%edx
f0101638:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010163b:	3b 55 10             	cmp    0x10(%ebp),%edx
f010163e:	7d 0b                	jge    f010164b <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101640:	83 c1 01             	add    $0x1,%ecx
f0101643:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101647:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101649:	eb b9                	jmp    f0101604 <strtol+0x76>

	if (endptr)
f010164b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010164f:	74 0d                	je     f010165e <strtol+0xd0>
		*endptr = (char *) s;
f0101651:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101654:	89 0e                	mov    %ecx,(%esi)
f0101656:	eb 06                	jmp    f010165e <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101658:	85 db                	test   %ebx,%ebx
f010165a:	74 98                	je     f01015f4 <strtol+0x66>
f010165c:	eb 9e                	jmp    f01015fc <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010165e:	89 c2                	mov    %eax,%edx
f0101660:	f7 da                	neg    %edx
f0101662:	85 ff                	test   %edi,%edi
f0101664:	0f 45 c2             	cmovne %edx,%eax
}
f0101667:	5b                   	pop    %ebx
f0101668:	5e                   	pop    %esi
f0101669:	5f                   	pop    %edi
f010166a:	5d                   	pop    %ebp
f010166b:	c3                   	ret    
f010166c:	66 90                	xchg   %ax,%ax
f010166e:	66 90                	xchg   %ax,%ax

f0101670 <__udivdi3>:
f0101670:	55                   	push   %ebp
f0101671:	57                   	push   %edi
f0101672:	56                   	push   %esi
f0101673:	53                   	push   %ebx
f0101674:	83 ec 1c             	sub    $0x1c,%esp
f0101677:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010167b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010167f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101683:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101687:	85 f6                	test   %esi,%esi
f0101689:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010168d:	89 ca                	mov    %ecx,%edx
f010168f:	89 f8                	mov    %edi,%eax
f0101691:	75 3d                	jne    f01016d0 <__udivdi3+0x60>
f0101693:	39 cf                	cmp    %ecx,%edi
f0101695:	0f 87 c5 00 00 00    	ja     f0101760 <__udivdi3+0xf0>
f010169b:	85 ff                	test   %edi,%edi
f010169d:	89 fd                	mov    %edi,%ebp
f010169f:	75 0b                	jne    f01016ac <__udivdi3+0x3c>
f01016a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01016a6:	31 d2                	xor    %edx,%edx
f01016a8:	f7 f7                	div    %edi
f01016aa:	89 c5                	mov    %eax,%ebp
f01016ac:	89 c8                	mov    %ecx,%eax
f01016ae:	31 d2                	xor    %edx,%edx
f01016b0:	f7 f5                	div    %ebp
f01016b2:	89 c1                	mov    %eax,%ecx
f01016b4:	89 d8                	mov    %ebx,%eax
f01016b6:	89 cf                	mov    %ecx,%edi
f01016b8:	f7 f5                	div    %ebp
f01016ba:	89 c3                	mov    %eax,%ebx
f01016bc:	89 d8                	mov    %ebx,%eax
f01016be:	89 fa                	mov    %edi,%edx
f01016c0:	83 c4 1c             	add    $0x1c,%esp
f01016c3:	5b                   	pop    %ebx
f01016c4:	5e                   	pop    %esi
f01016c5:	5f                   	pop    %edi
f01016c6:	5d                   	pop    %ebp
f01016c7:	c3                   	ret    
f01016c8:	90                   	nop
f01016c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016d0:	39 ce                	cmp    %ecx,%esi
f01016d2:	77 74                	ja     f0101748 <__udivdi3+0xd8>
f01016d4:	0f bd fe             	bsr    %esi,%edi
f01016d7:	83 f7 1f             	xor    $0x1f,%edi
f01016da:	0f 84 98 00 00 00    	je     f0101778 <__udivdi3+0x108>
f01016e0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01016e5:	89 f9                	mov    %edi,%ecx
f01016e7:	89 c5                	mov    %eax,%ebp
f01016e9:	29 fb                	sub    %edi,%ebx
f01016eb:	d3 e6                	shl    %cl,%esi
f01016ed:	89 d9                	mov    %ebx,%ecx
f01016ef:	d3 ed                	shr    %cl,%ebp
f01016f1:	89 f9                	mov    %edi,%ecx
f01016f3:	d3 e0                	shl    %cl,%eax
f01016f5:	09 ee                	or     %ebp,%esi
f01016f7:	89 d9                	mov    %ebx,%ecx
f01016f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016fd:	89 d5                	mov    %edx,%ebp
f01016ff:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101703:	d3 ed                	shr    %cl,%ebp
f0101705:	89 f9                	mov    %edi,%ecx
f0101707:	d3 e2                	shl    %cl,%edx
f0101709:	89 d9                	mov    %ebx,%ecx
f010170b:	d3 e8                	shr    %cl,%eax
f010170d:	09 c2                	or     %eax,%edx
f010170f:	89 d0                	mov    %edx,%eax
f0101711:	89 ea                	mov    %ebp,%edx
f0101713:	f7 f6                	div    %esi
f0101715:	89 d5                	mov    %edx,%ebp
f0101717:	89 c3                	mov    %eax,%ebx
f0101719:	f7 64 24 0c          	mull   0xc(%esp)
f010171d:	39 d5                	cmp    %edx,%ebp
f010171f:	72 10                	jb     f0101731 <__udivdi3+0xc1>
f0101721:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101725:	89 f9                	mov    %edi,%ecx
f0101727:	d3 e6                	shl    %cl,%esi
f0101729:	39 c6                	cmp    %eax,%esi
f010172b:	73 07                	jae    f0101734 <__udivdi3+0xc4>
f010172d:	39 d5                	cmp    %edx,%ebp
f010172f:	75 03                	jne    f0101734 <__udivdi3+0xc4>
f0101731:	83 eb 01             	sub    $0x1,%ebx
f0101734:	31 ff                	xor    %edi,%edi
f0101736:	89 d8                	mov    %ebx,%eax
f0101738:	89 fa                	mov    %edi,%edx
f010173a:	83 c4 1c             	add    $0x1c,%esp
f010173d:	5b                   	pop    %ebx
f010173e:	5e                   	pop    %esi
f010173f:	5f                   	pop    %edi
f0101740:	5d                   	pop    %ebp
f0101741:	c3                   	ret    
f0101742:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101748:	31 ff                	xor    %edi,%edi
f010174a:	31 db                	xor    %ebx,%ebx
f010174c:	89 d8                	mov    %ebx,%eax
f010174e:	89 fa                	mov    %edi,%edx
f0101750:	83 c4 1c             	add    $0x1c,%esp
f0101753:	5b                   	pop    %ebx
f0101754:	5e                   	pop    %esi
f0101755:	5f                   	pop    %edi
f0101756:	5d                   	pop    %ebp
f0101757:	c3                   	ret    
f0101758:	90                   	nop
f0101759:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101760:	89 d8                	mov    %ebx,%eax
f0101762:	f7 f7                	div    %edi
f0101764:	31 ff                	xor    %edi,%edi
f0101766:	89 c3                	mov    %eax,%ebx
f0101768:	89 d8                	mov    %ebx,%eax
f010176a:	89 fa                	mov    %edi,%edx
f010176c:	83 c4 1c             	add    $0x1c,%esp
f010176f:	5b                   	pop    %ebx
f0101770:	5e                   	pop    %esi
f0101771:	5f                   	pop    %edi
f0101772:	5d                   	pop    %ebp
f0101773:	c3                   	ret    
f0101774:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101778:	39 ce                	cmp    %ecx,%esi
f010177a:	72 0c                	jb     f0101788 <__udivdi3+0x118>
f010177c:	31 db                	xor    %ebx,%ebx
f010177e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101782:	0f 87 34 ff ff ff    	ja     f01016bc <__udivdi3+0x4c>
f0101788:	bb 01 00 00 00       	mov    $0x1,%ebx
f010178d:	e9 2a ff ff ff       	jmp    f01016bc <__udivdi3+0x4c>
f0101792:	66 90                	xchg   %ax,%ax
f0101794:	66 90                	xchg   %ax,%ax
f0101796:	66 90                	xchg   %ax,%ax
f0101798:	66 90                	xchg   %ax,%ax
f010179a:	66 90                	xchg   %ax,%ax
f010179c:	66 90                	xchg   %ax,%ax
f010179e:	66 90                	xchg   %ax,%ax

f01017a0 <__umoddi3>:
f01017a0:	55                   	push   %ebp
f01017a1:	57                   	push   %edi
f01017a2:	56                   	push   %esi
f01017a3:	53                   	push   %ebx
f01017a4:	83 ec 1c             	sub    $0x1c,%esp
f01017a7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017ab:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01017af:	8b 74 24 34          	mov    0x34(%esp),%esi
f01017b3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01017b7:	85 d2                	test   %edx,%edx
f01017b9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01017bd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017c1:	89 f3                	mov    %esi,%ebx
f01017c3:	89 3c 24             	mov    %edi,(%esp)
f01017c6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01017ca:	75 1c                	jne    f01017e8 <__umoddi3+0x48>
f01017cc:	39 f7                	cmp    %esi,%edi
f01017ce:	76 50                	jbe    f0101820 <__umoddi3+0x80>
f01017d0:	89 c8                	mov    %ecx,%eax
f01017d2:	89 f2                	mov    %esi,%edx
f01017d4:	f7 f7                	div    %edi
f01017d6:	89 d0                	mov    %edx,%eax
f01017d8:	31 d2                	xor    %edx,%edx
f01017da:	83 c4 1c             	add    $0x1c,%esp
f01017dd:	5b                   	pop    %ebx
f01017de:	5e                   	pop    %esi
f01017df:	5f                   	pop    %edi
f01017e0:	5d                   	pop    %ebp
f01017e1:	c3                   	ret    
f01017e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017e8:	39 f2                	cmp    %esi,%edx
f01017ea:	89 d0                	mov    %edx,%eax
f01017ec:	77 52                	ja     f0101840 <__umoddi3+0xa0>
f01017ee:	0f bd ea             	bsr    %edx,%ebp
f01017f1:	83 f5 1f             	xor    $0x1f,%ebp
f01017f4:	75 5a                	jne    f0101850 <__umoddi3+0xb0>
f01017f6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01017fa:	0f 82 e0 00 00 00    	jb     f01018e0 <__umoddi3+0x140>
f0101800:	39 0c 24             	cmp    %ecx,(%esp)
f0101803:	0f 86 d7 00 00 00    	jbe    f01018e0 <__umoddi3+0x140>
f0101809:	8b 44 24 08          	mov    0x8(%esp),%eax
f010180d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101811:	83 c4 1c             	add    $0x1c,%esp
f0101814:	5b                   	pop    %ebx
f0101815:	5e                   	pop    %esi
f0101816:	5f                   	pop    %edi
f0101817:	5d                   	pop    %ebp
f0101818:	c3                   	ret    
f0101819:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101820:	85 ff                	test   %edi,%edi
f0101822:	89 fd                	mov    %edi,%ebp
f0101824:	75 0b                	jne    f0101831 <__umoddi3+0x91>
f0101826:	b8 01 00 00 00       	mov    $0x1,%eax
f010182b:	31 d2                	xor    %edx,%edx
f010182d:	f7 f7                	div    %edi
f010182f:	89 c5                	mov    %eax,%ebp
f0101831:	89 f0                	mov    %esi,%eax
f0101833:	31 d2                	xor    %edx,%edx
f0101835:	f7 f5                	div    %ebp
f0101837:	89 c8                	mov    %ecx,%eax
f0101839:	f7 f5                	div    %ebp
f010183b:	89 d0                	mov    %edx,%eax
f010183d:	eb 99                	jmp    f01017d8 <__umoddi3+0x38>
f010183f:	90                   	nop
f0101840:	89 c8                	mov    %ecx,%eax
f0101842:	89 f2                	mov    %esi,%edx
f0101844:	83 c4 1c             	add    $0x1c,%esp
f0101847:	5b                   	pop    %ebx
f0101848:	5e                   	pop    %esi
f0101849:	5f                   	pop    %edi
f010184a:	5d                   	pop    %ebp
f010184b:	c3                   	ret    
f010184c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101850:	8b 34 24             	mov    (%esp),%esi
f0101853:	bf 20 00 00 00       	mov    $0x20,%edi
f0101858:	89 e9                	mov    %ebp,%ecx
f010185a:	29 ef                	sub    %ebp,%edi
f010185c:	d3 e0                	shl    %cl,%eax
f010185e:	89 f9                	mov    %edi,%ecx
f0101860:	89 f2                	mov    %esi,%edx
f0101862:	d3 ea                	shr    %cl,%edx
f0101864:	89 e9                	mov    %ebp,%ecx
f0101866:	09 c2                	or     %eax,%edx
f0101868:	89 d8                	mov    %ebx,%eax
f010186a:	89 14 24             	mov    %edx,(%esp)
f010186d:	89 f2                	mov    %esi,%edx
f010186f:	d3 e2                	shl    %cl,%edx
f0101871:	89 f9                	mov    %edi,%ecx
f0101873:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101877:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010187b:	d3 e8                	shr    %cl,%eax
f010187d:	89 e9                	mov    %ebp,%ecx
f010187f:	89 c6                	mov    %eax,%esi
f0101881:	d3 e3                	shl    %cl,%ebx
f0101883:	89 f9                	mov    %edi,%ecx
f0101885:	89 d0                	mov    %edx,%eax
f0101887:	d3 e8                	shr    %cl,%eax
f0101889:	89 e9                	mov    %ebp,%ecx
f010188b:	09 d8                	or     %ebx,%eax
f010188d:	89 d3                	mov    %edx,%ebx
f010188f:	89 f2                	mov    %esi,%edx
f0101891:	f7 34 24             	divl   (%esp)
f0101894:	89 d6                	mov    %edx,%esi
f0101896:	d3 e3                	shl    %cl,%ebx
f0101898:	f7 64 24 04          	mull   0x4(%esp)
f010189c:	39 d6                	cmp    %edx,%esi
f010189e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01018a2:	89 d1                	mov    %edx,%ecx
f01018a4:	89 c3                	mov    %eax,%ebx
f01018a6:	72 08                	jb     f01018b0 <__umoddi3+0x110>
f01018a8:	75 11                	jne    f01018bb <__umoddi3+0x11b>
f01018aa:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01018ae:	73 0b                	jae    f01018bb <__umoddi3+0x11b>
f01018b0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01018b4:	1b 14 24             	sbb    (%esp),%edx
f01018b7:	89 d1                	mov    %edx,%ecx
f01018b9:	89 c3                	mov    %eax,%ebx
f01018bb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01018bf:	29 da                	sub    %ebx,%edx
f01018c1:	19 ce                	sbb    %ecx,%esi
f01018c3:	89 f9                	mov    %edi,%ecx
f01018c5:	89 f0                	mov    %esi,%eax
f01018c7:	d3 e0                	shl    %cl,%eax
f01018c9:	89 e9                	mov    %ebp,%ecx
f01018cb:	d3 ea                	shr    %cl,%edx
f01018cd:	89 e9                	mov    %ebp,%ecx
f01018cf:	d3 ee                	shr    %cl,%esi
f01018d1:	09 d0                	or     %edx,%eax
f01018d3:	89 f2                	mov    %esi,%edx
f01018d5:	83 c4 1c             	add    $0x1c,%esp
f01018d8:	5b                   	pop    %ebx
f01018d9:	5e                   	pop    %esi
f01018da:	5f                   	pop    %edi
f01018db:	5d                   	pop    %ebp
f01018dc:	c3                   	ret    
f01018dd:	8d 76 00             	lea    0x0(%esi),%esi
f01018e0:	29 f9                	sub    %edi,%ecx
f01018e2:	19 d6                	sbb    %edx,%esi
f01018e4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018e8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018ec:	e9 18 ff ff ff       	jmp    f0101809 <__umoddi3+0x69>
