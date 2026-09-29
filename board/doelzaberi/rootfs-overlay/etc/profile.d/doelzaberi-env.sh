
if [ -z "${XDG_RUNTIME_DIR:-}" ]; then
	_dir="/run/user/$(id -u)"
	if [ -d "$_dir" ] && [ -w "$_dir" ]; then
		XDG_RUNTIME_DIR=$_dir
	elif mkdir -p "$_dir" 2>/dev/null && chmod 0700 "$_dir" 2>/dev/null; then
		XDG_RUNTIME_DIR=$_dir
	else
		_dir="/tmp/doelzaberi-runtime-$(id -u)"
		mkdir -p "$_dir" 2>/dev/null && chmod 0700 "$_dir" 2>/dev/null
		[ -d "$_dir" ] && XDG_RUNTIME_DIR=$_dir
	fi
	[ -n "${XDG_RUNTIME_DIR:-}" ] && export XDG_RUNTIME_DIR
	unset _dir
fi

case "${TERM:-}" in
'' | vt100 | vt102 | vt220 | dumb)
	case "$(tty 2>/dev/null)" in
	/dev/tty[0-9]*) TERM=linux; export TERM ;;
	esac
	;;
esac

