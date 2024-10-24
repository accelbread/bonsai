// bonsai -- Semantic command line refactoring tool
// Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option) any
// later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const builtin = @import("builtin");
const std = @import("std");
const log = std.log;
const assert = std.debug.assert;

const c = @cImport({
    @cInclude("tree_sitter/api.h");
});

extern fn tree_sitter_c() ?*const c.TSLanguage;

pub fn main() !void {
    const args = std.os.argv;
    assert(args.len == 4);

    const parser: *c.TSParser = c.ts_parser_new().?;
    defer c.ts_parser_delete(parser);

    const language: *const c.TSLanguage = tree_sitter_c() orelse
        return error.TreeSitterLanuageInitError;
    defer c.ts_language_delete(language);

    if (!c.ts_parser_set_language(parser, language)) {
        return error.TreeSitterSetLanguageError;
    }

    const source = src: {
        const file = try std.posix.openZ(
            args[3],
            .{ .ACCMODE = .RDONLY, .CLOEXEC = true },
            0,
        );
        defer std.posix.close(file);

        const stat = try std.posix.fstat(file);

        if (stat.size > std.math.maxInt(u32)) {
            return error.FileTooLarge;
        }

        break :src try std.posix.mmap(
            null,
            @intCast(stat.size),
            std.posix.PROT.READ,
            .{ .TYPE = .PRIVATE },
            file,
            0,
        );
    };

    const tree: *c.TSTree = c.ts_parser_parse_string(
        parser,
        null,
        source.ptr,
        @intCast(source.len),
    ) orelse return error.TreeSitterParseError;
    defer c.ts_tree_delete(tree);

    var err: c.TSQueryError = c.TSQueryErrorNone;
    var err_offset: u32 = 0;

    const query: *c.TSQuery = c.ts_query_new(
        language,
        args[1],

        @intCast(std.mem.len(args[1])),
        &err_offset,
        &err,
    ) orelse {
        std.debug.print("Query error at offset {}: {}\n", .{ err, err_offset });
        return error.TreeSitterQueryError;
    };
    defer c.ts_query_delete(query);

    const query_cursor: *c.TSQueryCursor = c.ts_query_cursor_new().?;
    defer c.ts_query_cursor_delete(query_cursor);

    const root_node: c.TSNode = c.ts_tree_root_node(tree);
    c.ts_query_cursor_exec(query_cursor, query, root_node);

    var match: c.TSQueryMatch = undefined;

    while (c.ts_query_cursor_next_match(query_cursor, &match)) {
        const captures: []const c.TSQueryCapture =
            match.captures[0..match.capture_count];
        for (captures) |capture| {
            std.debug.print("{any}\n", .{capture});
        }
    }
}
