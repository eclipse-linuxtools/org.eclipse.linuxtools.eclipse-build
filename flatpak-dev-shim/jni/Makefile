ifeq ($(JAVA_HOME),)
$(error Please define JAVA_HOME)
endif

CC=gcc

OUT_DIR=../target

GENERATED_HEADERS=java_lang_FlatpakProcessImpl.h
OBJECTS=FlatpakProcessImpl.o
LIBRARY=$(OUT_DIR)/libflatpakdevshim.so

CFLAGS += -fPIC -D_REENTRANT -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux $(shell pkg-config --cflags glib-2.0 gio-unix-2.0)
LDFLAGS += $(shell pkg-config --libs glib-2.0 gio-unix-2.0)

java_lang_FlatpakProcessImpl.h:
	$(JAVA_HOME)/bin/javac -h . -d $(OUT_DIR)/native --patch-module=java.base=../src/main/java ../src/main/java/java/lang/FlatpakProcessImpl.java

$(OBJECTS): %.o : %.c $(GENERATED_HEADERS)
	$(CC) -c $(CFLAGS) -o $@ $<

$(LIBRARY) : FlatpakProcessImpl.o
	$(CC) $(LDFLAGS) -shared -o $@ $^

all: $(LIBRARY)

clean:
	$(RM) $(OBJECTS) $(GENERATED_HEADERS)

rebuild: clean all
