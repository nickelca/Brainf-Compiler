const Target = enum {
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

    const target: Target = .nasm;

    try out.writeAll(start(target));

    blk: while (true) {
        const byte = brainf.reader().readByte() catch |e| switch (e) {
            error.EndOfStream => break :blk,
            else => return e,
        };
        if (std.mem.containsAtLeast(u8, &std.ascii.whitespace, 1, &.{byte})) {
            continue :blk;
        }

        try out.writeAll(switch (byte) {
            '+' => plus(target),
            '-' => minus(target),
            '>' => moveRight(target),
            '<' => moveLeft(target),
            '.' => outputCell(target),
            ',' => readCell(target),
            else => return stderr.writeAll("Invalid character\n"),
        });
    }

    try out.writeAll(end(target));
}

fn start(target: Target) []const u8 {
    return switch (target) {
        .nasm =>
        \\section .bss
        \\    mem: resb 512
        \\    termios: resb 60 ; termios struct
        \\
        \\section .text
        \\global _start
        \\
        \\_start:
        \\    mov r10, 0
        \\    ; Disable canonical mode
        \\    mov rax, 16            ; ioctl unsigned int fd	unsigned int cmd	unsigned long arg
        \\    mov rdi, 1             ; stdout
        \\    mov rsi, 0x5401        ; TCGETS
        \\    mov rdx, termios
        \\    syscall
        \\    and dword [termios + 12], ~0x00000002
        \\    ; ignore any error for now
        \\    mov rax, 16
        \\    mov rdi, 1
        \\    mov rsi, 0x5402
        \\    mov rdx, termios
        \\    syscall
        \\
    };
}

fn end(target: Target) []const u8 {
    return switch (target) {
        .nasm =>
        \\    ; Enable canonical mode
        \\    mov rax, 16            ; ioctl unsigned int fd	unsigned int cmd	unsigned long arg
        \\    mov rdi, 1             ; stdout
        \\    mov rsi, 0x5401        ; TCGETS
        \\    mov rdx, termios
        \\    syscall
        \\    or dword [termios + 12], 0x00000002
        \\    ; ignore any error for now
        \\    mov rax, 16
        \\    mov rdi, 1
        \\    mov rsi, 0x5402
        \\    mov rdx, termios
        \\    syscall
        \\
        \\    mov rax,60
        \\    mov rdi,0
        \\    syscall
    };
}

fn plus(target: Target) []const u8 {
    return switch (target) {
        .nasm =>
        \\    add byte [mem + r10], 1
        \\
    };
}

fn minus(target: Target) []const u8 {
    return switch (target) {
        .nasm =>
        \\    sub byte [mem + r10], 1
        \\
    };
}

fn moveRight(target: Target) []const u8 {
    return switch (target) {
        .nasm =>
        \\    add r10, 1
        \\    and r10, 0xFF
        \\
    };
}

fn moveLeft(target: Target) []const u8 {
    return switch (target) {
        .nasm =>
        \\    sub r10, 1
        \\    and r10, 0xFF
        \\
    };
}

fn outputCell(target: Target) []const u8 {
    return switch (target) {
        .nasm =>
        \\    mov rax, 1
        \\    mov rdi, 1
        \\    mov rsi, mem
        \\    add rsi, r10
        \\    mov rdx, 1
        \\    syscall
        \\
    };
}

fn readCell(target: Target) []const u8 {
    return switch (target) {
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
