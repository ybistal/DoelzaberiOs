#!/bin/sh

if [ -t 1 ] && [ -x /usr/bin/fastfetch ]; then
	case "$-" in
		*i*) /usr/bin/fastfetch ;;
	esac
fi
