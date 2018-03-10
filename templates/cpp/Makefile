CXX = g++									# compiler
CXXFLAGS = -g -Wall -Werror -std=c++11 -MMD			# compiler flags
# CXXFLAGS = -g -Wall -Werror -std=c++11 -MMD -pthread			# compiler flags
MAKEFILE_NAME = ${firstword ${MAKEFILE_LIST}}			# makefile name

OBJECTS1 = folder/file.o			# object files forming executable
EXEC1 = execname									# executable name

OBJECTS2 =  folder/file1.o folder/file2.o   	# object files forming executable
EXEC2 =  execname2        # executable name

OBJECTS3 =            	# object files forming executable
EXEC3 =            # executable name

OBJECTS4 =           			# object files forming executable
EXEC4 =            # executable name

OBJECTS5 =           		# object files forming executable
EXEC5 =            # executable name

OBJECTS = ${OBJECTS1} ${OBJECTS2} ${OBJECTS3} ${OBJECTS4} ${OBJECTS5}
EXECS = ${EXEC1} ${EXEC2} ${EXEC3} ${EXEC4} ${EXEC5}
DEPENDS = ${OBJECTS:.o=.d}							# substitute ".o" with ".d"

.PHONY : all clean

tmux:
	bash -c "echo 'set-option -g mouse on' > ~/.tmux.conf"

run:
	# bash -c "docker pull andrewparadi/uwaterloo:gcc"
	bash -c "docker run -it -v $(shell pwd):/src --entrypoint /bin/bash -w /src andrewparadi/uwaterloo:gcc"

default: a2

${EXEC1} : ${OBJECTS1}								# link step
	${CXX} ${CXXFLAGS} $^ -o $@

${EXEC2} : ${OBJECTS2}								# link step
	${CXX} ${CXXFLAGS} $^ -o $@

${EXEC3} : ${OBJECTS3}								# link step
	${CXX} ${CXXFLAGS} $^ -o $@

${EXEC4} : ${OBJECTS4}								# link step
	${CXX} ${CXXFLAGS} $^ -o $@

${EXEC5} : ${OBJECTS5}								# link step
	${CXX} ${CXXFLAGS} $^ -o $@

${OBJECTS} : ${MAKEFILE_NAME}							# OPTIONAL : changes to this file => recompile

-include ${DEPENDS}								# include *.d files containing program dependences

clean :										# remove files that can be regenerated
	rm -f ${DEPENDS} ${OBJECTS} ${EXECS} *.exec
