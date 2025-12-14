const std = @import("std");
const zqtfb = @import("zqtfb");
const doomgeneric = @cImport(@cInclude("doomgeneric.h"));
const keys = @cImport(@cInclude("doomkeys.h"));

var client: zqtfb.Client = undefined;
const width = 640;
const height = 400;
var start_time: i64 = undefined;
var bw: bool = true;

const log = std.log.scoped(.doomgeneric_rmpp);

// controller
const pad_size = 100;
const dpad_x = 25;
const dpad_y = 70;
const action_x = width - 25 - pad_size;
const action_y = 70;
const button_size = pad_size / 3;

const button_color: [4]u8 = .{ 255, 255, 255, 255 };
const button_color_pressed: [4]u8 = .{ 127, 127, 127, 255 };

var dpad: struct { up: bool, down: bool, left: bool, right: bool, use: bool, fire: bool, enter: bool } = .{
    .up = false,
    .down = false,
    .left = false,
    .right = false,
    .use = false,
    .fire = false,
    .enter = false,
};

const Key = struct {
    pressed: bool,
    key: KeyType,

    const KeyType = enum {
        dpad_up,
        dpad_down,
        dpad_left,
        dpad_right,
        use,
        fire,
        enter,
    };
};

const key_q_size: usize = 16;
var key_buffer: [key_q_size]Key = undefined;
var key_write_idx: usize = 0;
var key_read_idx: usize = 0;

fn pollThread() void {
    while (true) {
        const s = client.pollServerPacket() catch {
            continue;
        };

        if (s.type == .user_input) {
            switch (s.message.input.type) {
                .touch_release => {
                    // client.deinit();
                    // std.posix.exit(0);

                    dpad.up = false;
                    dpad.down = false;
                    dpad.right = false;
                    dpad.left = false;
                    dpad.use = false;
                    dpad.fire = false;
                    dpad.enter = false;

                    key_buffer[key_write_idx] = .{ .pressed = false, .key = .dpad_up };
                    key_write_idx += 1;
                    key_write_idx %= key_q_size;
                    key_buffer[key_write_idx] = .{ .pressed = false, .key = .dpad_down };
                    key_write_idx += 1;
                    key_write_idx %= key_q_size;
                    key_buffer[key_write_idx] = .{ .pressed = false, .key = .dpad_left };
                    key_write_idx += 1;
                    key_write_idx %= key_q_size;
                    key_buffer[key_write_idx] = .{ .pressed = false, .key = .dpad_right };
                    key_write_idx += 1;
                    key_write_idx %= key_q_size;
                    key_buffer[key_write_idx] = .{ .pressed = false, .key = .use };
                    key_write_idx += 1;
                    key_write_idx %= key_q_size;
                    key_buffer[key_write_idx] = .{ .pressed = false, .key = .fire };
                    key_write_idx += 1;
                    key_write_idx %= key_q_size;
                    key_buffer[key_write_idx] = .{ .pressed = false, .key = .enter };
                    key_write_idx += 1;
                    key_write_idx %= key_q_size;
                },
                .touch_press => {
                    const x = s.message.input.y;
                    const y = s.message.input.x;

                    if (x >= dpad_x + button_size and
                        x <= dpad_x + button_size * 2 and
                        y >= dpad_y + button_size * 2 and
                        y <= dpad_y + button_size * 3)
                    {
                        dpad.up = true;
                        key_buffer[key_write_idx] = .{ .pressed = true, .key = .dpad_up };
                        key_write_idx += 1;
                        key_write_idx %= key_q_size;
                    }

                    if (x >= dpad_x and
                        x <= dpad_x + button_size and
                        y >= dpad_y + button_size and
                        y <= dpad_y + button_size * 2)
                    {
                        dpad.left = true;
                        key_buffer[key_write_idx] = .{ .pressed = true, .key = .dpad_left };
                        key_write_idx += 1;
                        key_write_idx %= key_q_size;
                    }

                    if (x >= dpad_x + button_size * 2 and
                        x <= dpad_x + button_size * 3 and
                        y >= dpad_y + button_size and
                        y <= dpad_y + button_size * 2)
                    {
                        dpad.right = true;
                        key_buffer[key_write_idx] = .{ .pressed = true, .key = .dpad_right };
                        key_write_idx += 1;
                        key_write_idx %= key_q_size;
                    }

                    if (x >= dpad_x + button_size and
                        x <= dpad_x + button_size * 2 and
                        y >= dpad_y and
                        y <= dpad_y + button_size)
                    {
                        dpad.down = true;
                        key_buffer[key_write_idx] = .{ .pressed = true, .key = .dpad_down };
                        key_write_idx += 1;
                        key_write_idx %= key_q_size;
                    }

                    if (x >= action_x and
                        x <= action_x + button_size and
                        y >= action_y and
                        y <= action_y + button_size)
                    {
                        dpad.use = true;
                        key_buffer[key_write_idx] = .{ .pressed = true, .key = .use };
                        key_write_idx += 1;
                        key_write_idx %= key_q_size;
                    }

                    if (x >= action_x + button_size / 2 and
                        x <= action_x + button_size / 2 + button_size * 2 and
                        y >= action_y + button_size * 2 and
                        y <= action_y + button_size * 3 + button_size * 2)
                    {
                        dpad.fire = true;
                        key_buffer[key_write_idx] = .{ .pressed = true, .key = .fire };
                        key_write_idx += 1;
                        key_write_idx %= key_q_size;
                    }

                    if (x >= action_x + button_size * 2 and
                        x <= action_x + button_size * 3 and
                        y >= action_y and
                        y <= action_y + button_size)
                    {
                        dpad.enter = true;
                        key_buffer[key_write_idx] = .{ .pressed = true, .key = .enter };
                        key_write_idx += 1;
                        key_write_idx %= key_q_size;
                    }
                },
                .pen_release => {
                    client.deinit();
                    std.posix.exit(0);
                    // if (bw) {
                    //     client.setRefreshMode(.ufast) catch |err| {
                    //         log.warn("Unable to set ufast refresh mode: {}", .{err});
                    //         continue;
                    //     };
                    //     bw = false;
                    // } else {
                    //     client.setRefreshMode(.animate) catch |err| {
                    //         log.warn("Unable to set animate refresh mode: {}", .{err});
                    //         continue;
                    //     };
                    //     bw = true;
                    // }
                },
                else => {},
            }
        }
    }
}

