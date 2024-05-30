pub const start =
    \\.bss
    \\    mem: .zero 512
    \\    termios: .zero 60 /* termios struct */
    \\
    \\.text
    \\.globl _start
    \\
    \\EIOCTL_msg: .ascii "Failed to disable/enable canonical mode.\n", /* 41 */
    \\EWRITE_msg: .ascii "Failed to write character.\n" /* 27 */
    \\
    \\EIOCTL:
    \\   movq $1, %rax
    \\   movq $1, %rdi
    \\   leaq EIOCTL_msg(%rip), %rsi
    \\   movq $41, %rdx
    \\   syscall
    \\   movq $16, %rdi
    \\   jmp exit
    \\
    \\EWRITE:
    \\   movq $1, %rax
    \\   movq $1, %rdi
    \\   leaq EWRITE_msg(%rip), %rsi
    \\   movq $27, %rdx
    \\   syscall
    \\   movq $1, %rdi
    \\   jmp exit
    \\
    \\exit:
    \\   mov $60, %rax
    \\   syscall
    \\
    \\_start:
    \\    movq $0, %r10
    \\    /* Disable canonical mode */
    \\    movq $16, %rax            /* ioctl unsigned int fd	unsigned int cmd	unsigned long arg */
    \\    movq $1, %rdi             /* stdout */
    \\    movq $0x5401, %rsi        /* TCGETS */
    \\    leaq termios(%rip), %rdx
    \\    syscall
    \\    cmpq $0, %rax
    \\    jl EIOCTL
    \\
    \\    andl $~0x00000002, termios + 12 /* ICANON */
    \\    movq $16, %rax
    \\    mov $1, %rdi
    \\    mov $0x5402, %rsi
    \\    leaq termios(%rip), %rdx
    \\    syscall
    \\    cmpq $0, %rax
    \\    jl EIOCTL
    \\
;

pub const end =
    \\    /* Enable canonical mode */
    \\    movq $16, %rax            /* ioctl unsigned int fd	unsigned int cmd	unsigned long arg */
    \\    movq $1, %rdi             /* stdout */
    \\    movq $0x5401, %rsi        /* TCGETS */
    \\    leaq termios(%rip), %rdx
    \\    syscall
    \\    cmpq $0, %rax
    \\    jl EIOCTL
    \\
    \\    orl $0x00000002, termios + 12 /* ICANON */
    \\    movq $16, %rax
    \\    movq $1, %rdi
    \\    movq $0x5402, %rsi
    \\    leaq termios(%rip), %rdx
    \\    syscall
    \\    cmpq $0, %rax
    \\    jl EIOCTL
    \\
    \\    movq $0, %rdi
    \\    jmp exit
    \\
;

pub const plus =
    \\    addb $1, mem(%r10)
    \\
;

pub const minus =
    \\    subb $1, mem(%r10)
    \\
;

pub const move_right =
    \\    addq $1, %r10
    \\    andq $0xFF, %r10
    \\
;

pub const move_left =
    \\    subq $1, %r10
    \\    andq $0xFF, %r10
    \\
;

pub const output_cell =
    \\    movq $1, %rax
    \\    movq $1, %rdi
    \\    leaq mem(%rip), %rsi
    \\    addq %r10, %rsi
    \\    movq $1, %rdx
    \\    syscall
    \\    cmpq $0, %rax
    \\    jl EWRITE
    \\
;

pub const input_cell =
    \\    movq $0, %rax
    \\    movq $1, %rdi
    \\    leaq mem(%rip), %rsi
    \\    addq %r10, %rsi
    \\    movq $1, %rdx
    \\    syscall
    \\
;

pub const start_loop =
    \\    cmpb $0, mem(%r10)
    \\    je loop_end{d}
    \\    loop_start{0d}:
    \\
;

pub const end_loop =
    \\    cmpb $0, mem(%r10)
    \\    jne loop_start{d}
    \\    loop_end{0d}:
    \\
;
