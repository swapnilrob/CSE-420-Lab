#!/bin/bash

yacc -d -y --debug --verbose 22299138_22299142.y
echo 'Generated the parser C file as well the header file'
g++ -w -c -o y.o y.tab.c
echo 'Generated the parser object file'
flex 22299138_22299142.l
echo 'Generated the scanner C file'
g++ -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ y.o l.o -o a.out
echo 'All ready, running'
./a.out input.c
echo 'logfile'
cat 22299138_22299142_log.txt
echo 'errorfile'
cat 22299138_22299142_error.txt
