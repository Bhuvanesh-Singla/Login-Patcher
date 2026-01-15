#!/bin/bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

#Create incoming_keys directory
mkdir -p ~/incoming_keys

# Install gatekeeper.sh and create_students.sh in home directory
cp gatekeeper.sh ~/gatekeeper.sh
cp create_students.sh ~/create_students.sh

chmod +x ~/gatekeeper.sh
chmod +x ~/create_students.sh