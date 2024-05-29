pub const start =
    \\section .data
    \\    EIOCTL_msg: db "Failed to disable/enable canonical mode.", 10 ; 41
    \\    EWRITE_msg: db "Failed to write character.", 10 ; 27
    \\
    \\section .bss
    \\    mem: resb 512
    \\    termios: resb 60 ; termios struct
    \\
    \\section .text
    \\global _start
    \\
    \\%define ICANON 0x00000002
    \\
    \\EIOCTL:
    \\   mov rax, 1
    \\   mov rdi, 1
    \\   mov rsi, EIOCTL_msg
    \\   mov rdx, 41
    \\   syscall
    \\   mov rdi, 16
    \\   jmp exit
    \\
    \\EWRITE:
    \\   mov rax, 1
    \\   mov rdi, 1
    \\   mov rsi, EWRITE_msg
    \\   mov rdx, 27
    \\   syscall
    \\   mov rdi, 1
    \\   jmp exit
    \\
    \\exit:
    \\   mov rax, 60
    \\   syscall
    \\
    \\_start:
    \\    mov r10, 0
    \\    ; Disable canonical mode
    \\    mov rax, 16            ; ioctl unsigned int fd	unsigned int cmd	unsigned long arg
    \\    mov rdi, 1             ; stdout
    \\    mov rsi, 0x5401        ; TCGETS
    \\    mov rdx, termios
    \\    syscall
    \\    cmp rax, 0
    \\    jl EIOCTL
    \\
    \\    and dword [termios + 12], ~ICANON
    \\    mov rax, 16
    \\    mov rdi, 1
    \\    mov rsi, 0x5402
    \\    mov rdx, termios
    \\    syscall
    \\    cmp rax, 0
    \\    jl EIOCTL
    \\
;

pub const end =
    \\    ; Enable canonical mode
    \\    mov rax, 16            ; ioctl unsigned int fd	unsigned int cmd	unsigned long arg
    \\    mov rdi, 1             ; stdout
    \\    mov rsi, 0x5401        ; TCGETS
    \\    mov rdx, termios
    \\    syscall
    \\    cmp rax, 0
    \\    jl EIOCTL
    \\
    \\    or dword [termios + 12], ICANON
    \\    mov rax, 16
    \\    mov rdi, 1
    \\    mov rsi, 0x5402
    \\    mov rdx, termios
    \\    syscall
    \\    cmp rax, 0
    \\    jl EIOCTL
    \\
    \\    mov rdi,0
    \\    jmp exit
;

pub const plus =
    \\    add byte [mem + r10], 1
    \\
;

pub const minus =
    \\    sub byte [mem + r10], 1
    \\
;

pub const move_right =
    \\    add r10, 1
    \\    and r10, 0xFF
    \\
;

pub const move_left =
    \\    sub r10, 1
    \\    and r10, 0xFF
    \\
;

pub const output_cell =
    \\    mov rax, 1
    \\    mov rdi, 1
    \\    mov rsi, mem
    \\    add rsi, r10
    \\    mov rdx, 1
    \\    syscall
    \\    cmp rax, 0
    \\    jl EWRITE
    \\
;

pub const input_cell =
    \\    mov rax, 0
    \\    mov rdi, 1
    \\    mov rsi, mem
    \\    add rsi, r10
    \\    mov rdx, 1
    \\    syscall
    \\
;

pub const start_loop =
    \\    cmp byte [mem + r10], 0
    \\    je loop_end{d}
    \\    loop_start{0d}:
    \\
;

pub const end_loop =
    \\    cmp byte [mem + r10], 0
    \\    jne loop_start{d}
    \\    loop_end{0d}:
    \\
;