pub fn main() !void {
    start_time = std.time.milliTimestamp();
    log.info("Starting doomgeneric-rmpp at {d}", .{start_time});

    doomgeneric.doomgeneric_Create(@intCast(std.os.argv.len), @ptrCast(std.os.argv.ptr));

    log.info("doomgenetic_Create successfully ran", .{});

    while (true) {
        doomgeneric.doomgeneric_Tick();
        // log.debug("doomgeneric_Tick", .{});
    }
}

fn drawRect(buffer: []u8, x: usize, y: usize, w: usize, h: usize, color: [4]u8) void {
    for (y..y + h) |row| {
        for (x..x + w) |col| {
            const i = client.getPixel(@intCast(row), @intCast(col));
            buffer[i] = color[0]; // R
            buffer[i + 1] = color[1]; // G
            buffer[i + 2] = color[2]; // B
            buffer[i + 3] = 255; // A
        }
    }
}

fn drawDPad(buffer: []u8) void {
    // UP
    drawRect(
        buffer,
        dpad_x + button_size,
        dpad_y + button_size * 2,
        button_size,
        button_size,
        if (dpad.up) button_color_pressed else button_color,
    );

    // DOWN
    drawRect(
        buffer,
        dpad_x + button_size,
        dpad_y,
        button_size,
        button_size,
        if (dpad.down) button_color_pressed else button_color,
    );

    // LEFT
    drawRect(
        buffer,
        dpad_x,
        dpad_y + button_size,
        button_size,
        button_size,
        if (dpad.left) button_color_pressed else button_color,
    );

    // RIGHT
    drawRect(
        buffer,
        dpad_x + button_size * 2,
        dpad_y + button_size,
        button_size,
        button_size,
        if (dpad.right) button_color_pressed else button_color,
    );

    // USE
    drawRect(
        buffer,
        action_x,
        action_y,
        button_size,
        button_size,
        if (dpad.use) button_color_pressed else button_color,
    );

    // FIRE
    drawRect(
        buffer,
        action_x + button_size / 2,
        action_y + button_size * 2,
        button_size + button_size,
        button_size + button_size,
        if (dpad.fire) button_color_pressed else button_color,
    );

    // ENTER
    drawRect(
        buffer,
        action_x + button_size * 2,
        action_y,
        button_size,
        button_size,
        if (dpad.enter) button_color_pressed else button_color,
    );
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
        .{ .width = height, .height = width },
        true,
    ) catch |err| {
        log.err("Unable to create qtfb client: {}", .{err});
        std.process.exit(2);
    };

    client.setRefreshMode(.animate) catch |err| {
        log.err("Unable to set animate refresh mode: {}", .{err});
        client.deinit();
        std.posix.exit(3);
    };

    client.fullUpdate() catch |err| {
        log.warn("Full screen update failed, continuing: {}", .{err});
    };

    const t = std.Thread.spawn(.{}, pollThread, .{}) catch |err| {
        log.err("Unable to spawn poll thread: {}", .{err});
        client.deinit();
        std.posix.exit(4);
    };
    t.detach();
}

