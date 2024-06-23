# Branch Database State Switcher

Branch Database State Switcher is a bash script that helps manage database states across different Git branches. It allows you to easily backup and restore your database when switching between branches, saving time and reducing errors in development and QA processes.

## Problem Statement

When switching between various Git branches for code review or QA, changes in the database structure or content often require resetting and preparing the database for each branch. This process can be time-consuming and error-prone, especially when frequently switching between branches.

## Solution

This script automates the process of backing up the database before switching branches and restoring it after switching. It uses Git hooks (pre-checkout and post-checkout) to create and load database backups based on the branch name.

## Features

- [x] Backup database based on current branch name
- [x] Restore database from backup based on current branch name
- [x] List all available backups
- [x] Check the version of the branch db switcher
- [x] Delete specific backups
- [x] Delete all backups
- [x] Support for manual backup and restore operations
- [x] Support dockerized postgres database 
- [x] Support config file per project (reading config from `.env`)
- [x] Uninstall command
- [x] Add the script to global commands ( to be able to call it in every project without copy/pasting it )
- [x] Safe restore operation (before each restore operation, it will generate a backup from the current state of the DB with `.safemode` extension)
- [ ] Support for alternative config file name if it's not possible to use `.env`
- [ ] Support simple postgres database
- [ ] Install it on `pre-post checkout` hook for current branch
- [ ] Install/Uninstall the script via brew
- [ ] Support config file per project through `init` command (operation based on config file)
      - `init` command asks for multiple questions suchs `DB_NAME, DB_USER, etc.`
- [ ] Support global config file in case of missing per project config file
- [ ] Support save location via config file (choose between inside local docker or inside host machine)
- [ ] Support verbose mode
- [ ] Support `mysql`
- [ ] Support colorize output
- [ ] VSCode Extension via commands
- [ ] VSCode Extension via ui to back up various things

## Installation

You can simply download `bds.sh` and use it on your local machine or follow these instructions:

#### Step 1 - install it

 
If you use curl and bash:

```sh
curl -o ~/bds https://raw.githubusercontent.com/SeyyedKhandon/branch-db-state-switcher/main/bds.sh && chmod +x ~/bds && sudo mkdir -p /usr/local/bin/branch-db-state-switcher && sudo mv ~/bds /usr/local/bin/branch-db-state-switcher/bds && if ! grep -q '/usr/local/bin/branch-db-state-switcher' ~/.bashrc; then echo 'export PATH="/usr/local/bin/branch-db-state-switcher:$PATH"' >> ~/.bashrc; fi && source ~/.bashrc && RESULT=$(bds -v) && echo "\r\n $RESULT has been installed. \r\n" && echo "Read available commands https://github.com/SeyyedKhandon/branch-db-state-switcher" && echo "\r\n****Please give a star on github to support us.****\r\n"
```

If you use curl and zsh:

```sh
curl -o ~/bds https://raw.githubusercontent.com/SeyyedKhandon/branch-db-state-switcher/main/bds.sh && chmod +x ~/bds && sudo mkdir -p /usr/local/bin/branch-db-state-switcher && sudo mv ~/bds /usr/local/bin/branch-db-state-switcher/bds && if ! grep -q '/usr/local/bin/branch-db-state-switcher' ~/.zshrc; then echo 'export PATH="/usr/local/bin/branch-db-state-switcher:$PATH"' >> ~/.zshrc; fi && source ~/.zshrc && RESULT=$(bds -v) && echo "\r\n $RESULT has been installed. \r\n" && echo "Read available commands https://github.com/SeyyedKhandon/branch-db-state-switcher" && echo "\r\n****Please give a star on github to support us.****\r\n"
```

Check for installtion, open you terminal and run `bds -v` or `bds --version`: 
```sh
bds -v
# Branch database state switcher v1.0
```

#### Step 2 - configure it

In order to use it inside your project, you need to create a `.env` file inside your project, if you don't have. Don't forget to add `.env` to your `.gitignore` file. 

3. Add the following variables inside the `.env` of your project:

```bash
# DOCKER_IMAGE_NAME="your docker image name that runs the database" 
# DB_NAME="your database's name"
# DB_USER="your database's username"
# DB_PASSWORD="your database's password which usually on local is empty"
# SAFE_RESTORE_MODE="true or false" # By default if you dont provide anything, it is true, so before any restore command, it will take safemode backup. If you want to turnoff this feature, just set it's value to false. 

# For example:
DOCKER_IMAGE_NAME=myproject-db
DB_NAME=my_db_name
DB_USER=admin
DB_PASSWORD=
SAFE_RESTORE_MODE=true
```

**Note**: How to get the docker name? There are various ways to do it:

- Method1: Get it from your `docker-compose.yml` file inside your project
- Method2: Run `docker ps` in your terminal, which shows you a list of all running docker instances, for example `myproject-db`:

```bash
~ docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED      STATUS      PORTS                                          NAMES
91f8ac252584   postgres:13.4-alpine   "docker-entrypoint.s…"   5 days ago   Up 5 days   0.0.0.0:5432->5432/tcp                         myproject-db
```

#### Uninstall

If you no longer need this script and want to completely remove it, just run below command:

For bash users:

```sh
sudo sudo rm -R /usr/local/bin/branch-db-state-switcher && sed -i '' '/export PATH="\/usr\/local\/bin\/branch-db-state-switcher:\$PATH"/d' ~/.zshrc && source ~/.zshrc && echo "Branch DB State Switcher has been uninstalled."
```

For zsh users:

```sh
sudo rm -R /usr/local/bin/branch-db-state-switcher && sed -i '' '/export PATH="\/usr\/local\/bin\/branch-db-state-switcher:\$PATH"/d' ~/.zshrc && source ~/.zshrc && echo "Branch DB State Switcher has been uninstalled."
```


## Usage

The script accepts the following commands:

```sh
./bds <action_type> [backup/restore/delete_name]
# Second argument for backup/restore/delete is optional, so if you dont provide it, it will automatically generate a name based on your current working branch

```

**Available actions**:

- `-l` or `--list`: List all backups
- `backup`: Create a backup
- `restore`: Restore a backup
- `delete`: Delete a specific backup
- `delete-all`: Delete all backups

Examples:

1. List all backups: `bds -l`

2. Automatic backup based on current branch name: `bds backup`

3. Automatic restore based on current branch name: `bds restore`

4. Manual backup with a custom name: `bds backup myBackup`

5. Manual restore with a custom name: `bds restore myBackup`

6. Delete a specific backup: `bds delete myBackup`

7. Delete all backups: `bds delete-all`

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
