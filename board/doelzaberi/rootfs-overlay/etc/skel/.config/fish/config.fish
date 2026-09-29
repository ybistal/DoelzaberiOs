
if status is-interactive
    set -g fish_greeting
end

fish_add_path -g /usr/local/bin /usr/bin /usr/sbin /bin /sbin

alias ll 'ls -lh'
alias la 'ls -lah'
alias l 'ls -l'
alias .. 'cd ..'
alias ... 'cd ../..'
alias df 'df -h'
alias free 'free -h'

alias gui 'doelzaberi-gui'
