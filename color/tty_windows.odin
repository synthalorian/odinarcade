#+build windows
package color

// stdout_is_tty is conservative on Windows: color stays off until a proper
// console-mode check is wired in.
stdout_is_tty :: proc() -> bool {
	return false
}
