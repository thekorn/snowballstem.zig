const std = @import("std");

fn run_make_and_linkall(b: *std.Build, dep_snowball: *std.Build.Dependency, exe: *std.Build.Step.Compile, exe_unit_tests: *std.Build.Step.Compile) void {
    var make_run = b.addSystemCommand(&.{"make"});
    make_run.setCwd(dep_snowball.path(""));
    make_run.addArg("dist_libstemmer_c");
    b.getInstallStep().dependOn(&make_run.step);

    link(b, exe, dep_snowball, make_run);
    link(b, exe_unit_tests, dep_snowball, make_run);
}

fn link(b: *std.Build, cmp_stemp: *std.Build.Step.Compile, dep_snowball: *std.Build.Dependency, make_run: *std.Build.Step.Run) void {
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

    cmp_stemp.addCSourceFiles(.{ .root = dep_snowball.path("src_c"), .files = &.{
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
        "stem_ISO_8859_1_porter.c",
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
        "stem_UTF_8_porter.c",
        "stem_UTF_8_portuguese.c",
        "stem_UTF_8_romanian.c",
        "stem_UTF_8_russian.c",
        "stem_UTF_8_serbian.c",
        "stem_UTF_8_spanish.c",
        "stem_UTF_8_swedish.c",
        "stem_UTF_8_tamil.c",
        "stem_UTF_8_turkish.c",
        "stem_UTF_8_yiddish.c",
    } });

    cmp_stemp.installHeadersDirectory(dep_snowball.path(""), "include", .{
        .include_extensions = &.{"libstemmer.h"},
    });

    cmp_stemp.addIncludePath(dep_snowball.path("include"));
    cmp_stemp.addIncludePath(dep_snowball.path("runtime"));
    cmp_stemp.addIncludePath(dep_snowball.path("src_c"));

    cmp_stemp.step.dependOn(&make_run.step);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep_snowball = b.dependency("snowball", .{
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
        .test_runner = b.path("test_runner.zig"),
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    run_make_and_linkall(b, dep_snowball, exe, exe_unit_tests);
}
