/*
 * Copyright (c) 2019 elementary LLC. (https://github.com/elementary/vala-lint)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

public class ValaLint.Checks.IndentationCheck : Check {
    const string MESSAGE = _("Indentation is %d but should %d");
    public int indent_size = 4;

    public IndentationCheck () {
        Object (
            title: _("indentation"),
            description: _("Checks for correct indentation")
        );

        state = Config.get_state (title);
    }

    public override void check (Vala.ArrayList<ParseResult?> parse_result,
                                ref Vala.ArrayList<FormatMistake?> mistake_list) {

    }

    public bool is_explicit_namespace (Vala.Namespace ns) {
        if (ns.get_classes ().size == 1
            && ns.get_classes ()[0].source_reference.begin.line == ns.source_reference.begin.line) {
            return false;
        }

        return true;
    }

    public bool is_else_if_statement (Vala.IfStatement s) {
        var b = s.parent_node;
        if (b != null && b.parent_node is Vala.IfStatement) {
            Vala.IfStatement if_statement = (Vala.IfStatement)b.parent_node;
            if (if_statement.false_statement == b && b.source_reference.begin.line == s.source_reference.begin.line) {
                return true;
            }
        }

        return false;
    }

    public void check_block (Vala.Block b, int level, ref Vala.ArrayList<FormatMistake?> mistake_list) {
        if (state == Config.State.OFF) {
            return;
        }

        foreach (var s in b.get_statements ()) {
            int offset = 0;

            if (s is Vala.IfStatement && is_else_if_statement ((Vala.IfStatement)s)) {
                offset -= 1;
            }

            if (s.parent_node == null || s.parent_node.source_reference.begin.line != s.source_reference.begin.line) {
                check_line (s.source_reference, level + offset, ref mistake_list);
            }
        }
    }

    public void check_symbol (Vala.Symbol s, int level, ref Vala.ArrayList<FormatMistake?> mistake_list) {
        if (state == Config.State.OFF) {
            return;
        }

        if (s.parent_node == null || s.parent_node.source_reference.begin.line != s.source_reference.begin.line) {
            check_line (s.source_reference, level, ref mistake_list);
        }
    }

    private void check_line (Vala.SourceReference loc, int level, ref Vala.ArrayList<FormatMistake?> mistake_list) {
        Vala.SourceLocation line = loc.begin;
        char* file_begin = loc.file.get_mapped_contents ();

        while (line.pos > file_begin && line.pos[0] != '\n') {
            line.pos -= 1;
            line.column -= 1;
        }

        var first_char = line;
        int indent = 0;
        while (first_char.pos[0] == ' ' || first_char.pos[0] == '\n' || first_char.pos[0] == '\t') {
            if (first_char.pos[0] == ' ') {
                indent += 1;
            }

            first_char.pos += 1;
            first_char.column += 1;
        }

        int indent_should = level * indent_size;
        if (indent != indent_should) {
            add_mistake ({ this, first_char, line, MESSAGE.printf (indent, indent_should) }, ref mistake_list);
        }
    }
}
