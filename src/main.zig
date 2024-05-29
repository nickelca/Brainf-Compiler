//! TODO
//!     - Support more than just x86_64-linux NASM
//!     - Ensure values wrap properly in 0-256 range. No sneaky overflow
//!     - Consider proper course of action upon outputCell failure
//!         - Currently print error and exiting right away
//!     - Add command line flags for target, output file

const OutputFormat = union(enum) {
    const Self = @This();
    @"x86_64-linux-nasm": @import("x86_64-linux/nasm.zig"),

    fn start(ofmt: Self) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).start,
        };
    }

    fn end(ofmt: Self) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).end,
        };
    }

    fn plus(ofmt: Self) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).plus,
        };
    }

    fn minus(ofmt: Self) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).minus,
        };
    }

    fn moveRight(ofmt: Self) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).move_right,
        };
    }

    fn moveLeft(ofmt: Self) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).move_left,
        };
    }

    fn outputCell(ofmt: Self) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).output_cell,
        };
    }

    fn inputCell(ofmt: Self) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).input_cell,
        };
    }

    fn startLoop(ofmt: Self) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).start_loop,
        };
    }

    fn endLoop(ofmt: Self) []const u8 {
        return switch (ofmt) {
            inline else => |o| @TypeOf(o).end_loop,
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

    const brainf_file = try std.fs.cwd().openFile(args[1], .{});
    defer brainf_file.close();
    var brainf_buffered = std.io.bufferedReader(brainf_file.reader());
    const brainf = brainf_buffered.reader();

    const out_file = try std.fs.cwd().createFile("out.s", .{});
    defer out_file.close();
    var out_buffered = std.io.bufferedWriter(out_file.writer());
    const out = out_buffered.writer();

    const ofmt: OutputFormat = .{ .@"x86_64-linux-nasm" = .{} };

    try out.writeAll(ofmt.start());

    var loop_stack = std.ArrayList(usize).init(alloc);
    defer loop_stack.deinit();

    var read_position: usize = 0;
    blk: while (true) : (read_position += 1) {
        const byte = brainf.readByte() catch |e| switch (e) {
            error.EndOfStream => break :blk,
            else => return e,
        };

        switch (byte) {
            '+' => try out.writeAll(ofmt.plus()),
            '-' => try out.writeAll(ofmt.minus()),
            '>' => try out.writeAll(ofmt.moveRight()),
            '<' => try out.writeAll(ofmt.moveLeft()),
            '.' => try out.writeAll(ofmt.outputCell()),
            ',' => try out.writeAll(ofmt.inputCell()),
            '[' => {
                try out.print(ofmt.startLoop(), .{read_position});
                try loop_stack.append(read_position);
            },
            ']' => {
                const back_to = loop_stack.popOrNull() orelse {
                    return stderr.print(
                        "Unmatched loop close at character {d}.\n",
                        .{read_position},
                    );
                };
                try out.print(ofmt.endLoop(), .{back_to});
            },
            else => continue :blk,
        }
    }

    try out.writeAll(ofmt.end());
    try out_buffered.flush();
}

fn usage(writer: anytype) !void {
    try writer.writeAll(
        \\brainf-compile file.bf
        \\    Compile file.bf into assembly
    );
}

const std = @import("std");
