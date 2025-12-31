#!/bin/bash

# Enable strict error handling and safer script execution
# set -e: Exit immediately if any command exits with a non-zero status
# set -u: Treat unset variables as an error and exit immediately
# set -o pipefail: Ensure pipeline failures are captured (if any command in a pipe fails, the whole pipe fails)
set -euo pipefail

# Guacamole Stack Setup Script
# This script prepares the necessary directories and initializes the database schema
# for a Guacamole (Apache Guacamole remote desktop gateway) Docker deployment.

# Check if Docker daemon is running
# Docker ps command will fail if the daemon is not available
if ! (docker ps >/dev/null 2>&1); then
	# Inform user and exit if Docker is not running
	echo "Docker daemon not running, will exit here!"
	exit 1
fi

# ------------------------------------------------------------------------------
# Step 1: Prepare database initialization directory and generate init SQL script
# ------------------------------------------------------------------------------
echo "Preparing folder init and creating /home/docker/guacamole_stack/db/init/initdb.sql"

# Create the directory for database initialization scripts if it doesn't exist
# Using -p to create parent directories as needed, suppressing output
mkdir -p /home/docker/guacamole_stack/db/init >/dev/null 2>&1

# Run the Guacamole container to generate the MySQL database initialization script
# --rm: Remove container after execution
# 'guacamole/guacamole:1.6.0': Specific version of Guacamole for consistency
# The initdb.sh script generates SQL for the specified database type (MySQL)
docker run --rm 'guacamole/guacamole:1.6.0' /opt/guacamole/bin/initdb.sh --mysql >/home/docker/guacamole_stack/db/init/initdb.sql

echo "done"

# ------------------------------------------------------------------------------
# Step 2: Prepare recording directory with appropriate permissions
# ------------------------------------------------------------------------------
echo "Preparing folder record and setting permissions"

# Create directory for Guacamole session recordings
# -p: Create parent directories as needed
# -m 0775: Set permissions (read/write/execute for owner and group, read/execute for others) initially
# This ensures the Docker container can write recordings regardless of user
mkdir -p -m 0775 /home/docker/guacamole_stack/guacamole/record >/dev/null 2>&1

echo "done"

# ------------------------------------------------------------------------------
# Step 3: Set appropriate permissions for the entire Guacamole stack directory
# ------------------------------------------------------------------------------
# Recursively set permissions to 0775 (rwxrwxr-x) for the main directory
# This allows owner and group full access, others read and execute access
chmod -R 0775 /home/docker/guacamole_stack
