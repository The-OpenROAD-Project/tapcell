PDN_ROOT:=$(realpath .)

TAPCELL=tapcell

EXTRA_CLEAN+=designs

include common/common.mk

SUBDIRS=$(TAPCELL)

include common/target.mk

designs: coyote vbean

coyote vbean:
	$(BIN)/tapcell test/$@.tcl

test_1: $(SUBDIRS)
	$(BIN)/tapcell test/tapcell.tcl
.PHONY: test
