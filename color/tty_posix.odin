#+build linux, darwin, freebsd, openbsd, netbsd
package color

import "core:sys/posix"

// stdout_is_tty reports whether file descriptor 1 is attached to a terminal.
stdout_is_tty :: proc() -> bool {
	return bool(posix.isatty(posix.STDOUT_FILENO))
}
