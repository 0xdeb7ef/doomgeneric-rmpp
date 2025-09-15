const std = @import("std");
const zqtfb = @import("zqtfb");
const doomgeneric = @cImport(@cInclude("doomgeneric.h"));

var client: zqtfb.Client = undefined;
const width = 640;
const height = 400;
var start_time: i64 = undefined;
var last_tick: i64 = 0;

pub fn main() !void {
    start_time = std.time.milliTimestamp();

    doomgeneric.doomgeneric_Create(@intCast(std.os.argv.len), @ptrCast(std.os.argv.ptr));

    while (true) {
        doomgeneric.doomgeneric_Tick();
    }
}

export fn DG_Init() callconv(.c) void {
    const fb = zqtfb.getIDFromAppLoad() catch {
        std.process.exit(1);
    };

    client = zqtfb.Client.init(
        fb,
        .rMPP_rgba8888,
        .{ .width = width, .height = height },
        true,
    ) catch {
        std.process.exit(2);
    };

    client.fullUpdate() catch {
        std.process.exit(3);
    };
}

// TODO - Implement input
export fn DG_GetKey() callconv(.c) c_int {
    return 0;
}

// noop
export fn DG_SetWindowTitle(title: [*]c_char) callconv(.c) void {
    _ = title; // autofix
}

export fn DG_DrawFrame() callconv(.c) void {
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

    if (diff > std.time.ms_per_s) {
        client.fullUpdate() catch {
            std.process.exit(3);
        };

        last_tick = tick;
    }
}

export fn DG_SleepMs(ms: u32) callconv(.c) void {
    std.posix.nanosleep(0, ms * std.time.ns_per_ms);
}

export fn DG_GetTicksMs() callconv(.c) u32 {
    const now = std.time.milliTimestamp();
    const diff: u64 = @intCast(now - start_time);

    return @truncate(diff);
}
