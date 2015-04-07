#!/bin/make -f

.SILENT:

DEBTOOL ?= dpkg-buildpackage -rfakeroot
STATUS_CMD ?= git status
PKGNAME = $*
DATE = $(shell date +"%b %d %T")
TMPFILE := $(shell mktemp)
DIFF = git diff --cached
COMMIT = git commit

.PHONY: all status
all: $(patsubst %/gcs,%.build,$(wildcard */gcs))
status:
	$(STATUS_CMD)
notreleased: $(patsubst %/gcs,%/notreleased,$(wildcard */gcs))

%/build: %.build
	$(info [$(DATE)] $(PKGNAME): Finished.)

%.build: %/debian/changelog
	$(info [$(DATE)] $(PKGNAME): starting build process...)
	(cd $(PKGNAME); $(DEBTOOL))
	touch $(PKGNAME).build

%/debian/changelog: %/gcs/info %/svgz
	$(info [$(DATE)] $(PKGNAME): building debian files...)
	(cd $(PKGNAME); gcs_build -S)

%/svgz:
	$(info [$(DATE)] $(PKGNAME): gzipping SVG files...)
	find $(PKGNAME) -iname "*.svg" \
		-exec gzip '{}' \; \
		-exec mv '{}.gz' '{}z' \;

%/svg:
	$(info [$(DATE)] $(PKGNAME): gunzipping SVGZ files...)
	find $(PKGNAME) -iname "*.svgz" \
		-exec mv '{}' '{}.gz' \; \
		-exec gunzip '{}.gz' \; \
		-exec rename 's/\.svgz$$/\.svg/' {} \;

%/clean: %/svg
	$(info [$(DATE)] $(PKGNAME): cleanning useless files...)
	-find $(PKGNAME) -iname "*.gcs" -delete
	-find $(PKGNAME) -iname "*.~?~" -delete
	-rm -rf $(PKGNAME)/debian

%/fullclean: %/clean
	$(info [$(DATE)] $(PKGNAME): removing all output files...)
	-rm -f $(PKGNAME)*.build
	-rm -f $(PKGNAME)*.dsc
	-rm -f $(PKGNAME)*.changes
	-rm -f $(PKGNAME)*.tar.gz
	-rm -f $(PKGNAME)*.deb

%/status: %/notreleased
	$(info ~~~~~ $(PKGNAME) ~~~~~)
	$(STATUS_CMD) $(PKGNAME)

%/notreleased:
	if ! grep -q "($(shell awk '$$1 == "version:" { print $$2 }' $(PKGNAME)/gcs/info))" $(PKGNAME)/gcs/changelog; then \
		echo $(PKGNAME) not released ; \
	fi

%/commit: %/clean
	$(DIFF) $(PKGNAME)/gcs/changelog  | grep '^+.*urgency=' | sed -e 's/\(.* (.*)\).*/\1/g' -e '1s/.*/Released packages:\n&/' | tee $(TMPFILE)
	$(DIFF) $(PKGNAME)/gcs/info | grep "^+" | sed -e 's#+++ \(.*\)/gcs/info.*#\n\1:#g' -e 's#^+version: \(.*\)#(New version: \1)#' -e 's#^+##' | sed '1d' | tee -a $(TMPFILE)
	echo Press [ENTER] to continue or ctrl-c to cancel commit
	read dummy
	$(COMMIT) $(PKGNAME) -F $(TMPFILE)
	-rm -f $(TMPFILE)

commit: clean
	$(DIFF) */gcs/changelog  | grep '^+.*urgency=' | sed -e 's/\(.* (.*)\).*/\1/g' -e 's/^+/    - /g' -e '1s/.*/Released packages:\n&/' | tee $(TMPFILE)
	$(DIFF) */gcs/info | grep "^+" | sed -e 's#+++ \(.*\)/gcs/info.*#\n\1:#g' -e 's#^+version: \(.*\)#(New version: \1)#' -e 's#^+##' | sed '1d' | tee -a $(TMPFILE)
	echo Press [ENTER] to continue or ctrl-c to cancel commit
	read dummy
	$(COMMIT) -F $(TMPFILE)
	-rm -f $(TMPFILE)

.PHONY: clean
clean: $(patsubst %/gcs,%/clean,$(wildcard */gcs))

.PHONY: fullclean
fullclean: $(patsubst %/gcs,%/fullclean,$(wildcard */gcs)) clean

