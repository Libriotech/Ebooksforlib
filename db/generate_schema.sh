#!/bin/bash

dbicdump -o dump_directory=./lib -o components='["InflateColumn::DateTime"]' Ebooksforlib::Schema dbi:mysql:ebok ebok pass
