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
    try capy.backend.init();

    var window = try capy.Window.init();
    try window.set(
        capy.label(.{ .text = "Hello, World", .alignment = .Center }),
    );

    window.setTitle("Hello");
    window.setPreferredSize(250, 100);
    window.show();

    capy.runEventLoop();
}
