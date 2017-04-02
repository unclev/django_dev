Django site dev instance
===

## Requirements
1. Docker (docker-engine or docker-ce) 1.10.0+.
2. docker-compose 1.6.0+.

### Proxy network
This branch modification is specifically for accessing the web site via a reverse proxy -
for eg. kind of [docker-haproxy-network](https://github.com/gesellix/docker-haproxy-network) or [docker-haproxy-letsencrypt](https://github.com/bringnow/docker-haproxy-letsencrypt). To acomplish this the web container must share the same *haproxy_default* network with a proxy container.

This extenal network can be defined on the Docker host similar to
```sh
docker network create -d bridge \
 --subnet=172.15.0.0/16 \
 --gateway=172.15.0.1 \
 haproxy_default
```

## Workflow
1. Clone this repository.
2. In the directory you cloned it put `.env` file containing desired project name, for eg.:
  ```sh
  PROJECTNAME=example
  ```
  You may also wand adding `webdev` user uid and gid to the `.env` file:
  ```sh
  PROJECTNAME=example
  WUID=1001
  WGID=1001
  ```
  The defaults are
  ```sh
  PROJECTNAME=project
  WUID=1000
  WGID=1000
  ```
3. Optional. Adjust the port forwarding in the docker-compose.yml
4. Being in the source directory start the container with
  ```sh
  docker-compose up -d
  ```
  This builds the container, creates the `$PROJECTNAME` subdirectory with the newly created django project, 
  and runs server on port 8000 in the name of the specified `webdev` user.
5. Amend `ALLOWED_HOSTS` in `$PROJECTNAME/$PROJECTNAME/settings.py
  ```python
  ALLOWED_HOSTS = [u'example.tld']
  ```
6. If example.tld resolves to you localhost or docker machine, you may now request `http:/example.tld:8000`.

  Develop...

## Publishing changes
When the the contaier is build it copies source code from the build context directory. 

**This it is not recommended having several django projects at the same source location at the ame time.**

So to publish your work into the image:
1. Stop, remove the running container, and remove the existing image.
2. Modify *docker-compose.yml* to remove `.:/home/webdev` mapping.
3. Re-build the image.
4. Optional: you may want tag the just created image for further use.
5. Get back `.:/home/webdev` mapping for further development.

```sh
docker-compose down && docker rmi djangodev_web:latest
docker-compose build --no-cache
docker tag djangodev_web:latest djangodev_web:0.1
```

## Get to the container shell
Getting to the container shell is trivial with docker-compose:
```
victor@unclev:/srv/django_dev$ docker-compose exec web bash
webdev@861fbf29033c:~$ grep SECRET_KEY example/example/settings.py
SECRET_KEY = 'm5=+7mgsr!!#ape0c_3#2yawmpd(2e5_i4k@oun-6zwykjhzf+'
webdev@861fbf29033c:~$
```

## Connecting via the proxy
For HAProxy does not [fail to start if backend server name don't resolve](http://discourse.haproxy.org/t/haproxy-fails-to-start-if-backend-server-names-dont-resolve/322/16) include `default-server init-addr libc,none` in the `defaults` section.

Note that
- docker-compose.yml does not publish web server port;
- haproxy container (see [docker-compose.yml](https://github.com/unclev/haproxy-docker/blob/6c689d07ad34254c530df17f93cbc5ef033709e7/docker-compose.yml#L32-L33)) publishes port 80.
  The sample [haproxy.cfg](https://github.com/unclev/haproxy-docker/blob/6c689d07ad34254c530df17f93cbc5ef033709e7/config/haproxy/haproxy.cfg).

After starting **djangodev_web_1** and the proxy container (**letsencrypt_haproxy_1** here)
```
victor@unclev:/srv/django_dev$ docker-compose ps
     Name          Command     State   Ports 
--------------------------------------------
djangodev_web_1   ./start.sh   Up            
victor@unclev:/srv/django_dev$ cd ../letsencrypt
victor@unclev:/srv/letsencrypt$ docker-compose ps
        Name                       Command               State               Ports            
---------------------------------------------------------------------------------------------
letsencrypt_cli_1       entrypoint.sh help               Exit 0                               
letsencrypt_cron_1      entrypoint.sh cron-auto-re ...   Up       443/tcp                     
letsencrypt_haproxy_1   /entrypoint.sh                   Up       443/tcp, 0.0.0.0:80->80/tcp 
```
opening the site is trivial:
```
http://example.tld
```
