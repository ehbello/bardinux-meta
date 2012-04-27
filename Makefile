#!/bin/make -f

.SILENT:

DEBTOOL ?= dpkg-buildpackage -rfakeroot
PKGNAME = $*
DATE = $(shell date +"%b %d %T")
TMPFILE := $(shell mktemp)

.PHONY: all status
all: $(patsubst %/gcs,%.build,$(wildcard */gcs))
status: $(patsubst %/gcs,%/status,$(wildcard */gcs))

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

%/realclean: %/clean
	$(info [$(DATE)] $(PKGNAME): removing all output files...)
	-rm -f $(PKGNAME)*.build
	-rm -f $(PKGNAME)*.dsc
	-rm -f $(PKGNAME)*.changes
	-rm -f $(PKGNAME)*.tar.gz
	-rm -f $(PKGNAME)*.deb

%/status:
	$(info ~~~~~ $(PKGNAME) ~~~~~)
	bzr st $(PKGNAME)

%/commit:
	bzr diff $(PKGNAME)/gcs/changelog  | grep '^+.*urgency=' | sed -e 's/\(.* (.*)\).*/\1/g' -e '1s/.*/Released packages:\n&/' | tee $(TMPFILE)
	bzr diff $(PKGNAME)/gcs/info | grep "^+" | sed -e 's#+++ \(.*\)/gcs/info.*#\n\1:#g' -e 's#^+version: \(.*\)#(New version: \1)#' -e 's#^+##' | sed '1d' | tee -a $(TMPFILE)
	#read -p "Do you want to commit? [y/N] " answer
	bzr ci $(PKGNAME) -F $(TMPFILE)
	-rm -f $(TMPFILE)

commit:
	bzr diff */gcs/changelog  | grep '^+.*urgency=' | sed -e 's/\(.* (.*)\).*/\1/g' -e 's/^+/    - /g' -e '1s/.*/Released packages:\n&/' | tee $(TMPFILE)
	bzr diff */gcs/info | grep "^+" | sed -e 's#+++ \(.*\)/gcs/info.*#\n\1:#g' -e 's#^+version: \(.*\)#(New version: \1)#' -e 's#^+##' | sed '1d' | tee -a $(TMPFILE)
	#read -p "Do you want to commit? [y/N] " answer
	bzr ci -x Makefile -F $(TMPFILE)
	-rm -f $(TMPFILE)

.PHONY: clean
clean: $(patsubst %/gcs,%/clean,$(wildcard */gcs))

.PHONY: realclean
realclean: $(patsubst %/gcs,%/realclean,$(wildcard */gcs)) clean

