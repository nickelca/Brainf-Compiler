pub const start =
    \\.bss
    \\    .align 3
    \\    mem: .skip 512
    \\    termios: .skip 60 // termios struct
    \\
    \\.text
    \\.global _start
    \\
    \\EIOCTL_msg: .ascii "Failed to disable/enable canonical mode.\n", // 41
    \\EWRITE_msg: .ascii "Failed to write character.\n" // 27
    \\
    \\EIOCTL:
    \\   mov x8, #64
    \\   mov x0, #1
    \\   ldr x1, =EIOCTL_msg
    \\   mov x2, 41
    \\   svc #0
    \\   mov x0, #29
    \\   b exit
    \\
    \\EWRITE:
    \\   mov x8, #64
    \\   mov x0, #1
    \\   ldr x1, =EWRITE_msg
    \\   mov x2, #27
    \\   svc #0
    \\   mov x0, #64
    \\   b exit
    \\
    \\exit:
    \\   mov x8, #93
    \\   svc #0
    \\
    \\_start:
    \\    mov x10, #0
    \\    // Disable canonical mode
    \\    mov x8, #29             // ioctl unsigned int fd	unsigned int cmd	unsigned long arg
    \\    mov x0, #1              // stdout
    \\    ldr x1, =0x5401         // TCGETS
    \\    ldr x2, =termios
    \\    svc #0
    \\    cmp x0, #0
    \\    b.lt EIOCTL
    \\
    \\    ldr x2, =termios
    \\    ldr x3, [x2, #12]
    \\    ldr w4, =0x00000002
    \\    bic x3, x3, x4
    \\    str x3, [x2, #12]
    \\
    \\    mov x8, #29
    \\    mov x0, #1
    \\    ldr x1, =0x5402
    \\    ldr x2, =termios
    \\    svc #0
    \\    cmp x0, #0
    \\    b.lt EIOCTL
    \\
;

pub const end =
    \\    // Enable canonical mode
    \\    mov x8, #29             // ioctl unsigned int fd	unsigned int cmd	unsigned long arg
    \\    mov x0, #1              // stdout
    \\    ldr x1, =0x5401         // TCGETS
    \\    ldr x2, =termios
    \\    svc #0
    \\    cmp x0, #0
    \\    b.lt EIOCTL
    \\
    \\    ldr x2, =termios
    \\    ldr x3, [x2, #12]
    \\    ldr w4, =0x00000002
    \\    orr x3, x3, x4
    \\    str x3, [x2, #12]
    \\
    \\    mov x8, #29
    \\    mov x0, #1
    \\    ldr x1, =0x5402
    \\    ldr x2, =termios
    \\    svc #0
    \\    cmp x0, #0
    \\    b.lt EIOCTL
    \\
    \\    mov x0, #0
    \\    b exit
    \\
;

pub const plus =
    \\    ldr x0, =mem
    \\    add x0, x0, x10
    \\    ldrb w1, [x0]
    \\    add w1, w1, #1
    \\    strb w1, [x0]
    \\
;

pub const minus =
    \\    ldr x0, =mem
    \\    add x0, x0, x10
    \\    ldrb w1, [x0]
    \\    sub w1, w1, #1
    \\    strb w1, [x0]
    \\
;

pub const move_right =
    \\    add x10, x10, #1
    \\    and x10, x10, #0xFF
    \\
;

pub const move_left =
    \\    sub x10, x10, #1
    \\    and x10, x10, #0xFF
    \\
;

pub const output_cell =
    \\    mov x8, #64
    \\    mov x0, #1
    \\    ldr x1, =mem
    \\    add x1, x1, x10
    \\    mov x2, #1
    \\    svc #0
    \\    cmp x0, #0
    \\    b.lt EWRITE
    \\
;

pub const input_cell =
    \\    mov x8, #63
    \\    mov x0, #1
    \\    ldr x1, =mem
    \\    add x1, x1, x10
    \\    mov x2, #1
    \\    svc #0
    \\
;

pub const start_loop =
    \\    ldr x0, =mem
    \\    add x0, x0, x10
    \\    ldrb w1, [x0]
    \\    cmp w1, #0
    \\    b.eq loop_end{d}
    \\    loop_start{0d}:
    \\
;

pub const end_loop =
    \\    ldr x0, =mem
    \\    add x0, x0, x10
    \\    ldrb w1, [x0]
    \\    cmp w1, #0
    \\    b.ne loop_start{d}
    \\    loop_end{0d}:
    \\
;
