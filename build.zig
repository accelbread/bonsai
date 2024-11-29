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

const std = @import("std");
const builtin = @import("builtin");
const breadcore = @import("breadcore");

pub fn build(b: *std.Build) !void {
    return breadcore.standardBuild(b, "bonsai", .exe(linkLibraries));
}

fn linkLibraries(exe: *std.Build.Step.Compile) void {
    exe.linkLibC();
    exe.linkSystemLibrary("tree-sitter");
    exe.linkSystemLibrary("tree-sitter-c");
}
