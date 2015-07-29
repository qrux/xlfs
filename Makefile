# How to fix this build parallelization (parallel-compiles WITHIN a single dependency)?
B := MAKEFLAGS="-j 6" ./build-domu

LDCONFIG := sudo /sbin/ldconfig

.PHONY: lapp
lapp:  pcre db postfix START_POSTFIX curl
	cd lapp && ln -svf Makefile.XLAPP Makefile
	$(MAKE) -C lapp xlapp

.PHONY:		pcre
pcre:		.guard-b3.18-pcre
.guard-b3.18-pcre:
	$(B) b3.18-pcre
	touch $@ && $(LDCONFIG)

.PHONY:		db
db:		.guard-b3.17-db
.guard-b3.17-db:
	$(B) b3.17-db
	touch $@ && $(LDCONFIG)

.PHONY:		postfix
postfix:	.guard-b3.25-postfix
.guard-b3.25-postfix:
	$(B) b3.25-postfix
	touch $@ && $(LDCONFIG)

.PHONY:		START_POSTFIX
	$(B) b3.30-START_POSTFIX

.PHONY:		curl
curl:		.guard-b3.47-curl
.guard-b3.47-curl:
	$(B) b3.47-curl
	touch $@ && $(LDCONFIG)
