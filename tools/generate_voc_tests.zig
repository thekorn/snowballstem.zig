const std = @import("std");

const usage =
    \\Usage: ./generate_voc_tests [options]
    \\
    \\Options:
    \\  --voc-file voc file - test corpus
    \\  --voc-output-file voc output file - expected test results
    \\  --output-file generated zig code output file
    \\
;

const LineIter = struct {
    reader: std.fs.File.Reader,
    alloc: std.mem.Allocator,

    pub fn next(self: *LineIter) ?[]const u8 {
        const line = self.reader.readUntilDelimiterOrEofAlloc(self.alloc, '\n', std.math.maxInt(usize)) catch |err| {
            std.log.err("Failed to read line: {s}", .{@errorName(err)});
            return null;
        };
        return line;
    }
};

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try std.process.argsAlloc(arena);

    var opt_input_file_path: ?[]const u8 = null;
    var opt_voc_output_file_path: ?[]const u8 = null;
    var opt_output_file_path: ?[]const u8 = null;

    {
        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            const arg = args[i];
            if (std.mem.eql(u8, "-h", arg) or std.mem.eql(u8, "--help", arg)) {
                try std.io.getStdOut().writeAll(usage);
                return std.process.cleanExit();
            } else if (std.mem.eql(u8, "--voc-file", arg)) {
                i += 1;
                if (i > args.len) fatal("expected arg after '{s}'", .{arg});
                if (opt_input_file_path != null) fatal("duplicated {s} argument", .{arg});
                opt_input_file_path = args[i];
            } else if (std.mem.eql(u8, "--voc-output-file", arg)) {
                i += 1;
                if (i > args.len) fatal("expected arg after '{s}'", .{arg});
                if (opt_voc_output_file_path != null) fatal("duplicated {s} argument", .{arg});
                opt_voc_output_file_path = args[i];
            } else if (std.mem.eql(u8, "--output-file", arg)) {
                i += 1;
                if (i > args.len) fatal("expected arg after '{s}'", .{arg});
                if (opt_output_file_path != null) fatal("duplicated {s} argument", .{arg});
                opt_output_file_path = args[i];
            } else {
                fatal("unrecognized arg: '{s}'", .{arg});
            }
        }
    }

    const voc_file_path = opt_input_file_path orelse fatal("missing --voc-file", .{});
    const voc_output_file_path = opt_voc_output_file_path orelse fatal("missing --voc-output-file", .{});
    const output_file_path = opt_output_file_path orelse fatal("missing --voc-output-file", .{});

    var output_file = std.fs.cwd().createFile(output_file_path, .{}) catch |err| {
        fatal("unable to open '{s}': {s}", .{ output_file_path, @errorName(err) });
    };
    defer output_file.close();

    var voc_file = std.fs.cwd().openFile(voc_file_path, .{}) catch |err| {
        fatal("unable to open '{s}': {s}", .{ voc_file_path, @errorName(err) });
    };
    defer voc_file.close();

    var voc_output_file = std.fs.cwd().openFile(voc_output_file_path, .{}) catch |err| {
        fatal("unable to open '{s}': {s}", .{ voc_output_file_path, @errorName(err) });
    };
    defer voc_output_file.close();

    var voc_entries = std.ArrayList([]const u8).init(arena);
    defer voc_entries.deinit();

    var output_entries = std.ArrayList([]const u8).init(arena);
    defer output_entries.deinit();

    var voc_file_iter = LineIter{ .reader = voc_file.reader(), .alloc = arena };
    var output_file_iter = LineIter{ .reader = voc_output_file.reader(), .alloc = arena };

    try output_file.writeAll(
        \\const std = @import("std");
        \\const Stemmer = @import("../Stemmer.zig");
        \\
    );

    while (true) {
        const voc_item = voc_file_iter.next() orelse break;
        const output_item = output_file_iter.next() orelse break;

        const test_case = try std.fmt.allocPrint(arena,
            \\
            \\test "test german '{s}'" {{
            \\    var s = try Stemmer.init("german", "UTF_8");
            \\    defer s.deinit();
            \\
            \\    try std.testing.expectEqualStrings("{s}", s.stem("{s}"));
            \\}}
            \\
        , .{ voc_item, output_item, voc_item });

        try output_file.writeAll(test_case);
    }

    return std.process.cleanExit();
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format, args);
    std.process.exit(1);
}
