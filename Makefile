#!/bin/make -f

ifeq ($(DEBTOOL),)
	DEBTOOL = dpkg-buildpackage -rfakeroot
endif

.PHONY: all
all: debs

svgz:
	rm -f svg
	find -iname "*.svg" \
		-exec gzip '{}' \; \
		-exec mv '{}.gz' '{}z' \;
	touch svgz

svg:
	rm -f svg
	find -iname "*.svgz" \
		-exec mv '{}' '{}.gz' \; \
		-exec gunzip '{}.gz' \; \
		-exec rename 's/\.svgz$$/\.svg/' {} \;
	touch svg

gcs:
	@for i in $(dir $(wildcard */gcs)); do \
		cd $$i; \
		echo -n "[*] Building debian files for $$i... "; \
		gcs_build -S || exit; \
		echo "[ OK ]"; \
		cd - > /dev/null; \
	done
	touch gcs

debs: svgz gcs
	@for i in $(dir $(wildcard */gcs)); do \
		cd $$i; \
		echo "[*] Starting build proccess for $$i debian package"; \
		$(DEBTOOL) || exit; \
		echo "Done."; \
		cd - > /dev/null; \
	done
	touch debs

.PHONY: clean
clean: svg
	-rm -f gcs debs svg svgz
	-rm -rf */debian
	-find -iname "*.gcs" -delete
	-rm -f *.build *.dsc *.changes *.tar.gz *.deb

.PHONY: cleanall
cleanall: clean
	-rm -f */gcs/changelog
