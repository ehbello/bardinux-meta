#!/bin/make -f

ifeq ($(DEBTOOL),)
	DEBTOOL = dpkg-buildpackage -rfakeroot
endif

.PHONY: all
all: debs

.PHONY: gcs
gcs:
	@for i in $(dir $(wildcard */gcs)); do \
		cd $$i; \
		echo -n "[*] Building debian files for $$i... "; \
		gcs_build -S || exit; \
		echo "[ OK ]"; \
		cd - > /dev/null; \
	done

.PHONY: debs
debs: gcs
	@for i in $(dir $(wildcard */gcs)); do \
		cd $$i; \
		echo "[*] Starting build proccess for $$i debian package"; \
		$(DEBTOOL) || exit; \
		echo "Done."; \
		cd - > /dev/null; \
	done

.PHONY: clean
clean:
	-rm -rf */debian
	-find -iname "*.gcs" -delete
	-rm -f *.build *.dsc *.changes *.tar.gz *.deb

.PHONY: cleanall
cleanall: clean
	-rm -f */gcs/changelog
