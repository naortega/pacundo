# Copyright (C) 2024 Ortega Froysa, Nicolás <nicolas@ortegas.org> All rights reserved.
# Author: Ortega Froysa, Nicolás <nicolas@ortegas.org>
#
# This software is provided 'as-is', without any express or implied
# warranty. In no event will the authors be held liable for any damages
# arising from the use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
#
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
#
# 3. This notice may not be removed or altered from any source
#    distribution.

ifeq ($(PREFIX),)
	PREFIX := /usr/local
endif

pacundo.1.gz: pacundo.1
	gzip -c $^ > $@

.PHONY: clean doc install uninstall

clean:
	$(RM) pacundo.1.gz

doc: pacundo.1.gz

install: pacundo.1.gz
	install -Dm755 pacundo.pl $(PREFIX)/bin/pacundo
	install -Dm644 pacundo.1.gz $(PREFIX)/share/man/man1/

uninstall:
	$(RM) $(PREFIX)/bin/pacundo
	$(RM) $(PREFIX)/share/man/man1/pacundo.1.gz