// TODO - Implement input
export fn DG_GetKey(pressed: [*c]c_int, key: [*c]c_char) callconv(.c) c_int {
    // const src = @src();
    // log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });

    if (key_read_idx == key_write_idx) {
        return 0;
    }

    const k = key_buffer[key_read_idx];
    key_read_idx += 1;
    key_read_idx %= key_q_size;

    pressed.* = @intFromBool(k.pressed);
    key.* = switch (k.key) {
        .dpad_up => keys.KEY_UPARROW,
        .dpad_down => keys.KEY_DOWNARROW,
        .dpad_left => keys.KEY_LEFTARROW,
        .dpad_right => keys.KEY_RIGHTARROW,
        .use => keys.KEY_USE,
        .fire => keys.KEY_FIRE,
        .enter => keys.KEY_ENTER,
    };

    return 1;
}

// noop
export fn DG_SetWindowTitle(title: [*]c_char) callconv(.c) void {
    const src = @src();
    log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });
    _ = title; // autofix
}

export fn DG_DrawFrame() callconv(.c) void {
    // const src = @src();
    // log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });
    var buffer: [width * height * 4]u8 = undefined;

    for (0..height) |h| {
        for (0..width) |w| {
            // ScreenBuffer: BGRA (or possibly ARGB, just flipped)
            // rMPP:         RGBA
            const i = client.getPixel(@intCast(height - 1 - h), @intCast(w));
            const p: [4]u8 = @bitCast(doomgeneric.DG_ScreenBuffer[h * width + w]);
            // client.display[i] = p[2]; // R
            // client.display[i + 1] = p[1]; // G
            // client.display[i + 2] = p[0]; // B
            // client.display[i + 3] = 255; // A
            buffer[i] = p[2]; // R
            buffer[i + 1] = p[1]; // G
            buffer[i + 2] = p[0]; // B
            buffer[i + 3] = 255; // A
        }
    }

    drawDPad(&buffer);
    @memcpy(client.display, &buffer);

    // log.debug("Copied DG_ScreenBuffer to client.shm", .{});

    client.fullUpdate() catch |err| {
        log.warn("Full screen update failed, continuing: {}", .{err});
    };
}

export fn DG_SleepMs(ms: u32) callconv(.c) void {
    // const src = @src();
    // log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });

    std.posix.nanosleep(0, ms * std.time.ns_per_ms);
}

export fn DG_GetTicksMs() callconv(.c) u32 {
    // const src = @src();
    // log.debug("{s}: {s} {d}:{d}", .{ src.file, src.fn_name, src.line, src.column });

    const now = std.time.milliTimestamp();
    const diff: u64 = @intCast(now - start_time);

    return @truncate(diff);
}
