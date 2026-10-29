package tests

import "core:strings"
import "core:testing"

import "../color"

@(test)
no_color_env_disables_color :: proc(t: ^testing.T) {
	testing.expect(t, !color.should_color("1", true), "NO_COLOR=1 must disable color")
	testing.expect(t, !color.should_color("anything", true), "any non-empty NO_COLOR disables color")
}

@(test)
non_tty_disables_color :: proc(t: ^testing.T) {
	testing.expect(t, !color.should_color("", false), "piped stdout must disable color")
	testing.expect(t, !color.should_color("1", false))
}

@(test)
tty_without_no_color_enables_color :: proc(t: ^testing.T) {
	testing.expect(t, color.should_color("", true))
}

@(test)
disabled_paint_returns_plain_text :: proc(t: ^testing.T) {
	for s in color.Style {
		out := color.paint(false, s, "neon")
		testing.expect_value(t, out, "neon")
		testing.expect(t, !strings.contains(out, "\x1b"), "no escape codes when color is off")
	}
	testing.expect_value(t, color.cyan(false, "grid"), "grid")
	testing.expect_value(t, color.magenta(false, "sunset"), "sunset")
}

@(test)
enabled_paint_wraps_with_palette :: proc(t: ^testing.T) {
	defer free_all(context.temp_allocator)

	c := color.cyan(true, "grid")
	testing.expect(t, strings.has_prefix(c, "\x1b[96;40m"), "cyan on black prefix")
	testing.expect(t, strings.has_suffix(c, color.RESET), "reset suffix")
	testing.expect(t, strings.contains(c, "grid"))

	m := color.magenta(true, "sunset")
	testing.expect(t, strings.has_prefix(m, "\x1b[95;40m"), "magenta on black prefix")
	testing.expect(t, strings.has_suffix(m, color.RESET), "reset suffix")
}
