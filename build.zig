const std = @import("std");

var stemmer = [_][]const u8{
    "stem_ISO_8859_1_basque.c",
    "stem_ISO_8859_1_catalan.c",
    "stem_ISO_8859_1_danish.c",
    "stem_ISO_8859_1_dutch.c",
    "stem_ISO_8859_1_english.c",
    "stem_ISO_8859_1_finnish.c",
    "stem_ISO_8859_1_french.c",
    "stem_ISO_8859_1_german.c",
    "stem_ISO_8859_1_indonesian.c",
    "stem_ISO_8859_1_irish.c",
    "stem_ISO_8859_1_italian.c",
    "stem_ISO_8859_1_norwegian.c",
    "stem_ISO_8859_1_portuguese.c",
    "stem_ISO_8859_1_spanish.c",
    "stem_ISO_8859_1_swedish.c",
    "stem_ISO_8859_2_hungarian.c",
    "stem_KOI8_R_russian.c",
    "stem_UTF_8_arabic.c",
    "stem_UTF_8_armenian.c",
    "stem_UTF_8_basque.c",
    "stem_UTF_8_catalan.c",
    "stem_UTF_8_danish.c",
    "stem_UTF_8_dutch.c",
    "stem_UTF_8_estonian.c",
    "stem_UTF_8_english.c",
    "stem_UTF_8_finnish.c",
    "stem_UTF_8_french.c",
    "stem_UTF_8_german.c",
    "stem_UTF_8_greek.c",
    "stem_UTF_8_hindi.c",
    "stem_UTF_8_hungarian.c",
    "stem_UTF_8_indonesian.c",
    "stem_UTF_8_irish.c",
    "stem_UTF_8_italian.c",
    "stem_UTF_8_lithuanian.c",
    "stem_UTF_8_nepali.c",
    "stem_UTF_8_norwegian.c",
    "stem_UTF_8_portuguese.c",
    "stem_UTF_8_romanian.c",
    "stem_UTF_8_russian.c",
    "stem_UTF_8_serbian.c",
    "stem_UTF_8_spanish.c",
    "stem_UTF_8_swedish.c",
    "stem_UTF_8_tamil.c",
    "stem_UTF_8_turkish.c",
    "stem_UTF_8_yiddish.c",
};

fn filter_stemmer(alloc: std.mem.Allocator, selected_languages: ?[]const u8) ![]const []const u8 {
    var result = std.ArrayList([]const u8).init(alloc);
    defer result.deinit();

    for (stemmer) |stem| {
        var x = std.mem.splitBackwardsScalar(u8, stem, '.');
        _ = x.next();
        const y = x.next() orelse unreachable;
        var z = std.mem.splitBackwardsScalar(u8, y, '_');
        const lang = z.next() orelse unreachable;
        if (selected_languages == null) {
            try result.append(stem);
        } else {
            var s = std.mem.tokenizeAny(u8, lang, ",");
            while (s.next()) |l| {
                if (std.mem.eql(u8, l, lang)) {
                    try result.append(stem);
                }
            }
        }
    }

    return try result.toOwnedSlice();
}

fn run_make_and_linkall(
    b: *std.Build,
    dep_snowball: *std.Build.Dependency,
    exe: *std.Build.Step.Compile,
    exe_unit_tests: *std.Build.Step.Compile,
    voc_tests: *std.Build.Step.Compile,
    module_snowballstem: *std.Build.Module,
    stemmer_lang_selector_tool_step: *std.Build.Step.Run,
    lang_includes: []const []const u8,
) void {
    var make_run = b.addSystemCommand(&.{"make"});
    make_run.setCwd(dep_snowball.path(""));
    //make_run.addArg("-v");
    make_run.addArg("dist_libstemmer_c");
    b.getInstallStep().dependOn(&make_run.step);

    make_run.step.dependOn(&stemmer_lang_selector_tool_step.step);

    link(b, exe, dep_snowball, make_run, lang_includes);
    link(b, exe_unit_tests, dep_snowball, make_run, lang_includes);
    link(b, voc_tests, dep_snowball, make_run, lang_includes);
    link_modul(b, module_snowballstem, dep_snowball, make_run, lang_includes);
}

fn link(
    b: *std.Build,
    cmp_stemp: *std.Build.Step.Compile,
    dep_snowball: *std.Build.Dependency,
    make_run: *std.Build.Step.Run,
    lang_includes: []const []const u8,
) void {
    _ = b;
    cmp_stemp.linkLibC();

    cmp_stemp.addCSourceFiles(.{
        .root = dep_snowball.path("libstemmer"),
        .files = &.{"libstemmer.c"},
    });

    cmp_stemp.addCSourceFiles(.{
        .root = dep_snowball.path("runtime"),
        .files = &.{
            "api.c",
            "utilities.c",
        },
    });

    cmp_stemp.addCSourceFiles(.{
        .root = dep_snowball.path("src_c"),
        .files = lang_includes,
    });

    cmp_stemp.installHeadersDirectory(dep_snowball.path(""), "include", .{
        .include_extensions = &.{"libstemmer.h"},
    });

    cmp_stemp.addIncludePath(dep_snowball.path("include"));
    cmp_stemp.addIncludePath(dep_snowball.path("runtime"));
    cmp_stemp.addIncludePath(dep_snowball.path("src_c"));

    cmp_stemp.step.dependOn(&make_run.step);
}

