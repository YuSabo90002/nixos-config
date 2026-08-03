KDIR ?= /lib/modules/$(shell uname -r)/build

obj-m := hori_truck_wheel.o

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) clean
