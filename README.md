# RSpace On Docker
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

Containers are kept within their own docker network. The only exposed ports are port 8080. Containers are referred to by their docker name and not their IP address, this is because docker as built in translation for IP addresses to docker container names. By default docker binds the 8080 port to 0.0.0.0, if you are only running on localhost, then you can change the docker-compose config to only bind the 8080 port to 127.0.0.1.

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
| docker-compose.yaml                  | Main docker config file                          | Yes, edit paths to files match up with your host. Edit DB username/password           |
| rspace.war                           | RSpace Java EXE file                             | Yes, update with new WAR from RSpace repo releases page to update your version of RSpace |

**If you're running on Docker on Linux, you may need to add sudo infront of the commands, as default Docker on Linux does not come in sudo-less mode. This is not an issue on Docker for Desktop. Also, we haven't seen this on desktop versions of Docker yet, but in new distro releases (Eg. Ubuntu 24.04 LTS) docker-compose has been replaced with docker compose, so you may need to adjust your commands**

**If you make any changes to the docker config (such as editing any of the config files), you may need to do a docker-compose up, as docker-compose start sometimes doesn't pick up new changes**

**ℹ️ This guide follows the latest Docker compose commands and standards. If you're running a older distro (like Ubuntu 22.04 <), then you will need to use docker-compose and NOT docker compose. If you're using the latest version of Docker or a newer distro (Ubuntu 24.04, etc.) then docker compose should work fine for you. ℹ️**

***The steps below have recently been updated to facilitate a more automated deployment. If you still wish to read the manual steps, then please visit the archive/manual-steps branch of this repo*** 

Once you have edited any config files (such as changing default passwords, setting up hostnames, etc..) and you've downloaded the RSpace WAR file from the rspace-os repo and placed it into your rspace-docker folder following the naming pattern shown in the table above. You can start up the containers with

```
docker compose up -d
```

First startup may take longer than usual, this is because RSpace is importing a SQL template into the database, and then creating the media paths before it is started up. Subsequent startups should be quicker.

You should now be able to access RSpace by navigating to your URL / hostname 🕺


You can login with the username 'sysadmin1' and the password ![image](https://github.com/rspace-os/rspace-docker/assets/108399191/45cd4296-13e5-4649-90fc-eb286bcc0c0c)


**⚠️ You MUST change the default sysadmin1 password now ⚠️**

## Using RSpace after the first time setup

You can start and stop the containers using docker compose stop / down / start / up -d

Docker will automatically startup the database container first, and then the RSpace app container.

*If you make any changes to the docker config, you may need to do a docker-compose up, as docker-compose start sometimes doesn't pick up new changes.*

## Updating RSpace
If you need to update RSpace, stop the containers, replace the WAR file with one for a newer version of RSpace and then start the containers back up. We recommend you create a mariadb-dump (see commands below) of the database right before you update RSpace incase you need to revert back.


- The tomcat container will fetch the latest version of tomcat9 with JDK17.
- The mariadb container will fetch the latest LTS version.
- You do not need to update the apache2 container, as it will always fetch the latest version.
  

If you want to update the base docker images, you should run: 
```
docker-compose pull  && docker-compose up -d
```

## RSpace Backups & Restores

The RSpace media folder and database folder are kept in the docker volumes. You need to backup these volumes as they keep your data.

You should keep backups of your "rspace-docker" folder.

You can backup your database using the commands below (you can put these in a bash script and run them via cron for automatic backups too!)

```
docker exec -it rspace-db bash
mariadb-dump -u rspacedocker -p yourpassword DBNAME > backup.sql
```

^ Then you can copy your SQL file back to your host using docker cp 

You can backup your RSpace FileStore by backing up everything in /media/rspace, which is kept in the rspace-media volume

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
