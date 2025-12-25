#!/bin/bash
chmod +x start.sh
chmod +x build.sh
./build.sh
./start.sh &> /dev/null &
