//! TODO
//!     - Support more than just x86_64-linux NASM
//!     - Ensure values wrap properly in 0-256 range. No sneaky overflow
//!     - Consider proper course of action upon outputCell failure
//!         - Currently print error and exiting right away
//!     - Add command line flags for target, output file
//!         - Zig clap?

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

    if (!std.mem.endsWith(u8, args[1], ".bf") and
        !std.mem.endsWith(u8, args[1], ".b"))
    {
        try stderr.writeAll("Input file must be .bf or .b\n");
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
        const byte = brainf.readByte() catch |err| switch (err) {
            error.EndOfStream => break :blk,
            else => return err,
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

    const loop_stack_s = try loop_stack.toOwnedSlice();
    defer alloc.free(loop_stack_s);
    if (loop_stack_s.len > 0) {
        for (loop_stack_s) |pos| {
            try stderr.print(
                "Unmatched loop start at character {d}.\n",
                .{pos},
            );
        }
        return;
    }

    try out.writeAll(ofmt.end());
    try out_buffered.flush();
}

fn usage(writer: anytype) !void {
    try writer.writeAll(
        \\brainf-compile infile.{bf|b}
        \\    Compile infile.{bf|b} into out.s containing NASM assembly
        \\
    );

    // idealized usage
    _ =
        \\brainf-compile [-target=target] [-ofmt=output-format]
        \\               [-o outfile] [-Olevel] infile.{bf|b}
        \\  target
        \\    x86_64
        \\    aarch64
        \\    arm64
        \\
        \\  output-format
        \\    nasm
        \\    gnu-as
        \\
        \\  optimization
        \\    -O0        no optimization at all
        \\    -O1        compact consecutive + - > <
        \\    -O2        -O1 + do everything possible at compile time
        \\
    ;
}

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

const std = @import("std");
