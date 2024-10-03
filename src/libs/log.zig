const std = @import("std");
const time = std.time;

const Logger = struct {
    log_msg: []const u8,
    log_level: []const u8,
    log_time: i64,
};

pub const LogLevel = enum {
    Debug,
    Info,
    Warning,
    Error,
};

var log_time: i64 = undefined;

pub fn init() !void {
    // main allocation
    const allocator = std.heap.page_allocator;

    // u8 buffer for the path
    var exepath_buffer: [1024]u8 = undefined;
    const exepath = try std.fs.selfExePath(&exepath_buffer);

    const exe_dir = std.fs.path.dirname(exepath) orelse return error.UnexpectedNull;

    // marge the path
    const log_path = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, "logs" });
    defer allocator.free(log_path);

    var dir = std.fs.cwd().openDir(log_path, .{});
    if (dir) |*d| {
        defer d.close();
    } else |err| {
        if (err == std.fs.Dir.OpenError.FileNotFound) {
            try std.fs.cwd().makeDir(log_path);
        } else {}
    }

    log_time = time.timestamp();
}

fn get_log_file_path() ![]const u8 {
    const allocator = std.heap.page_allocator;

    var exepath_buffer: [1024]u8 = undefined;
    const exepath = try std.fs.selfExePath(&exepath_buffer);

    const exe_dir = std.fs.path.dirname(exepath) orelse return error.UnexpectedNull;

    const log_path = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, "logs" });
    defer allocator.free(log_path);

    const log_time_str = try std.fmt.allocPrint(allocator, "{d}", .{log_time});
    defer allocator.free(log_time_str);

    const log_file_name = try std.fmt.allocPrint(allocator, "{s}-log.txt", .{log_time_str});
    defer allocator.free(log_file_name);

    const log_file_path = try std.fs.path.join(allocator, &[_][]const u8{ log_path, log_file_name });
    return log_file_path;
}

pub fn log(log_msg: []const u8, log_level: LogLevel) !void {
    const allocator = std.heap.page_allocator;

    const log_file_path = try get_log_file_path();
    defer allocator.free(log_file_path);

    var log_file_result = std.fs.cwd().openFile(log_file_path, .{ .mode = .write_only });
    if (log_file_result) |log_file| {
        defer log_file.close();
    } else |outer_err| {
        if (outer_err == std.fs.Dir.OpenError.FileNotFound) {
            _ = try std.fs.cwd().createFile(log_file_path, .{});
            log_file_result = std.fs.cwd().openFile(log_file_path, .{ .mode = .write_only });
            if (log_file_result) |log_file| {
                defer log_file.close();
            } else |inner_err| {
                return inner_err;
            }
        } else {
            return outer_err;
        }
    }

    var log_level_init: []const u8 = undefined;

    switch (log_level) {
        LogLevel.Debug => {
            log_level_init = "Debug";
        },
        LogLevel.Info => {
            log_level_init = "Info";
        },
        LogLevel.Warning => {
            log_level_init = "Warning";
        },
        LogLevel.Error => {
            log_level_init = "Error";
        },
    }

    const log_entry = Logger{ .log_msg = log_msg, .log_level = log_level_init, .log_time = log_time };

    const log_str = try std.fmt.allocPrint(allocator, "{d} Level {s} : {s}\n", .{
        log_entry.log_time,
        @tagName(log_level),
        log_entry.log_msg,
    });
    defer allocator.free(log_str);

    const log_file_latest = std.fs.cwd().openFile(log_file_path, .{ .mode = .read_write });
    if (log_file_latest) |log_file| {
        defer log_file.close();

        const log_file_info = try log_file.readToEndAlloc(allocator, 1000);
        defer allocator.free(log_file_info);

        const log_file_info_str = try std.fmt.allocPrint(allocator, "{s}{s}", .{ log_file_info, log_str });
        defer allocator.free(log_file_info_str);

        try log_file.writeAll(log_file_info_str);
    } else |err| {
        return err;
    }
}
