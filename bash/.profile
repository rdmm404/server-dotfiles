# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# Add user tools once, including the Node version selected by fnm's default alias.
for path_dir in "$HOME/bin" "$HOME/.local/bin" "$HOME/.local/share/fnm/aliases/default/bin"; do
    if [ -d "$path_dir" ]; then
        case ":$PATH:" in
            *":$path_dir:"*) ;;
            *) PATH="$path_dir:$PATH" ;;
        esac
    fi
done
unset path_dir
export PATH

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
