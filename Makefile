B := ./build-domu

.PHONY: lapp
lapp:
	$(B) b3.18-pcre
	$(B) b3.17-db
	$(B) b3.25-postfix
	$(B) b3.30-START_POSTFIX
	$(B) b3.47-curl
	cd lapp && ln -s Makefile.XLAPP Makefile
	$(MAKE) -C lapp xlapp
