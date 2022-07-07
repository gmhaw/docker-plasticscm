This image deploys a PlasticSCM server on Ubuntu for on-premise hosting.

**Starting with v11 the old Mono version of PlasticSCM was retired in favour of the .NET 6 version (previously .NET Core).**

Between v8 and v10, both a Mono and .NET Core version of PlasticSCM existed. This image always used the "newer" .NET Core version named 'plasticscm-server-netcore'. The image was named after this and was not renamed since.

## Version tags

*This table lists the latest images for each major version and explains the usage of the different tags as well.*

|Tag| Description|Release|Release notes|
|---|---|---|---|
|[latest](https://hub.docker.com/r/gmhaw/plasticscm-server-netcore/tags?name=latest)|Always the latest version of both Ubuntu and PlasticSCM.|**2022-07-07**|[Permalink](https://www.plasticscm.com/download/releasenotes/11.0.16.7176)
|[bionic](https://hub.docker.com/r/gmhaw/plasticscm-server-netcore/tags?name=bionic)|Ubuntu release using the latest supported version of PlastiSCM.|**2022-07-07**|[Permalink](https://www.plasticscm.com/download/releasenotes/11.0.16.7176)
|[11.0.16.7176](https://hub.docker.com/r/gmhaw/plasticscm-server-netcore/tags?name=11.0.16.7176)|Specific release on the latest supported version of Ubuntu.|**2022-07-07**|[Permalink](https://www.plasticscm.com/download/releasenotes/11.0.16.7176)
|[11](https://hub.docker.com/r/gmhaw/plasticscm-server-netcore/tags?name=11)|Latest v11 release on the latest supported version of Ubuntu.|**2022-07-07**|[Permalink](https://www.plasticscm.com/download/releasenotes/from/11.0.16.6683/to/11.0.16.7176)
|[10](https://hub.docker.com/r/gmhaw/plasticscm-server-netcore/tags?name=10)|Latest v10 release on the latest supported version of Ubuntu.|2022-03-03|[Permalink](https://www.plasticscm.com/download/releasenotes/from/10.0.16.5328/to/10.0.16.6656)
|[9](https://hub.docker.com/r/gmhaw/plasticscm-server-netcore/tags?name=9)|Latest v9 release on the latest supported version of Ubuntu.|2021-04-05|[Permalink](https://www.plasticscm.com/download/releasenotes/from/9.0.16.4057/to/9.0.16.5315)

**Support for Ubuntu 20.04/22.04 is currently missing due to a missing dependency.**

## Volumes

The container is set up to be started using the following volumes:
* `/conf/` : Contains all important configuration files for the PlasticSCM server which are symbolically linked into the server directory.
* `/db/jet/`: Contains the data of your repositories
* `/logs/`: Contains the logs of the server

This allows it to be run in true docker fashion where the container can be killed and recreated without having to track any residual important data on the writeable layer of the container.

## Ports

The default configuration of PlasticSCM uses four ports:

| Port | Usage |
|------|-------|
| 7178 | HTTP endpoint of the PlasticSCM webadmin |
| 7179 | HTTPS endpoint of the PlasticSCM webadmin |
| 8087 | Unencrypted TCP port for the PlasticSCM VCS service |
| 8088 | SSL encrypted port for the PlasticSCM VCS service |

**Note: The webadmin only starts the HTTPS endpoint if at least one SSL port for the VCS service is configured.**

## Details

The default entrypoint is the included `/plastic.sh` script. It is used to configure and start the server and additionally manage the configuration files and license.
By default, the script is executed without any parameters which tries to start an already configured server.  
Pass `-v` or `--verbose` to the script for slightly more verbose output.  
Pass `-h`, `--help` or `help` to see all available flags and commands.
```
plastic.sh is a setup script for this docker container.
Usage:
	plastic.sh [-v -q -h] [COMMAND]

Available commands:
	config    Configures the server
	start     Starts a configured server (Default)
	full      Configures and immediately starts the server
	sync      Syncs the configurations files after/during a run server
	help      Print this help

Available flags:
	     --no-admin   Don't create admin user and group during config
	-q | --quiet      Turn off output
	-v | --verbose    Enable verbose output
	-h | --help       Print this help and exit
```

## Setup

To deploy the server for the first time, it is required to start up a container interactively with the mounted config volume once, passing `config` as the command to the entrypoint `plastic.sh`.
This runs the interactive plastic configuration process of PlasticSCM and afterwards sets up the symbolic links of the configuration files.

`docker run --rm -it -v conf:/conf gmhaw/plasticscm-server-netcore:latest -v config`

By default, a user `admin` with the password `plastic_admin` and a group `admins` is created. To suppress this pass `--no-admin` when using the `config` command.

If you provide some .conf files already placed in `conf/` when executing `plastic.sh config`, these files will replace .conf files already in the container. This means that some configurations in the plastic configuration process beforehand will be ignored and replaced. **If you already have a license file, you can provide it (`license.lic`) beforehand which will directly replace the auto-generated trial license of the plastic configuration process.**

With the `config/` volume properly configured deploy the container passing `start` (or leave empty as this is the default command) as an argument to the `plastic.sh` entrypoint script. This starts the server and it can be reached from outside (on port 8088 using SSL).

`docker run --name plasticscm -v conf:/conf -v logs:/logs -v db:/db/jet -p 8088:8088 -p 7179:7179 gmhaw/plasticscm-server-netcore:latest -v start` 

After the server was started, it can be further set up using the webadmin console (on port 7179 using HTTPS).

After the server was properly set up using the webadmin console further .conf files might have been created that are not yet linked to the conf volume. To complete/validate the linkage of all .conf files and the license, exec into the container and run `/plastic.sh sync` to move and symlink all remaining/newly created .conf files into the `/conf` volume.  
**If you do not do this step after your finished configuring your server you might lose some configuration files if you kill the container.**

`docker exec plasticscm bash -c "/plastic.sh -v sync"`

## Reverse Proxy considerations

If you are using a reverse proxy, there are some additional considerations:

### VCS Service

The PlasticSCM client *does* send an SNI to the server allowing you to filter specifically for your servers FQN in addition to the SSL port.

### Webadmin
Both the PlasticSCM VCS service and the webadmin support both encrypted and unencrypted communication. But the webadmin only allows unencrypted HTTP connections from `localhost`. So to access the webadmin you *have to* use HTTPS. This means you have to configure your reverse proxy to pass through the TCP connection directly to the container and not let the reverse proxy decrypt the incoming HTTPS connection. (Example below for Traefik)

## Tips

### User managment
To manage user and groups though the command line use

`/opt/plasticscm5/server/plasticd umtool`

which is currently not documented in the PlasticSCM installation guide.

### Custom certificate for the webadmin

By default the webadmin uses the same certificate as the SSL port configuration for the PlasticSCM VCS service, as set in the webadmin console or `/conf/network.conf`. This certificate is self-signed when auto-generated. This means all browsers will warn you to access the webadmin due to an unsecure certificate.

Currently there is no way to specify a certificate just for the webadmin, but there is a workaround:

Create a second SSL port configuration in the webadmin and place it at the top of the list. Use an unexposed port (and maybe check 'Localhost only') and specify a different certificate. Here you can e.g. specifiy a certifcate signed by letsencrypt. The certificates should be placed in `/opt/plasticscm5/server/`. The webadmin will use the certificate for this entry for it's HTTPS endpoint.

![](https://i.imgur.com/GFmJAPy.png)

## Example `docker-compose.yml`

This is an example for a docker-compose.yml deploying a PlasticSCM Service behind a Traefik reverse proxy.

```
version: '3.8'

services:
    plasticscm:
        image: gmhaw/plasticscm-server-netcore:latest
        container_name: plasticscm
        restart: unless-stopped
        command: -v start # Must be configured interactively once using 'config' when no config files and license are provided
        expose:
            - '7179' # Webadmin HTTPS port
            - '8088' # Plastic SSL port
        volumes:
            - type: volume
              source: config
              target: '/conf/'
            - type: volume
              source: db
              target: '/db/jet'
            - type: volume
              source: logs
              target: '/logs'
        labels:
            - traefik.enable=true
            # Plastic VCS Service (SSL)
            - traefik.tcp.routers.plastic.rule=HostSNI(`plastic.mycompany.com`)
            - traefik.tcp.routers.plastic.entrypoints=plastic #8088
            - traefik.tcp.routers.plastic.service=plastic
            - traefik.tcp.routers.plastic.tls=true
            - traefik.tcp.routers.plastic.tls.passthrough=true
            - traefik.tcp.services.plastic.loadbalancer.server.port=8088 # SSL connection
            # Plastic Webadmin (HTTPS)
            - traefik.tcp.routers.plasticweb.rule=HostSNI(`plastic.mycompany.com`)
            - traefik.tcp.routers.plasticweb.entrypoints=websecure #443
            - traefik.tcp.routers.plasticweb.service=plastic-webadmin
            - traefik.tcp.routers.plasticweb.tls=true
            - traefik.tcp.routers.plasticweb.tls.passthrough=true
            - traefik.tcp.services.plastic-webadmin.loadbalancer.server.port=7179 # HTTPS connection

volumes:
   config:
       name: plasticscm_config
   db:
       name: plasticscm_db
   logs:
       name: plasticscm_logs
```