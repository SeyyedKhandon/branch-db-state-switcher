#!/bin/bash

VERSION=1.0
# branchDBSwitcher v1.0
# This script is used to backup and restore the database inside the docker image based on the branch name.
# The script is intended to be used in the context of the a project which uses postgresql inside the docker without password on your laptop. So if you want to use it for your project, you may need to adjust the variables "DOCKER_IMAGE_NAME, DB_NAME, DB_USER" accordingly.
# Available actions: list, backup, restore, delete, delete-all
# Usage: ./branchDBSwitcher.sh <action_type> [backup_name]

# Example -list all backups: "./branchDBSwitcher.sh list"

# Example1- automatic backup based on current branch name: "./branchDBSwitcher.sh backup"
# Example1- automatic restore based on current branch name: "./branchDBSwitcher.sh restore"

# Example2- manual backup: "./branchDBSwitcher.sh backup myBackup"
# Example2- manual restore: "./branchDBSwitcher.sh restore myBackup"

# Example3- automatic delete based on current branch name: "./branchDBSwitcher.sh delete"

# Example3- manual delete: "./branchDBSwitcher.sh delete myBackup"

# Example4- delete all backups: "./branchDBSwitcher.sh delete-all"


ACTION_TYPE=$1
if [ -z "$ACTION_TYPE" ]; then
  echo "Please provide an action type as the first argument(version, backup, restore, list)."
  exit
fi


# Check if the second argument is provided
if [ -z "$2" ]; then
    # If not provided, generate backup name based on branch name
    BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD | sed 's|/|_|g')"
else
    # If provided, use the second argument as the backup name
    BRANCH_NAME=$2
fi

echo "Do you want to run '$ACTION_TYPE' process for your DB on '$BRANCH_NAME' branch? (y/n)"
read answer
if [ "$answer" = "y" ]; then
echo "===================================================================="
echo "Starting database $ACTION_TYPE process on the docker image itself"
echo "===================================================================="
else
  echo "Exiting..."
  exit
fi


DOCKER_IMAGE_NAME="you docker image name that runs the database"
DB_NAME="your database's name"
DB_USER="your database's username"
BACKUP_DIR="/dbBackupsBasedOnBranchName"
BACKUP_NAME="$BRANCH_NAME.psql"
echo "-------Variables:-------"
echo "Image name: '$DOCKER_IMAGE_NAME'"
echo "Database name: '$DB_NAME'"
echo "Database username: '$DB_USER'"
echo "Backup directory: '$BACKUP_DIR'"
echo "Backup name: '$BACKUP_NAME'"
echo "------------------------"

# Test the connection and variable substitution
echo "Testing connection to the database:"
docker exec -it $DOCKER_IMAGE_NAME bash -c "psql -U $DB_USER -d $DB_NAME -c 'SELECT version();'" | awk '/PostgreSQL/ {print $0}'
echo "------------------------"


# Check if the backup directory already exists inside the container
if ! docker exec $DOCKER_IMAGE_NAME [ -d $BACKUP_DIR ]; then
    echo "Creating backup directory inside the container..."
    # Attempt to create the directory
    if docker exec $DOCKER_IMAGE_NAME mkdir -p $BACKUP_DIR; then
        echo "Backup directory '$BACKUP_DIR' created successfully."
    else
        echo "Failed to create backup directory."
    fi
    echo "------------------------"
fi



# Perform the backup or restore operation
# Check the action type: list, backup, restore, delete, delete-all
if [ "$ACTION_TYPE" == "version" ]; then
    echo "Branch database state switcher v$VERSION"
elif [ "$ACTION_TYPE" == "list" ]; then
    # Perform list all backups operation
    echo "$BACKUP_DIR:"
    if docker exec -t $DOCKER_IMAGE_NAME bash -c "ls -la $BACKUP_DIR"; then
        echo "Listed all backups successfully."
    else 
        echo "Failed to list all backups inside the container."
    fi
elif [ "$ACTION_TYPE" == "backup" ]; then
    # Perform backup operation
    if docker exec -t $DOCKER_IMAGE_NAME bash -c "pg_dump -Fc -U $DB_USER -d $DB_NAME > $BACKUP_DIR/$BACKUP_NAME"; then
        echo "Backup process completed successfully inside docker at '$BACKUP_DIR/$BACKUP_NAME'."
    else
        echo "Failed to create backup file inside docker."
    fi
elif [ "$ACTION_TYPE" == "restore" ]; then
    # Perform restore operation
    # First, drop all tables in the database
if docker exec -t $DOCKER_IMAGE_NAME bash -c "psql -U $DB_USER -d $DB_NAME -t <<EOF | psql -U $DB_USER -d $DB_NAME
SELECT 'DROP TABLE IF EXISTS \"' || tablename || '\" CASCADE;' FROM pg_tables WHERE schemaname = 'public';
EOF" > /dev/null 2>&1  && docker exec -t $DOCKER_IMAGE_NAME bash -c "psql -U $DB_USER -d $DB_NAME -c 'SET session_replication_role = replica;'" > /dev/null 2>&1; then

    echo "Dropped all tables inside the database."

    if docker exec -t $DOCKER_IMAGE_NAME bash -c "pg_restore --clean --if-exists -U $DB_USER -d $DB_NAME $BACKUP_DIR/$BACKUP_NAME" > /dev/null 2>&1 && docker exec -t $DOCKER_IMAGE_NAME bash -c "psql -U $DB_USER -d $DB_NAME -c 'SET session_replication_role = DEFAULT;'" > /dev/null 2>&1; then
    echo "Restore process completed successfully inside docker from '$BACKUP_DIR/$BACKUP_NAME'."
    else
        echo "Failed to restore backup file or re-enable FK checks."
    fi
else
    echo "Failed to drop tables inside the database for a clean restore."
fi
elif [ "$ACTION_TYPE" == "delete" ]; then
    # Perform delete specific backup operation
    if docker exec -t $DOCKER_IMAGE_NAME bash -c "rm $BACKUP_DIR/$BACKUP_NAME"; then
        docker exec -t $DOCKER_IMAGE_NAME bash -c "ls -la $BACKUP_DIR"
        echo "Deleted backup '$BACKUP_DIR/$BACKUP_NAME' inside the container."
    else 
        echo "Failed to delete backup '$BACKUP_DIR/$BACKUP_NAME' inside the container."
    fi
elif [ "$ACTION_TYPE" == "delete-all" ]; then
    # Perform delete all backups operation
    if docker exec -t $DOCKER_IMAGE_NAME bash -c "rm -R $BACKUP_DIR"; then
        echo "Deleted all backups inside the container."
    else 
        echo "Failed to delete all backups inside the container."
    fi
else 
    # Handle invalid action type
    echo "Invalid action type. Please provide either 'list', 'backup', 'restore', 'delete', or 'delete-all' as the first argument."
fi