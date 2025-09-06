#!/bin/bash
# sed-i-test.sh
# 2025.09.04

echo
echo "Testing sed -i using /config as the parent directory..."
echo

# create a temporary file
echo "failed" > /config/sedtest.txt

# try sed -i substitution
sed -i 's/failed/passed/' /config/sedtest.txt

# check the contents
cat /config/sedtest.txt

# removing file
rm /config/sedtest.txt

echo
echo "Testing sed -i using /tmp as the parent directory..."
echo

# create a temporary file
echo "failed" > /tmp/sedtest.txt

# try sed -i substitution
sed -i 's/failed/passed/' /tmp/sedtest.txt

# check the contents
cat /tmp/sedtest.txt

# removing file
rm /tmp/sedtest.txt
echo
