const std = @import("std");
const capy = @import("capy");
const j_json = @import("libs/j_json.zig");

// This is required for your app to build to WebAssembly and other particular architectures

pub usingnamespace capy.cross_platform;

pub fn main() !void {
    try j_json.init();
    try j_json.init_json();
    try init_window();
}

fn init_window() !void {
    //get the window width and height from the json file
    const allocator = std.heap.page_allocator;
    var exepath_buffer: [1024]u8 = undefined;
    const exepath = try std.fs.selfExePath(&exepath_buffer);

    const exe_dir = std.fs.path.dirname(exepath) orelse return error.UnexpectedNull;

    const config_path = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, "config" });
    defer allocator.free(config_path);
    const json_file_path = try std.fs.path.join(allocator, &[_][]const u8{ config_path, "config.json" });
    defer allocator.free(json_file_path);

    const open = try std.fs.cwd().openFile(json_file_path, .{});
    defer open.close();

    const stringAlloc = std.heap.page_allocator;
    const file_content_alloc = try open.readToEndAlloc(stringAlloc, 1000);
    defer stringAlloc.free(file_content_alloc);
    const parse = try std.json.parseFromSlice(j_json.json_content, stringAlloc, file_content_alloc, .{});
    defer parse.deinit();

    const parsed_value = parse.value;

    const w_width: u32 = parsed_value.window_size.width;
    const w_height: u32 = parsed_value.window_size.height;

    try capy.backend.init();

    var window = try capy.Window.init();
    try window.set(
        capy.label(.{ .text = "Hello, World", .alignment = .Center }),
    );

    window.setTitle("Hello");
    window.setPreferredSize(w_width, w_height);
    window.show();

    capy.runEventLoop();
}
