

# git clone -b mt76x2u  https://github.com/LorenzoBianconi/mt76.git SRC_DIR

#Manual Insert
#sudo insmod SRC_DIR/mt76.ko
#sudo insmod SRC_DIR/mt76-usb.ko
#sudo insmod SRC_DIR/mt76x2-common.ko
#sudo insmod SRC_DIR/mt76x2u.ko

#Manual remove
#sudo rmmod mt76x2u mt76x2-common mt76-usb mt76

MAKE = make

LINUX_SRC = /lib/modules/$(shell uname -r)/build
LINUX_SRC_MODULE = /lib/modules/$(shell uname -r)/kernel/drivers/net/wireless
CROSS_COMPILE =

#mt76x2u_testing
SRC=src
BRANCH=mt76x2u
COMMIT=1101f7fb42d894b78419b4b0d60773df44a497cd
ROOT_DIR=$(shell pwd)
PATCH_DIR=$(ROOT_DIR)/patches
SRC_DIR=$(ROOT_DIR)/$(SRC)

MAKE_OPTS =EXTRA_CFLAGS+="-I$(SRC_DIR)"

export LINUX_SRC CROSS_COMPILE  LINUX_SRC_MODULE  EXTRA_CFLAGS

# The targets that may be used.
PHONY += all clean uninstall install debug release getsrc patch_apply testlistfile

all: release


release: patch_apply   
	@echo ""
	@echo "*** Building driver without debug messages ***"
	@echo ""
	$(MAKE) -C $(LINUX_SRC) $(MAKE_OPTS)  SUBDIRS=$(SRC_DIR) modules

debug: patch_apply
	export DBGFLAGS
	@echo ""
	@echo "*** Building driver with debug messages ***"
	@echo ""
	#rm -rvf $(SRC_DIR)
	#git clone -b mt76x2u  https://github.com/LorenzoBianconi/mt76.git subdir
	#patch -d$(SRC_DIR)  -p1 < $(ROOT_DIR)/fix.patch
	$(MAKE) -C $(LINUX_SRC) DBGFLAGS=-DDBG $(MAKE_OPTS)  SUBDIRS=$(SRC_DIR)  modules

install: release
	-rmmod mt76x2u mt76x2-common mt76-usb mt76
	rm -frv $(LINUX_SRC_MODULE)/mt76*.ko
	cp -pRv  $(ROOT_DIR)/firmware/* /lib/firmware/
	install -d $(LINUX_SRC_MODULE)
	install -m 644 -c  $(SRC_DIR)/mt76.ko\
			   $(SRC_DIR)/mt76-usb.ko\
			   $(SRC_DIR)/mt76x2-common.ko\
			   $(SRC_DIR)/mt76x2u.ko  \
							$(LINUX_SRC_MODULE)
	/sbin/depmod -a ${shell uname -r}

uninstall:
	rm -frv $(LINUX_SRC_MODULE)/mt76*.ko
	rm -frv /lib/firmware/mt7662u*
	/sbin/depmod -a ${shell uname -r}


getsrc:
	if [ ! -d "$(SRC_DIR)" ]; then \
	   git clone -b $(BRANCH)  https://github.com/LorenzoBianconi/mt76.git $(SRC) ;\
	   cd  $(SRC) ;\
	   git checkout $(COMMIT) ;\
	   cd - ;\
	fi

patch_apply: getsrc
	#https://stackoverflow.com/questions/20121805/shell-conditional-in-makefile?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
	#https://unix.stackexchange.com/questions/55780/check-if-a-file-or-folder-has-been-patched-already?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
	#https://stackoverflow.com/questions/47358120/how-to-pass-for-loop-variable-to-shell-function-in-makefile?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa	
	for patchfile in  $(PATCH_DIR)/* ; do \
	echo $$patchfile ;\
	if [ -f $${patchfile} ]; then \
	if ! patch -d$(SRC_DIR)  -R -p1 -s -f --dry-run < $${patchfile} ; then\
	   	patch -d$(SRC_DIR) -p1 < $${patchfile} ;\
	fi ;\
	fi ;\
	done
	#if ! patch -d$(SRC_DIR)  -R -p1 -s -f --dry-run < $(ROOT_DIR)/fix.patch ; then\
	#   	patch -d$(SRC_DIR) -p1 < $(ROOT_DIR)/fix.patch ;\
	#fi
	#if ! patch -d$(SRC_DIR)  -R -p1 -s -f --dry-run < $(ROOT_DIR)/fix1.patch ; then\
	#   	patch -d$(SRC_DIR) -p1 < $(ROOT_DIR)/fix1.patch ;\
	#fi
	#if ! patch -d$(SRC_DIR)  -R -p1 -s -f --dry-run < $(ROOT_DIR)/fix2.patch ; then\
	#   	patch -d$(SRC_DIR) -p1 < $(ROOT_DIR)/fix2.patch ;\
	#fi
	#rm -rvf $(SRC_DIR)
	#https://stackoverflow.com/questions/59838/check-if-a-directory-exists-in-a-shell-script
		
testlistfile:
	#https://stackoverflow.com/questions/20121805/shell-conditional-in-makefile?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
	#https://unix.stackexchange.com/questions/55780/check-if-a-file-or-folder-has-been-patched-already?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
	for patchfile in  $(PATCH_DIR)/* ; do \
	echo $$patchfile ;\
	done
clean:
	rm -frv $(SRC_DIR)/*.o \
		$(SRC_DIR)/*.ko \
		$(SRC_DIR)/.*.cmd\
		$(SRC_DIR)/.tmp_versions\
		$(SRC_DIR)/*.symvers\
		$(SRC_DIR)/*.order

# Declare the contents of the .PHONY variable as phony.  We keep that
# information in a variable so we can use it in if_changed and friends.
.PHONY: $(PHONY)




