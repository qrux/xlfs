# How to fix this build parallelization (parallel-compiles WITHIN a single dependency)?
CPU_COUNT :=			$(shell cat /proc/cpuinfo | grep -w "^processor" | wc -l)
B :=				MAKEFLAGS="-j $(CPU_COUNT)" ./build-domu
SUDO :=				$(shell which sudo)
LDCONFIG_BIN :=			$(shell which ldconfig)
UID :=				$(shell id -u)

LDCONFIG := /usr/bin/sudo /sbin/ldconfig

########################################################################
# mail
########################################################################

.PHONY:	all
all:
	@echo
	@echo "Available targets:"
	@echo "  lapp         lapp-clean"
	@echo "  nameserver   nameserver-clean"
	#@echo "  mail         mail-clean"
	@echo

.PHONY: verify
verify:
	@if [ 0 = $(UID) ] ; then echo ; echo "  Cannot run as root; log in as BLFS user." ; echo ; exit 1 ; fi

.PHONY: mail
mail:	verify pcre db postgresql dovecot postfix alpine START_POSTFIX START_DOVECOT libbsd sendmail opendkim

.PHONY:	libbsd
libbsd:	.libbsd
.libbsd:
	$(B) b3*-libbsd
	touch $@ && $(LDCONFIG)

.PHONY:	sendmail
sendmail: .sendmail
.sendmail:
	$(B) b3*-sendmail
	touch $@ && $(LDCONFIG)

.PHONY: opendkim
opendkim: .opendkim
.opendkim:
	$(B) b3*-opendkim
	touch $@ && $(LDCONFIG)

.PHONY: sqlite
sqlite:	.sqlite
.sqlite:
	$(B) b3*-sqlite
	touch $@ && $(LDCONFIG)

.PHONY:	postgresql
postgresql: .postgresql
.postgresql:
	$(B) b3*-postgresql
	touch $@ && $(LDCONFIG)

.PHONY:	dovecot
dovecot: .dovecot
.dovecot:
	$(B) b3*-dovecot
	touch $@ && $(LDCONFIG)

.PHONY:		START_DOVECOT
START_DOVECOT:	.start_dovecot
.start_dovecot:
	$(B) b3*-START_DOVECOT
	touch $@ && $(LDCONFIG)

.PHONY:	alpine
alpine: .alpine
.alpine:
	$(B) b3*-postfix
	touch $@ && $(LDCONFIG)

########################################################################
# nameserver
########################################################################

.PHONY:	nameserver
nameserver: verify .guard-b3.05-PERL_NET_TOOLS .guard-b3.10-bind .guard-b3.11-START_BIND

.guard-b3.05-PERL_NET_TOOLS:
	$(B) b3.05-PERL_NET_TOOLS
	touch $@ && $(LDCONFIG)

.guard-b3.10-bind:
	$(B) b3.10-bind
	touch $@ && $(LDCONFIG)

.guard-b3.11-START_BIND:
	$(B) b3.11-START_BIND
	touch $@ && $(LDCONFIG)

.PHONY: nameserver-clean
nameserver-clean:
	rm -vf .guard-b3.05-PERL_NET_TOOLS .guard-b3.10-bind .guard-b3.11-START_BIND

########################################################################
# lapp
########################################################################

.PHONY: lapp-clean
lapp-clean:
	rm -vf .guard-b3.18-pcre .guard-b3.17-db .guard-b3.25-postfix .guard-b3.47-curl
	$(MAKE) -C lapp clean

.PHONY: lapp
lapp:  verify pcre db postgresql postfix START_POSTFIX apr apr-util curl
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
START_POSTFIX:	.guard-b3.30-START_POSTFIX
.guard-b3.30-START_POSTFIX:
	$(B) b3.30-START_POSTFIX
	touch $@ && $(LDCONFIG)

.PHONY:		apr
apr:		.guard-b3.35-apr
.guard-b3.35-apr:
	$(B) b3.35-apr
	touch $@ && $(LDCONFIG)

.PHONY:		apr-util
apr-util:	.guard-b3.36-apr-util
.guard-b3.36-apr-util:
	$(B) b3.36-apr-util
	touch $@ && $(LDCONFIG)
	
.PHONY:		curl
curl:		.guard-b3.47-curl
.guard-b3.47-curl:
	$(B) b3.47-curl
	touch $@ && $(LDCONFIG)
