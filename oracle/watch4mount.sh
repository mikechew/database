#!/bin/bash
watch 'ps -ef | grep pmon | grep -v grep ; echo ""; echo ""; df -h'
