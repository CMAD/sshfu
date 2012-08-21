#!/bin/sh

vimsyntax() {
	mkdir -p ~/.vim/syntax
	cp "$ORIGIN/misc/sshfu.vim" ~/.vim/syntax
	cat >> ~/.vimrc <<-EOF
		" sshfu syntax highliting (autoinstalled)
		au BufNewFile,BufRead ~/.ssh/sshfu/routes set filetype=sshfu
	EOF
}

ORIGIN=`dirname "$0"`

echo "running autoinstall..." >&2

echo "trying to copy the script to /usr/local/bin using normal cp" >&2
cp "$0" /usr/local/bin/sshfu 

if [ "$?" -ne 0 ]; then
	echo "it didn't work, trying to use sudo..." >&2 
	sudo cp "$ORIGIN/sshfu" /usr/local/bin/sshfu && echo ... ok. >&2 && return 0
else
	echo ... ok. >&2
	return 0
fi

echo "didn't work either, trying su" >&2
su root -c "cp '$ORIGIN/sshfu' /usr/local/bin/sshfu" 

if [ "$?" -ne 0 ]; then
	echo "didn't work, plase install manually." >&2
	exit 1
fi

echo ... ok. >&2

if [ -e ./misc/sshfu.vim ] && [ ! -e ~/.vim/syntax/sshfu.vim ]; then
	vimsyntax
fi
