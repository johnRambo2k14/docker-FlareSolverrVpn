# [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr), WireGuard and OpenVPN

Shamelessly stolen from DyonR's Docker Jackett [implementation](https://github.com/DyonR/docker-Jackettvpn) and MarkusMcNugen qBittorrent [implementation](https://github.com/MarkusMcNugen/docker-qBittorrentvpn)

### Notice
This project was hacked together very quickly. I don't have much time to dedicate to this project, so I apologise in advance if I'm not available. Feel free to fork off this repo. 

[![Docker Pulls](https://img.shields.io/docker/pulls/trigger2k18/flaresolverrvpn)](https://hub.docker.com/r/trigger2k18/flaresolverrvpn)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/trigger2k18/flaresolverrvpn/latest)](https://hub.docker.com/r/trigger2k18/flaresolverrvpn)

Docker container which runs the latest headless [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr) Server while connecting to WireGuard or OpenVPN with iptables killswitch to prevent IP leakage when the tunnel goes down.

## Docker Features
* Base: amd64/debian:sid-slim
* Latest [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr)
* Selectively enable or disable WireGuard or OpenVPN support
* IP tables kill switch to prevent IP leaking when VPN connection fails
* Configurable UID and GID for config files for FlareSolverr.
* Created with [Unraid](https://unraid.net/) in mind

# Run container from Docker registry
The container is available from the Docker Hub, which is the simplest way to get it.
To run the container use this command, with additional parameters, please refer to the Variables, Volumes, and Ports section:

```
$ docker run --privileged  -d \
              -v /your/config/path/:/config \
              -e "VPN_ENABLED=yes" \
              -e "VPN_TYPE=wireguard" \
              -e "LAN_NETWORK=192.168.0.0/24" \
              -p 9117:9117 \
              --restart unless-stopped \
              trigger2k18/flaresolverrvpn
```

# Variables, Volumes, and Ports
## Environment Variables
| Variable | Required | Function | Example | Default |
|----------|----------|----------|----------|----------|
`LOG_LEVEL` | No | Verbosity of the logging. Use `LOG_LEVEL=debug` for more information.| `LOG_LEVEL=info` | info | 
`LOG_HTML` | No | Only for debugging. If `true` all HTML that passes through the proxy will be logged to the console in `debug` level.| `LOG_HTML=false` |false 
`CAPTCHA_SOLVER` | No | Captcha solving method. It is used when a captcha is encountered. See the Captcha Solvers section.| `CAPTCHA_SOLVER=none` | none |
`TZ` | No | Timezone used in the logs and the web browser.| `TZ=Europe/London`| UTC |
`HEADLESS` | No | Only for debugging. To run the web browser in headless mode or visible. | `HEADLESS=true` | true | 
|`VPN_ENABLED`| Yes | Enable VPN? (yes/no)|`VPN_ENABLED=yes`|`yes`|
|`VPN_TYPE`| Yes | WireGuard or OpenVPN? (wireguard/openvpn)|`VPN_TYPE=wireguard`|`openvpn`|
|`VPN_USERNAME`| No | If username and password provided, configures ovpn file automatically |`VPN_USERNAME=ad8f64c02a2de`||
|`VPN_PASSWORD`| No | If username and password provided, configures ovpn file automatically |`VPN_PASSWORD=ac98df79ed7fb`||
|`LAN_NETWORK`| Yes (atleast one) | Comma delimited local Network's with CIDR notation |`LAN_NETWORK=192.168.0.0/24,10.10.0.0/24`||
|`NAME_SERVERS`| No | Comma delimited name servers |`NAME_SERVERS=1.1.1.1,1.0.0.1`|`1.1.1.1,1.0.0.1`|
|`PUID`| No | UID applied to config files |`PUID=99`|`99`|
|`PGID`| No | GID applied to config files |`PGID=100`|`100`|
|`UMASK`| No | |`UMASK=002`|`002`|
|`HEALTH_CHECK_HOST`| No |This is the host or IP that the healthcheck script will use to check an active connection|`HEALTH_CHECK_HOST=one.one.one.one`|`one.one.one.one`|
|`HEALTH_CHECK_INTERVAL`| No |This is the time in seconds that the container waits to see if the internet connection still works (check if VPN died)|`HEALTH_CHECK_INTERVAL=300`|`300`|
|`HEALTH_CHECK_SILENT`| No |Set to `1` to supress the 'Network is up' message. Defaults to `1` if unset.|`HEALTH_CHECK_SILENT=1`|`1`|
|`ADDITIONAL_PORTS`| No |Adding a comma delimited list of ports will allow these ports via the iptables script.|`ADDITIONAL_PORTS=1234,8112`||

## Volumes
| Volume | Required | Function | Example |
|----------|----------|----------|----------|
| `config` | Yes | FlarSsolverr and OpenVPN config files | `/your/config/path/:/config` - this creates two sub folders, `flaresolverr` and `openvpn`, place your .ovpn files there|

## Ports
| Port | Proto | Required | Function | Example |
|----------|----------|----------|----------|----------|
| `8191` | TCP | Yes | FlareSolverr communication port | `8191:8191`|

# Access the FlareSolverr
Access http://IPADDRESS:PORT from a browser on the same network. (for example: http://192.168.0.90:8191)

# How to use WireGuard 
The container will fail to boot if `VPN_ENABLED` is set and there is no valid .conf file present in the /config/wireguard directory. Drop a .conf file from your VPN provider into /config/wireguard and start the container again. The file must have the name `wg0.conf`, or it will fail to start.

# How to use OpenVPN
The container will fail to boot if `VPN_ENABLED` is set and there is no valid .ovpn file present in the /config/openvpn directory. Drop a .ovpn file from your VPN provider into /config/openvpn (if necessary with additional files like certificates) and start the container again. You may need to edit the ovpn configuration file to load your VPN credentials from a file by setting `auth-user-pass`.

**Note:** The script will use the first ovpn file it finds in the /config/openvpn directory. Adding multiple ovpn files will not start multiple VPN connections.

## Example auth-user-pass option for .ovpn files
`auth-user-pass credentials.conf`

## Example credentials.conf
```
username
password
```

## PUID/PGID
User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:

```
id <username>
```

## Captcha Solvers

:warning: At this time none of the captcha solvers work. You can check the status in the open issues. Any help is welcome.

Sometimes CloudFlare not only gives mathematical computations and browser tests, sometimes they also require the user to
solve a captcha.
If this is the case, FlareSolverr will return the error `Captcha detected but no automatic solver is configured.`

FlareSolverr can be customized to solve the captchas automatically by setting the environment variable `CAPTCHA_SOLVER`
to the file name of one of the adapters inside the [/captcha](src/captcha) directory.

### hcaptcha-solver

This method makes use of the [hcaptcha-solver](https://github.com/JimmyLaurent/hcaptcha-solver) project.

NOTE: This solver works picking random images so it will fail in a lot of requests and it's hard to know if it is
working or not. In a real use case with Sonarr/Radarr + Jackett it is still useful because those apps make a new request
each 15 minutes. Eventually one of the requests is going to work and Jackett saves the cookie forever (until it stops
working).

To use this solver you must set the environment variable:

```bash
CAPTCHA_SOLVER=hcaptcha-solver
```

### CaptchaHarvester

This method makes use of the [CaptchaHarvester](https://github.com/NoahCardoza/CaptchaHarvester) project which allows
users to collect their own tokens from ReCaptcha V2/V3 and hCaptcha for free.

To use this method you must set these environment variables:

```bash
CAPTCHA_SOLVER=harvester
HARVESTER_ENDPOINT=https://127.0.0.1:5000/token
```

**Note**: above I set `HARVESTER_ENDPOINT` to the default configuration of the captcha harvester's server, but that
could change if you customize the command line flags. Simply put, `HARVESTER_ENDPOINT` should be set to the URI of the
route that returns a token in plain text when called.

## Related projects

* C# implementation => https://github.com/FlareSolverr/FlareSolverrSharp

# Issues
If you are having issues with this container please submit an issue on GitHub.
Please provide logs, Docker version and other information that can simplify reproducing the issue.
If possible, always use the most up to date version of Docker, you operating system, kernel and the container itself. Support is always a best-effort basis.
