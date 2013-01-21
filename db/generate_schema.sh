#!/bin/bash

dbicdump -o dump_directory=./lib Ebooksforlib::Schema dbi:mysql:ebok ebok pass
