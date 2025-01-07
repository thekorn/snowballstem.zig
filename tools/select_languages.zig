const std = @import("std");

const usage =
    \\Usage: ./select_languages [options]
    \\
    \\Options:
    \\  --langs comma seperated string of languages
    \\  --output-file generated zig code output file
    \\
;

// reference: https://github.com/snowballstem/snowball/blob/master/libstemmer/modules.txt
const languages = [_][]const u8{
    "arabic          UTF_8                   arabic,ar,ara",
    "armenian        UTF_8                   armenian,hy,hye,arm",
    "basque          UTF_8,ISO_8859_1        basque,eu,eus,baq",
    "catalan         UTF_8,ISO_8859_1        catalan,ca,cat",
    "danish          UTF_8,ISO_8859_1        danish,da,dan",
    "dutch           UTF_8,ISO_8859_1        dutch,nl,dut,nld",
    "english         UTF_8,ISO_8859_1        english,en,eng",
    "estonian        UTF_8                   estonian,et,est",
    "finnish         UTF_8,ISO_8859_1        finnish,fi,fin",
    "french          UTF_8,ISO_8859_1        french,fr,fre,fra",
    "german          UTF_8,ISO_8859_1        german,de,ger,deu",
    "greek           UTF_8                   greek,el,gre,ell",
    "hindi           UTF_8                   hindi,hi,hin",
    "hungarian       UTF_8,ISO_8859_2        hungarian,hu,hun",
    "indonesian      UTF_8,ISO_8859_1        indonesian,id,ind",
    "irish           UTF_8,ISO_8859_1        irish,ga,gle",
    "italian         UTF_8,ISO_8859_1        italian,it,ita",
    "lithuanian      UTF_8                   lithuanian,lt,lit",
    "nepali          UTF_8                   nepali,ne,nep",
    "norwegian       UTF_8,ISO_8859_1        norwegian,no,nor",
    "portuguese      UTF_8,ISO_8859_1        portuguese,pt,por",
    "romanian        UTF_8                   romanian,ro,rum,ron",
    "russian         UTF_8,KOI8_R            russian,ru,rus",
    "serbian         UTF_8                   serbian,sr,srp",
    "spanish         UTF_8,ISO_8859_1        spanish,es,esl,spa",
    "swedish         UTF_8,ISO_8859_1        swedish,sv,swe",
    "tamil           UTF_8                   tamil,ta,tam",
    "turkish         UTF_8                   turkish,tr,tur",
    "yiddish         UTF_8                   yiddish,yi,yi",
};

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try std.process.argsAlloc(arena);

    var opt_output_file_path: ?[]const u8 = null;
    var opt_langs: ?[]const u8 = null;

    {
        var i: usize = 1;
        while (i < args.len) : (i += 1) {
            const arg = args[i];
            if (std.mem.eql(u8, "-h", arg) or std.mem.eql(u8, "--help", arg)) {
                try std.io.getStdOut().writeAll(usage);
                return std.process.cleanExit();
            } else if (std.mem.eql(u8, "--output-file", arg)) {
                i += 1;
                if (i > args.len) fatal("expected arg after '{s}'", .{arg});
                if (opt_output_file_path != null) fatal("duplicated {s} argument", .{arg});
                opt_output_file_path = args[i];
            } else if (std.mem.eql(u8, "--langs", arg)) {
                i += 1;
                if (i > args.len) fatal("expected arg after '{s}'", .{arg});
                if (opt_langs != null) fatal("duplicated {s} argument", .{arg});
                opt_langs = args[i];
            } else {
                fatal("unrecognized arg: '{s}'", .{arg});
            }
        }
    }

    const output_file_path = opt_output_file_path orelse fatal("missing --output-file", .{});
    const langs: ?[]const u8 = opt_langs orelse null;

    var output_file = std.fs.cwd().createFile(output_file_path, .{}) catch |err| {
        fatal("unable to open '{s}': {s}", .{ output_file_path, @errorName(err) });
    };
    defer output_file.close();

    if (langs == null) {
        for (languages) |l| {
            const ln = try std.fmt.allocPrint(arena, "{s}\n", .{l});
            try output_file.writeAll(ln);
        }
    } else {
        var langsIter = std.mem.tokenizeSequence(u8, langs.?, ",");

        while (langsIter.next()) |lang| {
            var found = false;
            for (languages) |l| {
                if (std.mem.startsWith(u8, l, lang)) {
                    found = true;
                    const ln = try std.fmt.allocPrint(arena, "{s}\n", .{l});
                    try output_file.writeAll(ln);
                }
            }
            if (!found) {
                fatal("unknown language: '{s}'", .{lang});
            }
        }
    }
    return std.process.cleanExit();
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format, args);
    std.process.exit(1);
}
