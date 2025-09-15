const std = @import("std");
const zqtfb = @import("zqtfb");
const doomgeneric = @cImport(@cInclude("doomgeneric.h"));

var client: zqtfb.Client = undefined;
const width = 640;
const height = 400;
var start_time: i64 = undefined;
var last_tick: i64 = 0;

const log = std.log.scoped(.doomgeneric_rmpp);

pub fn main() !void {
    start_time = std.time.milliTimestamp();
    log.info("Starting doomgeneric-rmpp at {d}", .{start_time});

    doomgeneric.doomgeneric_Create(@intCast(std.os.argv.len), @ptrCast(std.os.argv.ptr));

    log.info("doomgenetic_Create successfully ran", .{});

    while (true) {
        doomgeneric.doomgeneric_Tick();
        log.debug("doomgeneric_Tick", .{});
    }
}

export fn DG_Init() callconv(.c) void {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });

    const fb = zqtfb.getIDFromAppLoad() catch |err| {
        log.err("Unable to grab QTFB_KEY: {}", .{err});
        std.process.exit(1);
    };

    client = zqtfb.Client.init(
        fb,
        .rMPP_rgba8888,
        .{ .width = width, .height = height },
        true,
    ) catch |err| {
        log.err("Unable to create qtfb client: {}", .{err});
        std.process.exit(2);
    };

    client.fullUpdate() catch |err| {
        log.warn("Full screen update failed, continuing: {}", .{err});
    };
}

// TODO - Implement input
export fn DG_GetKey() callconv(.c) c_int {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });

    return 0;
}

// noop
export fn DG_SetWindowTitle(title: [*]c_char) callconv(.c) void {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });
    _ = title; // autofix
}

export fn DG_DrawFrame() callconv(.c) void {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });

    const tick = std.time.milliTimestamp();
    const diff = tick - last_tick;

    for (0..(width * height)) |i| {
        // ScreenBuffer: BGRA (or possibly ARGB, just flipped)
        // rMPP:         RGBA
        const p: [4]u8 = @bitCast(doomgeneric.DG_ScreenBuffer[i]);
        client.shm[(i * 4)] = p[2]; // R
        client.shm[(i * 4) + 1] = p[1]; // G
        client.shm[(i * 4) + 2] = p[0]; // B
        client.shm[(i * 4) + 3] = 255; // A
    }

    log.debug("Copied DG_ScreenBuffer to client.shm", .{});

    if (diff > std.time.ms_per_s) {
        client.fullUpdate() catch |err| {
            log.warn("Full screen update failed, continuing: {}", .{err});
        };

        last_tick = tick;
    }
}

export fn DG_SleepMs(ms: u32) callconv(.c) void {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });

    std.posix.nanosleep(0, ms * std.time.ns_per_ms);
}

export fn DG_GetTicksMs() callconv(.c) u32 {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });

    const now = std.time.milliTimestamp();
    const diff: u64 = @intCast(now - start_time);

    return @truncate(diff);
}
