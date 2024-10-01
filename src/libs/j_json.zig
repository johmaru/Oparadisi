const std = @import("std");

const window_size = struct {
    width: u32,
    height: u32,
};

pub const json_content = struct {
    window_size: window_size,
};

pub fn init() !void {
    // main allocation
    const allocator = std.heap.page_allocator;

    // u8 buffer for the path
    var exepath_buffer: [1024]u8 = undefined;
    const exepath = try std.fs.selfExePath(&exepath_buffer);

    const exe_dir = std.fs.path.dirname(exepath) orelse return error.UnexpectedNull;

    // marge the path
    const config_path = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, "config" });
    defer allocator.free(config_path);

    std.debug.print("config path: {s}\n", .{config_path});

    var dir = std.fs.cwd().openDir(config_path, .{});
    if (dir) |*d| {
        defer d.close();
    } else |err| {
        if (err == std.fs.Dir.OpenError.FileNotFound) {
            try std.fs.cwd().makeDir(config_path);
        } else {}
    }
}

pub fn init_json() !void {
    // main allocation
    const allocator = std.heap.page_allocator;

    // u8 buffer for the path
    var exepath_buffer: [1024]u8 = undefined;
    const exepath = try std.fs.selfExePath(&exepath_buffer);

    const exe_dir = std.fs.path.dirname(exepath) orelse return error.UnexpectedNull;

    // marge the path
    const config_path = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, "config" });
    defer allocator.free(config_path);

    // marge the path
    const json_file_path = try std.fs.path.join(allocator, &[_][]const u8{ config_path, "config.json" });
    defer allocator.free(json_file_path);

    const file_result = std.fs.cwd().openFile(json_file_path, .{});
    if (file_result) |file| {
        defer file.close();
        const file_info = try file.readToEndAlloc(std.heap.page_allocator, 1000);
        if (file_info.len == 0) {
            try create_default_config(json_file_path);
        }
    } else |err| {
        if (err == error.FileNotFound) {
            try create_default_config(json_file_path);
        } else {
            return err;
        }
    }
}

fn create_default_config(json_file_path: []const u8) !void {
    const create = try std.fs.cwd().createFile(json_file_path, .{});
    defer create.close();
    var buff: [100]u8 = undefined;

    const jsondata = json_content{
        .window_size = window_size{ .width = 800, .height = 600 },
    };

    const option = std.json.StringifyOptions{
        .whitespace = .indent_1,
    };

    var fba = std.heap.FixedBufferAllocator.init(&buff);
    var string = std.ArrayList(u8).init(fba.allocator());
    try std.json.stringify(jsondata, option, string.writer());
    try create.writeAll(string.items);
}
