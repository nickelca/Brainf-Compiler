pub const start =
    \\section .bss
    \\    mem: resb 512
    \\    termios: resb 60 ; termios struct
    \\
    \\section .text
    \\global _start
    \\
    \\EIOCTL_msg: db "Failed to disable/enable canonical mode.", 10 ; 41
    \\EWRITE_msg: db "Failed to write character.", 10 ; 27
    \\
    \\%define ICANON 0x00000002
    \\
    \\EIOCTL:
    \\   mov eax, 4
    \\   mov ebx, 1
    \\   mov ecx, EIOCTL_msg
    \\   mov edx, 41
    \\   syscall
    \\   mov ebx, 16
    \\   jmp exit
    \\
    \\EWRITE:
    \\   mov eax, 4
    \\   mov ebx, 1
    \\   mov ecx, EWRITE_msg
    \\   mov edx, 27
    \\   syscall
    \\   mov ebx, 4
    \\   jmp exit
    \\
    \\exit:
    \\   mov eax, 1
    \\   syscall
    \\
    \\_start:
    \\    mov ebp, 0
    \\    ; Disable canonical mode
    \\    mov eax, 54            ; ioctl unsigned int fd	unsigned int cmd	unsigned long arg
    \\    mov ebx, 1             ; stdout
    \\    mov ecx, 0x5401        ; TCGETS
    \\    mov edx, termios
    \\    syscall
    \\    cmp eax, 0
    \\    jl EIOCTL
    \\
    \\    and dword [termios + 12], ~ICANON
    \\    mov eax, 54
    \\    mov ebx, 1
    \\    mov ecx, 0x5402
    \\    mov edx, termios
    \\    syscall
    \\    cmp eax, 0
    \\    jl EIOCTL
    \\
;

pub const end =
    \\    ; Enable canonical mode
    \\    mov eax, 54            ; ioctl unsigned int fd	unsigned int cmd	unsigned long arg
    \\    mov ebx, 1             ; stdout
    \\    mov ecx, 0x5401        ; TCGETS
    \\    mov edx, termios
    \\    syscall
    \\    cmp eax, 0
    \\    jl EIOCTL
    \\
    \\    or dword [termios + 12], ICANON
    \\    mov eax, 54
    \\    mov ebx, 1
    \\    mov ecx, 0x5402
    \\    mov edx, termios
    \\    syscall
    \\    cmp eax, 0
    \\    jl EIOCTL
    \\
    \\    mov ebx,0
    \\    jmp exit
;

pub const plus =
    \\    add byte [mem + ebp], 1
    \\
;

pub const minus =
    \\    sub byte [mem + ebp], 1
    \\
;

pub const move_right =
    \\    add ebp, 1
    \\    and ebp, 0xFF
    \\
;

pub const move_left =
    \\    sub ebp, 1
    \\    and ebp, 0xFF
    \\
;

pub const output_cell =
    \\    mov eax, 4
    \\    mov ebx, 1
    \\    mov ecx, mem
    \\    add ecx, ebp
    \\    mov edx, 1
    \\    syscall
    \\    cmp eax, 0
    \\    jl EWRITE
    \\
;

pub const input_cell =
    \\    mov eax, 3
    \\    mov ebx, 1
    \\    mov ecx, mem
    \\    add ecx, ebp
    \\    mov edx, 1
    \\    syscall
    \\
;

pub const start_loop =
    \\    cmp byte [mem + ebp], 0
    \\    je loop_end{d}
    \\    loop_start{0d}:
    \\
;

pub const end_loop =
    \\    cmp byte [mem + ebp], 0
    \\    jne loop_start{d}
    \\    loop_end{0d}:
    \\
;