fn link_modul(
    b: *std.Build,
    cmp_stemp: *std.Build.Module,
    dep_snowball: *std.Build.Dependency,
    make_run: *std.Build.Step.Run,
    lang_includes: []const []const u8,
) void {
    _ = b;
    _ = make_run;
    //cmp_stemp.linkLibC();

    cmp_stemp.addCSourceFiles(.{
        .root = dep_snowball.path("libstemmer"),
        .files = &.{"libstemmer.c"},
    });

    cmp_stemp.addCSourceFiles(.{
        .root = dep_snowball.path("runtime"),
        .files = &.{
            "api.c",
            "utilities.c",
        },
    });

    cmp_stemp.addCSourceFiles(.{
        .root = dep_snowball.path("src_c"),
        .files = lang_includes,
    });

    //cmp_stemp.installHeadersDirectory(dep_snowball.path(""), "include", .{
    //    .include_extensions = &.{"libstemmer.h"},
    //});

    cmp_stemp.addIncludePath(dep_snowball.path("include"));
    cmp_stemp.addIncludePath(dep_snowball.path("runtime"));
    cmp_stemp.addIncludePath(dep_snowball.path("src_c"));

    //cmp_stemp.step.dependOn(&make_run.step);
    //cmp_stemp.linkLibrary(&make_run);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const stemmer_langs = b.option([]const u8, "stemmer_langs", "compiled stemmer languages") orelse null;

    const dep_snowball = b.dependency("snowball", .{
        .target = target,
        .optimize = optimize,
    });

    const dep_snowball_data = b.dependency("snowball-data", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "snowballstem.zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .test_runner = .{
            .path = b.path("test_runner.zig"),
            .mode = .simple,
        },
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    const module_snowballstem = b.addModule("snowballstem", .{
        .root_source_file = b.path("src/Stemmer.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const tool = b.addExecutable(.{
        .name = "generate_voc_tests",
        .root_source_file = b.path("tools/generate_voc_tests.zig"),
        .target = target,
    });

    const tool_step = b.addRunArtifact(tool);

    const lang = "german";
    const output_file = b.fmt("{s}_tests.zig", .{lang});

    tool_step.addArg("--voc-file");
    tool_step.addFileArg(dep_snowball_data.path(b.fmt("{s}/voc.txt", .{lang})));
    tool_step.addArg("--voc-output-file");
    tool_step.addFileArg(dep_snowball_data.path(b.fmt("{s}/output.txt", .{lang})));
    tool_step.addArg("--output-file");
    const output = tool_step.addOutputFileArg(output_file);
    tool_step.addArgs(&.{ "--lang", lang });

    const wf = b.addUpdateSourceFiles();
    wf.addCopyFileToSource(output, b.fmt("src/tests/{s}", .{output_file}));

    const voc_tests = b.addTest(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
        // use the default test runner to be less verbose
        // .test_runner = .{
        //    .path = b.path("test_runner.zig"),
        //    .mode = .simple,
        //},
    });
    voc_tests.step.dependOn(&wf.step);

    const run_voc_tests = b.addRunArtifact(voc_tests);
    test_step.dependOn(&run_voc_tests.step);

    const stemmer_lang_selector_tool = b.addExecutable(.{
        .name = "select_languages",
        .root_source_file = b.path("tools/select_languages.zig"),
        .target = target,
    });

    const stemmer_lang_selector_tool_file = dep_snowball.path("libstemmer/modules.txt");

    const stemmer_lang_selector_tool_step = b.addRunArtifact(stemmer_lang_selector_tool);
    stemmer_lang_selector_tool_step.addArg("--output-file");
    stemmer_lang_selector_tool_step.addArg(stemmer_lang_selector_tool_file.getPath(b));

    if (stemmer_langs != null) {
        stemmer_lang_selector_tool_step.addArgs(&.{ "--langs", stemmer_langs.? });
    }

    const lang_includes = filter_stemmer(b.allocator, stemmer_langs) catch unreachable;

    run_make_and_linkall(
        b,
        dep_snowball,
        exe,
        exe_unit_tests,
        voc_tests,
        module_snowballstem,
        stemmer_lang_selector_tool_step,
        lang_includes,
    );
}
