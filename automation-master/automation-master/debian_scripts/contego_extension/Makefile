prefix = /usr/local
bindir = $(prefix)/bin
sharedir = $(prefix)/share
mandir = $(sharedir)/man
man1dir = $(mandir)/man1

CFLAGS = --std=c99

all: contego

clean:
	rm -f contego contego.o

install: all
	install contego $(DESTDIR)$(bindir)
	install -m 0644 contego.1 $(DESTDIR)$(man1dir)

clean:
	rm -rf $(CURDIR)/home/tvault/.virtenv/
	rm -rf  $(CURDIR)/home/tvault/tvault-contego-virtenv.tar.gz	
	rm -rf  $(CURDIR)/debian/home/tvault/.virtenv
