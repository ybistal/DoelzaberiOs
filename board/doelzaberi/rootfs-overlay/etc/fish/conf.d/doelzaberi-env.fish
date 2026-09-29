
if not set -q XDG_RUNTIME_DIR
    set -l candidate /run/user/(id -u)
    if test -d $candidate; and test -w $candidate
        set -gx XDG_RUNTIME_DIR $candidate
    else if mkdir -p $candidate 2>/dev/null; and chmod 0700 $candidate 2>/dev/null
        set -gx XDG_RUNTIME_DIR $candidate
    else
        set -l fallback /tmp/doelzaberi-runtime-(id -u)
        if mkdir -p $fallback 2>/dev/null
            chmod 0700 $fallback 2>/dev/null
            set -gx XDG_RUNTIME_DIR $fallback
        end
    end
end

switch "$TERM"
    case '' vt100 vt102 vt220 dumb
        if string match -q '/dev/tty[0-9]*' (tty 2>/dev/null)
            set -gx TERM linux
        end
end

