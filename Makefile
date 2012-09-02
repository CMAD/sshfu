PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
VIMDIR = $(PREFIX)/share/vim/addons

destdirs :=	$(DESTDIR)$(BINDIR) \
		$(DESTDIR)$(VIMDIR)/syntax \
		$(DESTDIR)$(VIMDIR)/ftdetect

all:
install: all
	install -d $(destdirs)
	install sshfu $(DESTDIR)$(BINDIR)
	install -m644 misc/sshfu.vim $(DESTDIR)$(VIMDIR)/syntax
	install -m644 misc/sshfu_file.vim $(DESTDIR)$(VIMDIR)/ftdetect
