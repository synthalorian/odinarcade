// Package color is the single place that knows about ANSI escape codes.
// Palette: neon cyan + hot magenta on a black background.
//
// Color is disabled when:
//   - the NO_COLOR environment variable is set to a non-empty value
//     (https://no-color.org), or
//   - stdout is not a TTY (pipes, files, CI logs).
package color

import "core:c/libc"
import "core:fmt"

RESET :: "\x1b[0m"

Style :: enum {
	Cyan,
	Magenta,
}

// style_code returns the SGR sequence for a style (bright fg on black bg).
style_code :: proc(s: Style) -> string {
	switch s {
	case .Cyan:
		return "\x1b[96;40m"
	case .Magenta:
		return "\x1b[95;40m"
	}
	return ""
}

// should_color is the pure decision function: color only when NO_COLOR is
// empty/unset AND stdout is a terminal.
should_color :: proc(no_color: string, is_tty: bool) -> bool {
	return no_color == "" && is_tty
}

// no_color_env returns the value of NO_COLOR, or "" when unset.
no_color_env :: proc() -> string {
	return string(libc.getenv("NO_COLOR"))
}

// enabled_from_env inspects the real environment and stdout.
enabled_from_env :: proc() -> bool {
	return should_color(no_color_env(), stdout_is_tty())
}

// paint wraps s in the style's escape codes when enabled. When disabled it
// returns s unchanged (no allocation). Enabled output lives in the temp allocator.
paint :: proc(enabled: bool, style: Style, s: string) -> string {
	if !enabled {
		return s
	}
	return fmt.tprintf("%s%s%s", style_code(style), s, RESET)
}

cyan :: proc(enabled: bool, s: string) -> string {
	return paint(enabled, .Cyan, s)
}

magenta :: proc(enabled: bool, s: string) -> string {
	return paint(enabled, .Magenta, s)
}
