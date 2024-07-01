# RSpace On Docker
![Current RSpace Version](https://img.shields.io/badge/Current_RSpace_Version-2.00-2ea44f)

## System Requirements
- A machine with at least 4GB of RAM and a dual core CPU (more is better) - See performance metrics at the end of this guide
- Docker and docker-compose installed on the machine


## Your Data Folders

The /media/rspace and /var/lib/mysql folders are mounted as docker volumes. This is where important data is stored. Back the docker volumes up!


**You will need to change this in the docker-compose file to match your paths before first startup**

## Container Structure

RSpace App Container
- Latest version of Tomcat 9 w/ OpenJDK 17
- RSpace (Whichever version your WAR file is)
  
RSpace DB Container
- MariaDB (LTS)
  
## Docker Networking & Security

Containers are kept within their own docker network. The only exposed ports are port 8080. Containers are referred to by their docker name and not their IP address, this is because docker as built in translation for IP addresses to docker container names.

## Access to RSpace

RSpace will be reachable on port 8080 on localhost. You can setup a reverse proxy (only apache2 is compatible) to access RSpace over a TLD and setup SSL. Have a look in the Extras folder in this repo for docs on how to setup apache2 to work with RSpace.

**Highly recommended for production releases to configure apache2 and to access RSpace only over HTTPS via apache2**

localhost:8080 is fine for development purposes or if you're only running RSpace locally for a test drive.

## Installing RSpace on Docker

You must already have docker and docker-compose installed. 

This guide goes over setting up RSpace on Docker using a Linux host machine, if you're running Docker on Windows, then you will need to edit your config files.

**YOU WILL HAVE TO CHANGE THE VOLUME "bind" FILE PATHS IN THE DOCKER-COMPOSE.YAML FILE TO MATCH YOUR HOST / OWN PATHS**.

ℹ️ Get the RSpace WAR file from GitHub releases - https://github.com/rspace-os/rspace-web/releases  ℹ️

Your file structure inside your rspace-docker folder should look like this:

- docker-compose.yaml
- deployment.properties
- rspace.war
- templates
	- db-template.sql
- configs
	- db-config.cnf
	- rspace.env
	- tomcat-locate.sh
	- server.xml


| File name                            | File role                                        | Do I need to edit it?                                                                    |
| ------------------------------------ | ------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| **Inside your configs folder**       |                                                  |                                                                                          |
| db-config.cnf                        | MariaDB config file                              | No                                                                                       |
| rspace.env                           | Tomcat properties for RSpace                     | Yes, edit your min/max amount of RAM allowed. Edit the JMelody username and password     |
| server.xml                           | Tomcat config file                               | Only for debugging purposes or if you want to setup a new listener                       |
| tomcat-locate.sh                     | Tomcat Java config file                          | No                                                                                       |
| **Inside your templates folder**     |                                                  |                                                                                          |
| db-template.sql                      | DB Template to be imported before first start up | No                                                                                       |
| **Inside your rspace-docker folder** |                                                  |                                                                                          |
| deployment.properties                | RSpace config file                               | Yes, edit hostname, db username/pass, and any RSpace integrations you wish to setup      |
| docker-compose.yaml                  | Main docker config file                          | Yes, edit so paths to files match up with your host. Edit DB username/password           |
| rspace.war                           | RSpace Java EXE file                             | Yes, update with new WAR from RSpace repo releases page to update your version of RSpace |

**If you're running on Docker on Linux, you may need to add sudo infront of the commands, as default Docker on Linux does not come in rootless mode. Docker for Desktop (on Mac OS) comes with rootless mode out the box.**

**If you make any changes to the docker config (such as editing any of the config files), you may need to do a docker-compose up, as docker-compose start sometimes doesn't pick up new changes**

Next, create the containers, but do not start them:

```
docker-compose up --no-start
```
## Setting up the RSpace DB Containers

Then only start your database container:

```
docker-compose start rspace-db
```

You'll want to get a bash shell inside the database container (your container name might be different so double check using docker container ps), so that you can import the SQL file, run:

```
docker exec -it rspace-docker_rspace-db_1 bash
```

And once you're in the bash shell, run the following command (you can find the default sql password in the docker-compose file)

```
mariadb -u root -p rspace < import.sql
```

Then exit from the container. You can now start the RSpace container on your host, to do so run:

```
docker-compose start rspace-app
```

**You MUST now create the following folders below. Without these folders being created, RSpace will FAIL TO START UP. Create the folders, then restart the container like shown below.**

To do so, bash into the rspace-app container and run the following command:

```
docker exec -it rspace-docker_rspace-app_1 bash
mkdir /media/rspace/tomcat-tmp
mkdir /media/rspace/archives
mkdir /media/rspace/archive
mkdir /media/rspace/backup
mkdir /media/rspace/download
mkdir /media/rspace/indices
cd /media/rspace/ && ls -l
exit
```

Now stop both your containers (stopping the app first):

```
docker-compose stop rspace-app
docker-compose stop rspace-db
```

and then start the containers again:

```
docker-compose start rspace-db
docker-compose start rspace-app
```

you must start / stop them in this order. You should now be able to access RSpace by navigating to your URL / hostname 🕺

You can login with the username 'sysadmin1' and the password ![image](https://github.com/rspace-os/rspace-docker/assets/108399191/45cd4296-13e5-4649-90fc-eb286bcc0c0c)

**⚠️ You MUST change the default sysadmin1 password now ⚠️**

## Using RSpace after the first time setup

The steps above are only needed for the first time setup, after that you can start and stop the RSpace containers like this:

- docker-compose start / stop rspace-app
- docker-compose start / stop rspace-db


**You MUST start the database container BEFORE the RSpace container. You MUST stop the RSpace container before the database container.**


I recommend that you create a simple bash startup and shutdown script that has the docker-compose commands in the correct order, so that stopping and starting all the services in the correct order is easier.

*If you make any changes to the docker config, you may need to do a docker-compose up, as docker-compose start sometimes doesn't pick up new changes*

## Updating RSpace
If you need to update RSpace, stop the containers, replace the WAR file with one for a newer version of RSpace and then start the containers back up. We recommend you create a mariadb-dump (see commands below) of the database right before you update RSpace incase you need to revert back.


- The tomcat container will fetch the latest version of tomcat9 with JDK17.
- The mariadb container will fetch the latest LTS version.
- You do not need to update the apache2 container, as it will always fetch the latest version.
  
*These updates only apply if you do a docker-compose stop and then docker-compose up -d, as docker-compose start does not check for container updates*

## RSpace Backups & Restores

The RSpace media folder and database folder are kept in the docker volumes. You need to backup these volumes as they keep your data.

You should keep backups of your "rspace-docker" folder.

You can backup your database using the commands below (you can put these in a bash script and run them via cron for automatic backups too!)

```
docker exec -it rspace-docker_rspace-db_1 bash
mariadb-dump -u rspacedocker -p yourpassword DBNAME > backup.sql
```

^ Then you can copy your SQL file back to your host


Additionally, RSpace has it's own Export / Import process which can be used for backing up data - https://documentation.researchspace.com/article/25mt56kamf-export-options



## Completely deleting your RSpace containers and data.
If you want a fresh start, you can do so by deleting the docker containers and volumes linked to RSpace on Docker.


## Performance of RSpace on Docker
We've ran RSpace on Docker on multiple setups. Compared to our bare metal setup (running RSpace on tomcat installed on a linux system running on a cloud instance with 2cpu/4gb ram), it runs a little bit slower on Docker compared to the bare metal version, but it's still useable. 

Running RSpace on any semi modern computer gives us good results. 

If you're running RSpace on a dedicated VM or computer, 4GB of RAM is the minimum we'd suggest (8GB will give you a better experience), and that will need to increase with higher user loads.

If you're running RSpace on a computer (such as a Laptop or Desktop), then really you want 8GB of RAM minimum - We had good results running RSpace on a 8GB M1 MacBook Air, however as soon as a background program was opened, we hit our RAM limit pretty quickly. If you've got a PC with 16GB of RAM or higher, you should be fine - We tested it with a Intel Mac Mini with 16GB of RAM and a Lenovo ThinkPad T14 (AMD) with 24GB of RAM, and those devices had no problem running RSpace on Docker with multiple other background programs running.

If you do increase your RAM, make sure to edit the rspace.env file to edit the Tomcat ram limit to be higher - Tomcat won't automatically use all available RAM, you need to manually increase the maximum RAM it can use.

## Support & Issues

Please use GitHub issues to submit any issues you may face.

If you have an issue with the Docker config, or RSpace is failing to startup, please use the Github issues for the rspace-docker repo

If you have found a bug or have an issue with the RSpace software itself, please use the Github issues for the rspace-web repo
