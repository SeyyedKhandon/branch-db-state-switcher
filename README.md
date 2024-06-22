# Branch DB Switcher

Branch DB Switcher is a bash script that helps manage database states across different Git branches. It allows you to easily backup and restore your database when switching between branches, saving time and reducing errors in development and QA processes.

## Problem Statement

When switching between various Git branches for code review or QA, changes in the database structure or content often require resetting and preparing the database for each branch. This process can be time-consuming and error-prone, especially when frequently switching between branches.

## Solution

This script automates the process of backing up the database before switching branches and restoring it after switching. It uses Git hooks (pre-checkout and post-checkout) to create and load database backups based on the branch name.

## Features

- [x] Backup database based on current branch name
- [x] Restore database from backup based on current branch name
- [x] List all available backups
- [x] Delete specific backups
- [x] Delete all backups
- [x] Support for manual backup and restore operations
- [x] Support dockerized postgres database 
- [ ] Support simple postgres database
- [ ] Safe restore operation (before each restore operation, it will generate a backup from the current state of the DB with `.safemode.psql` extension)
- [ ] Install it on `pre-post checkout` hook for current branch
- [ ] Install/Uninstall the script via brew
- [ ] Add the script to global commands ( to be able to call it in every project without copy/pasting it )
- [ ] Support config file per project through `init` command (operation based on config file)
    - `init` command asks for multiple questions suchs `DB_NAME, DB_USER, etc.`
- [ ] Support global config file in case of missing per project config file
- [ ] Support save location via config file (choose between inside local docker or inside host machine)
- [ ] Support verbose mode
- [ ] Support `mysql`
- [ ] Support colorize output


## Prerequisites

- Docker
- Git
- PostgreSQL (running in a Docker container)

## Installation

1. Clone this repository or copy the `branchDBSwitcher.sh` script to your project root.
2. Make the script executable:
   ```
   chmod +x ./branchDBSwitcher.sh
   ```
3. Update the following variables in the script according to your project setup:
   ```bash
   DOCKER_IMAGE_NAME="docker_image_name" 
   DB_NAME="db_name"
   DB_USER="db_username"
   ```

**Note**: How to get the docker name? There are various ways to do it:

- Method1: Get it from your `docker-compose.yml` file inside your project
- Method2: Run `docker ps` in your terminal, which shows you a list of all running docker instances, for example `myproject-db`:

```bash
~ docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED      STATUS      PORTS                                          NAMES
91f8ac252584   postgres:13.4-alpine   "docker-entrypoint.s…"   5 days ago   Up 5 days   0.0.0.0:5432->5432/tcp                         myproject-db
```

## Usage

The script accepts the following commands:

```
./branchDBSwitcher.sh <action_type> [backup_name]
```

Available actions:
- `list`: List all backups
- `backup`: Create a backup
- `restore`: Restore a backup
- `delete`: Delete a specific backup
- `delete-all`: Delete all backups

Examples:

1. List all backups:
   ```
   ./branchDBSwitcher.sh list
   ```

2. Automatic backup based on current branch name:
   ```
   ./branchDBSwitcher.sh backup
   ```

3. Automatic restore based on current branch name:
   ```
   ./branchDBSwitcher.sh restore
   ```

4. Manual backup with a custom name:
   ```
   ./branchDBSwitcher.sh backup myBackup
   ```

5. Manual restore with a custom name:
   ```
   ./branchDBSwitcher.sh restore myBackup
   ```

6. Delete a specific backup:
   ```
   ./branchDBSwitcher.sh delete myBackup
   ```

7. Delete all backups:
   ```
   ./branchDBSwitcher.sh delete-all
   ```

## Git Hooks Integration

To fully automate the process, you need to integrate the script with Git hooks. This part is still in progress, but you'll need to add the script calls to the `pre-checkout` and `post-checkout` hooks in your Git repository.

## Notes

- This script is designed to work with passwordless PostgreSQL databases running in Docker containers in local machine.
- Ensure you have the necessary permissions to execute Docker commands and access the database.
- This script is designed for local environment for development mode, so avoid using it on production.


## Contributing

Contributions, issues, and feature requests are welcome. Feel free to check issues page if you want to contribute.

### Contributors

Thanks to the following people who have contributed to this project:

* [@seyyedkhandon](https://github.com/seyyedkhandon) - Creator and maintainer


### How to Become a Contributor

We welcome contributions from the community! If you'd like to contribute:

1. Check the `issues page` for open issues or create a new one to discuss your idea.
1. Once approved, follow the steps in the Contributing section above.
1. Fork the Project
1. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
1. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
1. Push to the Branch (`git push origin feature/AmazingFeature`)
1. Open a Pull Request
1. After your pull request is merged, you'll be added to the contributors list.

## License

[MIT](https://choosealicense.com/licenses/mit/)
