#!/bin/bash

# Branch Database State Switcher 
VERSION=1.0


# ---------------------------------------------------------------------- #
# Check if the first argument is provided
# ---------------------------------------------------------------------- #
ACTION_TYPE=$1
if [ -z "$ACTION_TYPE" ]; then
  echo "Please provide an action type as the first argument(version, backup, restore, list)."
  echo "Refer to the readme.md for more information."
  echo "Exiting from 'Branch Database State Switcher v$VERSION...'"
  exit
fi

# ---------------------------------------------------------------------- #
# Check script version via switches "--version" or "-v"
# ---------------------------------------------------------------------- #
if [ "$ACTION_TYPE" == "-v" ] || [ "$ACTION_TYPE" == "--version" ]; then
    echo "Branch database state switcher v$VERSION"
    exit
fi

# ---------------------------------------------------------------------- #
# Check if current directory is a git repository
# ---------------------------------------------------------------------- #
if ! git rev-parse --is-inside-work-tree > /dev/null; then
    echo "Current directory is not a git repository."
    echo "Please run the script inside a git repository."
    echo "Exiting from 'Branch Database State Switcher v$VERSION...'"
    exit
fi


# ---------------------------------------------------------------------- #
# Check if config file is present, otherwise ask the user to create it
# ---------------------------------------------------------------------- #
if [ ! -f "./bds.config" ]; then
    echo "Config file 'bds.config' not found."
    echo "Please create a config file with the following variables:"
    echo "DOCKER_IMAGE_NAME='your docker image name that runs the database'"
    echo "DB_NAME='your database's name'"
    echo "DB_USER='your database's username'"
    echo "DB_PASSWORD='your database's password'"
    echo "Exiting from 'Branch Database State Switcher v$VERSION...'"
    exit
fi

# Load variables from the bds.config file
DOCKER_IMAGE_NAME=$(grep DOCKER_IMAGE_NAME ./bds.config | cut -d '=' -f2)
DB_NAME=$(grep DB_NAME ./bds.config | cut -d '=' -f2)
DB_USER=$(grep DB_USER ./bds.config | cut -d '=' -f2)
DB_PASSWORD=$(grep DB_PASSWORD ./bds.config | cut -d '=' -f2)
echo ""
echo "--------- Configuration on './bds.config' ---------"
echo "Image name: '$DOCKER_IMAGE_NAME'"
echo "Database name: '$DB_NAME'"
echo "Database username: '$DB_USER'"
echo "Database password: '$DB_PASSWORD'"
echo "------------------------"
echo ""


# ---------------------------------------------------------------------- #
# Check if the docker image is running
# ---------------------------------------------------------------------- #
if ! docker ps | grep $DOCKER_IMAGE_NAME > /dev/null; then
    echo "Docker image '$DOCKER_IMAGE_NAME' is not running."
    echo "Please start the docker image and try again."
    echo "Exiting from 'Branch Database State Switcher v$VERSION...'"
    exit
fi

# ---------------------------------------------------------------------- #
# Check if the database is accessible
# ---------------------------------------------------------------------- #
if ! docker exec $DOCKER_IMAGE_NAME psql -U $DB_USER -d $DB_NAME -c "SELECT version();" > /dev/null; then
    echo "Failed to connect to the database."
    echo "Please check the database name and user in the config file."
    echo "Exiting from 'Branch Database State Switcher v$VERSION...'"
    exit
fi


# ---------------------------------------------------------------------- #
# Check if the BACKUP_DIR is present inside the container
# ---------------------------------------------------------------------- #
BACKUP_DIR="/branched_db_backups"
if ! docker exec $DOCKER_IMAGE_NAME [ -d $BACKUP_DIR ]; then
    if docker exec $DOCKER_IMAGE_NAME mkdir -p $BACKUP_DIR; then
        echo "Backup directory '$BACKUP_DIR' created successfully."
    else
        echo "Failed to create backup directory."
    fi
fi
echo "Backup directory: '$BACKUP_DIR'"

# ---------------------------------------------------------------------- #
# Check if the BACKUP_NAME name is provided as the second argument
# ---------------------------------------------------------------------- #
if [ "$ACTION_TYPE" == "backup" ] || [ "$ACTION_TYPE" == "restore" ] || [ "$ACTION_TYPE" == "delete" ]; then
    if [ -z "$2" ]; then
        # If not provided, generate backup name based on branch name
        BACKUP_NAME="$(git rev-parse --abbrev-ref HEAD | sed 's|/|_|g')"
    else
        # If provided, use the second argument as the backup name
        BACKUP_NAME=$2
    fi
fi
echo "Backup name: '$BACKUP_NAME'"



# ---------------------------------------------------------------------- #
# List all backups inside the container
# ---------------------------------------------------------------------- #
if [ "$ACTION_TYPE" == "--list" ] || [ "$ACTION_TYPE" == "-l" ]; then
    # Perform list all backups operation
    echo "$BACKUP_DIR:"
    if output=$(docker exec -t $DOCKER_IMAGE_NAME bash -c "ls -l $BACKUP_DIR" 2>&1); then
    echo "$output"
    else 
    echo "Failed to list all backups inside the container. Error: $output"
    fi
exit
fi

# ---------------------------------------------------------------------- #
# Ask the user to confirm the action
# ---------------------------------------------------------------------- #
echo ""
echo "Do you want to run '$ACTION_TYPE' process for your DB on '$BACKUP_NAME' branch? (y/n)"
echo ""
read answer
if [ "$answer" = "y" ]; then
echo "===================================================================="
echo "Starting database $ACTION_TYPE process on the docker image itself"
echo "===================================================================="
else
  echo "Exiting..."
  exit
fi


# ---------------------------------------------------------------------- #
# Perform Actions
# ---------------------------------------------------------------------- #
if [ "$ACTION_TYPE" == "backup" ]; then
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

    echo "Dropped all tables inside the database for clean restore."

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