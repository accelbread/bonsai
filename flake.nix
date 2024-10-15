# bonsai -- Semantic command line refactoring tool
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  description = "Semantic command line refactoring tool.";
  inputs.flakelight-zig.url = "github:accelbread/flakelight-zig";
  outputs = { flakelight-zig, ... }:
    flakelight-zig ./. {
      license = "AGPL-3.0-or-later";
      zigFlags = [ "--release" ];
      zigSystemLibs = pkgs:
        let
          treeSitterLangs = [ "c" ];
          treeSitterGrammars = pkgs.linkFarm "tree-sitter-grammars" (map
            (g:
              let
                name = "tree-sitter-${g}";
                grammar = pkgs.tree-sitter.builtGrammars.${name};
                pkg = pkgs.linkFarm name [{
                  name = "lib/lib${name}.so";
                  path = "${grammar}/parser";
                }];
              in
              {
                name = "lib/pkgconfig/${name}.pc";
                path = pkgs.writeText "${name}-pc" ''
                  Name: ${name}
                  Description: Tree-sitter grammar for ${g}
                  Version: ${grammar.version}
                  Libs: -L${pkg}/lib -l${name}
                '';
              })
            treeSitterLangs);
        in
        [ pkgs.tree-sitter treeSitterGrammars ];
    };
}
