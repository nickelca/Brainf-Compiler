//! TODO
//!     - Support more than just x86_64-linux NASM
//!     - Support loops
//!     - Ensure values wrap properly in 0-256 range. No sneaky overflow
//!     - Consider proper course of action upon outputCell failure
//!         - Currently failing and exiting right away
//!     - Add command line flags for target, output file
//!     - Buffer reader and writer

const OutputFormat = union(enum) {
    @"x86_64-linux-nasm": @import("x86_64-linux/nasm.zig"),

    fn start(ofmt: OutputFormat) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).start,
        };
    }

    fn end(ofmt: OutputFormat) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).end,
        };
    }

    fn plus(ofmt: OutputFormat) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).plus,
        };
    }

    fn minus(ofmt: OutputFormat) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).minus,
        };
    }

    fn moveRight(ofmt: OutputFormat) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).move_right,
        };
    }

    fn moveLeft(ofmt: OutputFormat) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).move_left,
        };
    }

    fn outputCell(ofmt: OutputFormat) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).output_cell,
        };
    }

    fn inputCell(ofmt: OutputFormat) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).input_cell,
        };
    }
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

    const ofmt: OutputFormat = .{ .@"x86_64-linux-nasm" = .{} };

    try out.writeAll(ofmt.start());

    blk: while (true) {
        const byte = brainf.reader().readByte() catch |e| switch (e) {
            error.EndOfStream => break :blk,
            else => return e,
        };

        try out.writeAll(switch (byte) {
            '+' => ofmt.plus(),
            '-' => ofmt.minus(),
            '>' => ofmt.moveRight(),
            '<' => ofmt.moveLeft(),
            '.' => ofmt.outputCell(),
            ',' => ofmt.inputCell(),
            else => continue :blk,
        });
    }

    try out.writeAll(ofmt.end());
}

fn usage(writer: anytype) !void {
    try writer.writeAll(
        \\brainf-compile file.bf
        \\    Compile file.bf into assembly
    );
}

const std = @import("std");
