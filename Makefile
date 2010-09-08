#!/bin/make -f

.SILENT:

DEBTOOL ?= dpkg-buildpackage -rfakeroot
PKGNAME = $*
DATE = $(shell date +"%b %d %T")

.PHONY: all
all: $(patsubst %/gcs,%.build,$(wildcard */gcs))

%.build: %/svgz %/debian/changelog
	$(info [$(DATE)] $(PKGNAME): starting build process...)
	(cd $(PKGNAME); $(DEBTOOL))
	touch $(PKGNAME).build

%/debian/changelog: %/gcs/info
	$(info [$(DATE)] $(PKGNAME): building debian files...)
	(cd $(PKGNAME); gcs_build -S)

%/svgz:
	$(info [$(DATE)] $(PKGNAME): gzipping SVG files...)
	find $(PKGNAME) -iname "*.svg" \
		-exec gzip '{}' \; \
		-exec mv '{}.gz' '{}z' \;

svg:
	find -iname "*.svgz" \
		-exec mv '{}' '{}.gz' \; \
		-exec gunzip '{}.gz' \; \
		-exec rename 's/\.svgz$$/\.svg/' {} \;

.PHONY: clean
clean: svg
	-find -iname "*.gcs" -delete
	-rm -rf */debian
	-rm -f *.build *.dsc *.changes *.tar.gz *.deb

.PHONY: realclean
realclean: clean
	-rm -f */gcs/changelog

