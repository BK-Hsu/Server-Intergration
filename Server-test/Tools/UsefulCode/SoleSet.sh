#!/bin/bash
SoleUSB30Addr=($(echo ${USB30Addr[@]} | tr ' ' '\n' | sort -u ))
SoleUSB30Addr=$(echo ${SoleUSB30Addr[@]} | sed 's/ /\\|/g' | sed s/\\./\\\\./g)