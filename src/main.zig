const Target = enum {
    @"x86_64-linux",
};

const OutputFormat = enum {
    nasm,
};

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    var sfb = std.heap.stackFallback(64 * 64, gpa.allocator());
    const alloc = sfb.get();

    const stderr = std.io.getStdErr().writer();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len != 2) {
        return usage(stderr);
    }

    const brainf = try std.fs.cwd().openFile(args[1], .{});
    defer brainf.close();
    const out = try std.fs.cwd().createFile("out.s", .{});
    defer out.close();

    const ofmt: OutputFormat = .nasm;

    try out.writeAll(start(ofmt));

    blk: while (true) {
        const byte = brainf.reader().readByte() catch |e| switch (e) {
            error.EndOfStream => break :blk,
            else => return e,
        };

        try out.writeAll(switch (byte) {
            '+' => plus(ofmt),
            '-' => minus(ofmt),
            '>' => moveRight(ofmt),
            '<' => moveLeft(ofmt),
            '.' => outputCell(ofmt),
            ',' => readCell(ofmt),
            else => continue :blk,
        });
    }

    try out.writeAll(end(ofmt));
}

fn start(ofmt: OutputFormat) []const u8 {
    return switch (ofmt) {
        .nasm =>
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
    };
}

fn end(ofmt: OutputFormat) []const u8 {
    return switch (ofmt) {
        .nasm =>
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
    };
}

fn plus(ofmt: OutputFormat) []const u8 {
    return switch (ofmt) {
        .nasm =>
        \\    add byte [mem + r10], 1
        \\
    };
}

fn minus(ofmt: OutputFormat) []const u8 {
    return switch (ofmt) {
        .nasm =>
        \\    sub byte [mem + r10], 1
        \\
    };
}

fn moveRight(ofmt: OutputFormat) []const u8 {
    return switch (ofmt) {
        .nasm =>
        \\    add r10, 1
        \\    and r10, 0xFF
        \\
    };
}

fn moveLeft(ofmt: OutputFormat) []const u8 {
    return switch (ofmt) {
        .nasm =>
        \\    sub r10, 1
        \\    and r10, 0xFF
        \\
    };
}

fn outputCell(ofmt: OutputFormat) []const u8 {
    return switch (ofmt) {
        .nasm =>
        \\    mov rax, 1
        \\    mov rdi, 1
        \\    mov rsi, mem
        \\    add rsi, r10
        \\    mov rdx, 1
        \\    syscall
        \\    cmp rax, 0
        \\    jl EWRITE
        \\
    };
}

fn readCell(ofmt: OutputFormat) []const u8 {
    return switch (ofmt) {
        .nasm =>
        \\    mov rax, 0
        \\    mov rdi, 1
        \\    mov rsi, mem
        \\    add rsi, r10
        \\    mov rdx, 1
        \\    syscall
        \\
    };
}

fn usage(writer: anytype) !void {
    try writer.writeAll(
        \\brainf-compile file.bf
        \\    Compile file.bf into assembly
    );
}

const std = @import("std");
