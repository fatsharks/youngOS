org  0100h

BaseOfStack		equ	0100h

BaseOfKernelFile	equ	 08000h	; KERNEL.BIN 被加载到的位置 ----  段地址
OffsetOfKernelFile	equ	     0h	; KERNEL.BIN 被加载到的位置 ---- 偏移地址


	jmp	LABEL_START		; Start

; 下面是 FAT12 磁盘的头, 之所以包含它是因为下面用到了磁盘的一些信息
%include	"fat12hdr.inc"


LABEL_START:			; <--- 从这里开始 *************
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, BaseOfStack

	mov	dh, 0			; "Loading  "
	call	DispStr			; 显示字符串

	; 下面在 A 盘的根目录寻找 KERNEL.BIN
	mov	word [wSectorNo], SectorNoOfRootDirectory	;从根目录区第一个扇区19开始
	xor	ah, ah	; `.
	xor	dl, dl	;  | 软驱复位
	int	13h	; /
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0	; wRootDirSizeForLoop=14，根目录区共14个扇区
	jz	LABEL_NO_KERNELBIN		;  | 判断根目录区是不是已经读完,
	dec	word [wRootDirSizeForLoop]	; /  读完表示没有找到 KERNEL.BIN
	mov	ax, BaseOfKernelFile
	mov	es, ax			; es <- BaseOfKernelFile
	mov	bx, OffsetOfKernelFile	; bx <- OffsetOfKernelFile es:bx <- kernel文件内容
	mov	ax, [wSectorNo]		; ax <- Root Directory 中的某 Sector 号
	mov	cl, 1
	call	ReadSector

	mov	si, KernelFileName	; ds:si -> "KERNEL  BIN"
	mov	di, OffsetOfKernelFile; es:di <- kernel文件内容
	cld                        ;置DF为0，字符串操作时，si自增 
	mov	dx, 10h             ; 文件信息存放在根目录区的条目中，一个条目32个字节，一个扇区512个字节刚好可以存储16个条目
LABEL_SEARCH_FOR_KERNELBIN:
    ; 在条目中寻找匹配文件名
	cmp	dx, 0				  ; `.
	jz	LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR;  | 循环次数控制, 如果已经读完
	dec	dx				  ; /  了一个 Sector, 就跳到下一个
	mov	cx, 11
LABEL_CMP_FILENAME:
	cmp	cx, 0			; `.
	jz	LABEL_FILENAME_FOUND	;  | 循环次数控制, 如果比较了 11 个字符都
	dec	cx			; /  相等, 表示找到
	lodsb				; ds:si -> al   "KERNEL  BIN",循环一次，si+1
	cmp	al, byte [es:di]	; if al == es:di kernel文件内容
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT
LABEL_GO_ON:
	inc	di
	jmp	LABEL_CMP_FILENAME	;	继续循环

LABEL_DIFFERENT:
	and	di, 0FFE0h		; else`. 让 di 是 20h 的倍数 ,一个条目是32个字节，20h
	add	di, 20h			;      |
	mov	si, KernelFileName	;      | di += 20h  下一个目录条目
	jmp	LABEL_SEARCH_FOR_KERNELBIN;   /

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_KERNELBIN:
	mov	dh, 2			; "No KERNEL."
	call	DispStr			; 显示字符串
