##### Configuring stuff

SERVER_EXEC_NAME:=rethinkdb
START_DB_DIR:=scripts
START_DB_NAME:=start_rethinkdb
TAGS:=.tags

# Default DEBUG variable to "on".  This should be changed on a release branch.
DEBUG?=1

VERBOSE?=0

# Choose our directories
SOURCE_DIR:=src
BUILD_ROOT_DIR:=build
ifeq (${DEBUG},1)
BUILD_DIR:=$(BUILD_ROOT_DIR)/debug
else
BUILD_DIR:=$(BUILD_ROOT_DIR)/release
endif
DEP_DIR:=$(BUILD_DIR)/dep
OBJ_DIR:=$(BUILD_DIR)/obj

# Define configuration variables
CXX:=g++
LDFLAGS:=-lrt -laio
CXXFLAGS:=-I$(SOURCE_DIR) -Wall -Wextra -Wformat=2 -Wno-unused-parameter -Werror

# Configure debug vs. release
ifeq ($(DEBUG),1)
CXXFLAGS:=$(CXXFLAGS) -g -DDELETE_DEBUG
else
CXXFLAGS:=$(CXXFLAGS) -O3 -DNDEBUG
endif
ifdef VALGRIND
CXXFLAGS+=-DVALGRIND
endif

# Should makefile be noisy?
ifeq ($(VERBOSE),1)
QUIET:=
else
QUIET:=@
endif



##### Finding what to build

SOURCES:=$(shell find $(SOURCE_DIR) -name \*.cc)
NAMES:=$(patsubst $(SOURCE_DIR)/%.cc,%,$(SOURCES))
DEPS:=$(patsubst %,$(DEP_DIR)/%.d,$(NAMES))
OBJS:=$(patsubst %,$(OBJ_DIR)/%.o,$(NAMES))



##### Build targets

# High level build targets
$(BUILD_DIR)/$(SERVER_EXEC_NAME): $(OBJS) $(BUILD_DIR)
ifeq ($(VERBOSE),0)
	@echo "    LD $@"
endif
	$(QUIET) $(CXX) $(LDFLAGS) $(OBJS) -o $(BUILD_DIR)/$(SERVER_EXEC_NAME)
	$(QUIET) cp $(START_DB_DIR)/$(START_DB_NAME) $(BUILD_DIR)/$(START_DB_NAME)

tags:
	$(QUIET) ctags -R -f $(TAGS)

style:
	$(QUIET) find . -name \*.cc -o -name \*.hpp | xargs ../scripts/cpplint --verbose 2 --filter=-whitespace/end_of_line,-whitespace/parens,-whitespace/line_length,-readability/casting,-whitespace/braces,-readability/todo,-legal/copyright,-whitespace/comments,-build/include,-whitespace/labels,-runtime/int,-runtime/printf 2>&1 | grep -v Done\ processing

clean:
ifeq ($(VERBOSE),0)
	@echo "    RM *~"
	@echo "    RM -r $(BUILD_ROOT_DIR)"
	@echo "    RM $(TAGS)"
endif
	$(QUIET) find -name '*~' -exec rm {} \;
	$(QUIET) rm -r $(BUILD_ROOT_DIR)
	$(QUIET) rm -f $(TAGS)

# Directories
$(BUILD_DIR):
	$(QUIET) mkdir -p $(BUILD_DIR)

# Object files
$(OBJ_DIR)/%.o: $(SOURCE_DIR)/%.cc Makefile
	$(QUIET) mkdir -p $(dir $@)
ifeq ($(VERBOSE),0)
	@echo "    CC $< -o $@"
endif
	$(QUIET) $(CXX) $(CXXFLAGS) -c -o $@ $<

# Dependencies
$(DEP_DIR)/%.d: $(SOURCE_DIR)/%.cc
	$(QUIET) mkdir -p $(dir $@)
	$(QUIET) $(CXX) $(CXXFLAGS) -M $< > $@.$$$$;				   \
	sed 's,\($*\)\.o[ :]*,$(OBJ_DIR)/\1.o $@ : ,g' < $@.$$$$ > $@;	  \
	rm -f $@.$$$$
# Include the dependencies into the makefile so that they take effect
-include $(DEPS)
