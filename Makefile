PKG_NAME = ocr-fileformat
PKG_VERSION = 0.0.2

CP = cp -r
LN = ln -sf
MV = mv -f
MKDIR = mkdir -p
RM = rm -rfv
ZIP = zip

PREFIX = $(DESTDIR)/usr/local
SHAREDIR = $(PREFIX)/share/$(PKG_NAME)
BINDIR = $(PREFIX)/bin

.PHONY: check \
	install uninstall \
	docs \
	clean realclean \
	release \
	vendor

check:
	$(MAKE) -C vendor check

# TODO
# xslt/hocr__alto2.0.xsl: vendor/hOCR-to-ALTO/hocr2alto2.0.xsl
#     $(LN) ../$< $@

vendor: check
	# download the dependencies
	$(MAKE) -C vendor all
	# copy Alto XSD
	cd xsd && $(LN) ../vendor/alto-schema/*/*.xsd . && \
		for xsd in *.xsd;do \
			target_xsd=`echo $$xsd|sed 's/.//g'|sed 's/-/./'`; \
			if [ ! -e $$target_xsd ];then \
				$(MV) $$xsd $$target_xsd; \
			fi; done
	# copy PAGE XSD
	@cd xsd && $(LN) ../vendor/page-schema/*.xsd .
	# copy ABBYY XSD
	cd xsd && $(LN) ../vendor/abbyy-schema/*.xsd .
	# symlink hocr<->alto
	cd xslt && $(LN) ../vendor/hOCR-to-ALTO/hocr2alto2.0.xsl hocr__alto2.0.xsl
	cd xslt && $(LN) ../vendor/hOCR-to-ALTO/hocr2alto2.1.xsl hocr__alto2.1.xsl
	cd xslt && $(LN) ../vendor/hOCR-to-ALTO/alto2hocr.xsl alto__hocr.xsl

install: vendor $(VENDOR_DIRNAME)
	$(MKDIR) $(SHAREDIR)
	$(CP) -t $(SHAREDIR) xsd xslt vendor lib.sh
	$(MKDIR) $(BINDIR)
	sed '/^SHAREDIR=/c SHAREDIR="$(SHAREDIR)"' bin/ocr-transform.sh > $(BINDIR)/ocr-transform
	sed '/^SHAREDIR=/c SHAREDIR="$(SHAREDIR)"' bin/ocr-validate.sh > $(BINDIR)/ocr-validate
	chmod a+x $(BINDIR)/ocr-transform $(BINDIR)/ocr-validate
	find $(SHAREDIR) -exec chmod u+w {} \;

uninstall:
	$(RM) $(BINDIR)/ocr-transform
	$(RM) $(BINDIR)/ocr-validate
	$(RM) $(SHAREDIR)

clean:
	$(RM) xsd/*

realclean: clean
	$(MAKE) -C vendor clean


release:
	$(RM) $(PKG_NAME)_$(PKG_VERSION)
	$(MKDIR) $(PKG_NAME)_$(PKG_VERSION)
	tar -X .zipignore -cf - . | tar -xf - -C $(PKG_NAME)_$(PKG_VERSION)
	# $(CP) LICENSE Makefile README.md bin/ lib.sh vendor/
	tar czf $(PKG_NAME)_$(PKG_VERSION).tar.gz $(PKG_NAME)_$(PKG_VERSION)
	zip --symlinks -r $(PKG_NAME)_$(PKG_VERSION).zip $(PKG_NAME)_$(PKG_VERSION)

docs:
	mkdir -p docs
	shinclude -d -p src/docs -c xml src/docs/OCR-Comparison.md > docs/OCR-Comparison.md