%ifdef	_LOADER_DEBUG_
	mov	ax, 4c00h		; `.
	int	21h			; / 没有找到 KERNEL.BIN, 回到 DOS
%else
	jmp	$			; 没有找到 KERNEL.BIN, 死循环在这里
%endif

LABEL_FILENAME_FOUND:			; 找到 KERNEL.BIN 后便来到这里继续
	mov	ax, RootDirSectors
	and	di, 0FFF0h		; di -> 当前条目的开始TODO:0FFE0h

	push	eax
	mov	eax, [es : di + 01Ch]		; 条目开始地址偏移01Ch个字节为文件大小
	mov	dword [dwKernelSize], eax	; / 保存 KERNEL.BIN 文件大小
	pop	eax

	add	di, 01Ah		; di -> 首 Sector
                        ; 条目开始地址偏移01Ah个字节为文件内容存储的开始簇号
                        ; 根据BPB_SecPerClus计算出开始扇区号,此处簇号等于扇区号
	mov	cx, word [es:di]
	push	cx			; 保存此 Sector 在 FAT 中的序号  与下文调用读取扇区的“call ReadSector"后的pop ax 相对应  
	add	cx, ax
	add	cx, DeltaSectorNo	; cl <- LOADER.BIN 的起始扇区号(0-based) DeltaSectorNo=17
	mov	ax, BaseOfKernelFile
	mov	es, ax			; es <- BaseOfKernelFile
	mov	bx, OffsetOfKernelFile	; bx <- OffsetOfKernelFile　es:bx 指向kernel文件的内容
	mov	ax, cx			; ax <- Sector 号

LABEL_GOON_LOADING_FILE:
	push	ax			; `.
	push	bx			;  |
	mov	ah, 0Eh			;  | 每读一个扇区就在 "Loading  " 后面
	mov	al, '.'			;  | 打一个点, 形成这样的效果:
	mov	bl, 0Fh			;  | Loading ......
	int	10h			;  |
	pop	bx			;  |
	pop	ax			; /

	mov	cl, 1           ; 起始扇区号在上一步的ax中
	call	ReadSector
	pop	ax			; 取出此 Sector 在 FAT 中的序号　与上文的push cx相对应
	call	GetFATEntry
	cmp	ax, 0FFFh   ; 比较 ax与0fffh的值，相等则表示此簇已经是最后一个，Kernel.bin已加载到内存
	jz	LABEL_FILE_LOADED
	push	ax			; 保存 Sector 在 FAT 中的序号
	mov	dx, RootDirSectors
	add	ax, dx
	add	ax, DeltaSectorNo   ;计算 ax簇号对应扇区号
	add	bx, [BPB_BytsPerSec] ;bx<-bx+[BPB_BytsPerSec],es:bx指向下一段未使用的内存
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:

	call	KillMotor		; 关闭软驱马达

	mov	dh, 1			; "Ready."
	call	DispStr			; 显示字符串

	jmp	$


;============================================================================
;变量
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory 占用的扇区数
wSectorNo		dw	0		; 要读取的扇区号
bOdd			db	0		; 奇数还是偶数
dwKernelSize		dd	0		; KERNEL.BIN 文件大小

;============================================================================
;字符串
;----------------------------------------------------------------------------
KernelFileName		db	"KERNEL  BIN", 0	; KERNEL.BIN 之文件名
; 为简化代码, 下面每个字符串的长度均为 MessageLength
MessageLength		equ	9
LoadMessage:		db	"Loading  "
Message1		db	"Ready.   "
Message2		db	"No KERNEL"
;============================================================================

;----------------------------------------------------------------------------
; 函数名: DispStr
;----------------------------------------------------------------------------
; 作用:
;	显示一个字符串, 函数开始时 dh 中应该是字符串序号(0-based)
DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, LoadMessage
	mov	bp, ax			; ┓
	mov	ax, ds			; ┣ ES:BP = 串地址
	mov	es, ax			; ┛
	mov	cx, MessageLength	; CX = 串长度
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 0007h		; 页号为0(BH = 0) 黑底白字(BL = 07h)
	mov	dl, 0
	add	dh, 3			; 从第 3 行往下显示
	int	10h			; int 10h
	ret
;----------------------------------------------------------------------------
; 函数名: ReadSector
;----------------------------------------------------------------------------
; 作用:
;	从序号(Directory Entry 中的 Sector 号)为 ax 的的 Sector 开始, 将 cl 个 Sector 读入 es:bx 中
ReadSector:
	; -----------------------------------------------------------------------
	; 怎样由扇区号求扇区在磁盘中的位置 (扇区号 -> 柱面号, 起始扇区, 磁头号)
	; -----------------------------------------------------------------------
	; 设扇区号为 x
	;                           ┌ 柱面号 = y >> 1
	;       x           ┌ 商 y ┤
	; -------------- => ┤      └ 磁头号 = y & 1
	;  每磁道扇区数     │
	;                   └ 余 z => 起始扇区号 = z + 1
	push	bp
	mov	bp, sp
	sub	esp, 2			; 辟出两个字节的堆栈区域保存要读的扇区数: byte [bp-2]

	mov	byte [bp-2], cl
	push	bx			; 保存 bx
	mov	bl, [BPB_SecPerTrk]	; bl: 除数
	div	bl			; y 在 al 中, z 在 ah 中
	inc	ah			; z ++
	mov	cl, ah			; cl <- 起始扇区号
	mov	dh, al			; dh <- y
	shr	al, 1			; y >> 1 (其实是 y/BPB_NumHeads, 这里BPB_NumHeads=2)
	mov	ch, al			; ch <- 柱面号
	and	dh, 1			; dh & 1 = 磁头号
	pop	bx			; 恢复 bx
	; 至此, "柱面号, 起始扇区, 磁头号" 全部得到 ^^^^^^^^^^^^^^^^^^^^^^^^
	mov	dl, [BS_DrvNum]		; 驱动器号 (0 表示 A 盘)
.GoOnReading:
	mov	ah, 2			; 读
	mov	al, byte [bp-2]		; 读 al 个扇区
	int	13h
	jc	.GoOnReading		; 如果读取错误 CF 会被置为 1, 这时就不停地读, 直到正确为止

	add	esp, 2
	pop	bp

	ret

