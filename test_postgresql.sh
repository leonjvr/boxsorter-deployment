#!/bin/bash

# Load environment variables from .env
if [ -f ".env" ]; then
  while IFS= read -r line; do
    if [[ $line =~ ^TI_DB_USER= ]]; then
      TI_DB_USER="${line#*=}"
    elif [[ $line =~ ^TI_DB_PASSWORD= ]]; then
      TI_DB_PASSWORD="${line#*=}"
    elif [[ $line =~ ^TI_DB_NAME= ]]; then
      TI_DB_NAME="${line#*=}"
    elif [[ $line =~ ^TI_DB_HOST= ]]; then
      TI_DB_HOST="${line#*=}"
    elif [[ $line =~ ^TI_DB_PORT= ]]; then
      TI_DB_PORT="${line#*=}"
    fi
  done < .env
else
  echo ".env not found. Make sure the file exists in the current directory - or copy this script to the folder where .env resides."
  exit 1
fi

# Check if the required environment variables are set
if [ -z "$TI_DB_USER" ] || [ -z "$TI_DB_PASSWORD" ] || [ -z "$TI_DB_NAME" ]; then
  echo "Missing required environment variables in .env. Check the file and ensure it contains TI_DB_USER, TI_DB_PASSWORD, and TI_DB_NAME."
  exit 1
fi

# Get the container ID of the PostgreSQL container
container_id=$(docker ps --filter "ancestor=postgres:13" --format "{{.ID}}")

# Check if the PostgreSQL container is running
if [ -z "$container_id" ]; then
  echo "PostgreSQL container is not running."
  exit 1
fi

# Test PostgreSQL server accessibility
psql_command="docker exec -i $container_id psql -U $TI_DB_USER -d $TI_DB_NAME -h localhost -p 5432"

echo "Testing PostgreSQL server..."
$psql_command -c "SELECT 1;" > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "PostgreSQL server is running and accessible."

  # Check if the database was created
  if $psql_command -c "\l" | grep -q "$TI_DB_NAME"; then
    echo "Database '$TI_DB_NAME' exists. It was successfully created."
  else
    echo "Database '$TI_DB_NAME' does not exist. It was not created."
  fi
else
  echo "Failed to connect to the PostgreSQL server. Check your settings in .env"
fi