;----------------------------------------------------------------------------
; 函数名: GetFATEntry
;----------------------------------------------------------------------------
; 作用:
;	找到序号为 ax 的 Sector 在 FAT 中的条目, 结果放在 ax 中
;   参数存放在ax寄存器中，表示一个簇号。输出结果是该簇号在FAT表中的FATENTRY，它的内容仍然是一个簇号，表示文件下一部分所在簇的簇号。
;	需要注意的是, 中间需要读 FAT 的扇区到 es:bx 处, 所以函数一开始保存了 es 和 bx
;   我们知道了扇区号x，然后我们去FAT1中寻找x所对应的FATEntry，我们已经知道一个FAT项占1.5个字节。所以我们用x*3/2=y………z，y为商（偏移量)（字节），相对于FAT1的初始位置的偏移量（FAT项）；Z为余数（0或者1），是判断FATEntry是奇数还是偶数，0表示偶数，1表示奇数。然后我们让y/512=m………n，m为商，n为余数，此时m为FATEntry所在的相对扇区，n为在此扇区内的偏移量（字节）。因为FAT1表前面还有1个引导扇区，所以FATEntry所在的实际扇区号为m+1。然后读取m+1和m+2两个扇区，然后在偏移n个字节处，取出FATEntry，相当于读取两个字节。此时再利用z，如果z为0的话，此FAT项为前一个字节和后一个字节的后4位，如果z为1的话，此FATEntry取前一个字节的前4位和后一个字节。
GetFATEntry:
	push	es
	push	bx
    ; 函数中使用到了es和bx所以要进行保存，保存在栈上,es:bx会被函数ReadSector所使用
	push	ax
	mov	ax, BaseOfKernelFile	; ┓
	sub	ax, 0100h		; ┣ 在 BaseOfKernelFile 后面留出 4K 空间用于存放 FAT, 因为这是个段基址，0100h还要乘上个16正好是4K空间
	mov	es, ax			; ┛
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx			; dx:ax = ax * 3
	mov	bx, 2
	div	bx			; dx:ax / 2  ==>  ax <- 商, dx <- 余数
                    ; 簇号为奇数时：簇号”*1.5的结果会包含0.5，即偏移的结果中包含半个字节
                    ; 簇号为偶数时：簇号”*1.5的结果为整数，即偏移的结果整好为整数个字节
                    
	cmp	dx, 0
	jz	LABEL_EVEN
	mov	byte [bOdd], 1
LABEL_EVEN:;偶数
	xor	dx, dx			; 现在 ax 中是 FATEntry 在 FAT 中的偏移量. 下面来计算 FATEntry 在哪个扇区中(FAT占用不止一个扇区)
	mov	bx, [BPB_BytsPerSec]
	div	bx			; dx:ax / BPB_BytsPerSec  ==>	ax <- 商   (FATEntry 所在的扇区相对于 FAT 来说的扇区号)
					;				dx <- 余数 (FATEntry 在扇区内的偏移)。
	push	dx
	mov	bx, 0			; bx <- 0	于是, es:bx = (BaseOfKernelFile - 100):00 = (BaseOfKernelFile - 100) * 10h　
                        ; kernel文件内容位置
	add	ax, SectorNoOfFAT1	; 此句执行之后的 ax 就是 FATEntry 所在的扇区号,前面还有一个引导扇区，所以要+1
	mov	cl, 2
	call	ReadSector		; 读取 FATEntry 所在的扇区, 一次读两个, 避免在边界发生错误, 因为一个 FATEntry 可能跨越两个扇区
	pop	dx                  ; dx <- 余数 (FATEntry 在扇区内的偏移)。
	add	bx, dx              ; 在add之前，bx为目标空间的首地址，其中内容是包含FATEntry的扇区。bx+dx就定位到了该FATEntry
	mov	ax, [es:bx]         ; ax为FATEntry
	cmp	byte [bOdd], 1  ;是奇数的簇号还是偶数的簇号
	jnz	LABEL_EVEN_2
	shr	ax, 4           ;　需要高12位,ax为16位，直接右移4位就能得到FAT项值
LABEL_EVEN_2:
	and	ax, 0FFFh       ;  需要低12位

LABEL_GET_FAT_ENRY_OK:

	pop	bx
	pop	es
	ret
;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
; 函数名: KillMotor
;----------------------------------------------------------------------------
; 作用:
;	关闭软驱马达
KillMotor:
	push	dx
	mov	dx, 03F2h
	mov	al, 0
	out	dx, al
	pop	dx
	ret
;----------------------------------------------------------------------------

