# Optimize Node.js Application Server

## Tune Access

In order to optimize the application server for network traffic, a few tweaks need to be made in `/etc/sysctl.conf` followed by a reboot of the server. Open the file and replace the contents with the following:

```bash
### IMPROVE SYSTEM MEMORY MANAGEMENT ###

# Increase size of file handles and inode cache
fs.file-max = 2097152

# Do less swapping
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2

### GENERAL NETWORK SECURITY OPTIONS ###

# Number of times SYNACKs for passive TCP connection.
net.ipv4.tcp_synack_retries = 2

# Allowed local port range
net.ipv4.ip_local_port_range = 2000 65535

# Protect Against TCP Time-Wait
net.ipv4.tcp_rfc1337 = 1

# Decrease the time default value for tcp_fin_timeout connection
net.ipv4.tcp_fin_timeout = 15

# Decrease the time default value for connections to keep alive
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

### TUNING NETWORK PERFORMANCE ###

# Default Socket Receive Buffer
net.core.rmem_default = 31457280

# Maximum Socket Receive Buffer
net.core.rmem_max = 12582912

# Default Socket Send Buffer
net.core.wmem_default = 31457280

# Maximum Socket Send Buffer
net.core.wmem_max = 12582912

# Increase number of incoming connections
net.core.somaxconn = 4096

# Increase number of incoming connections backlog
net.core.netdev_max_backlog = 65536

# Increase the maximum amount of option memory buffers
net.core.optmem_max = 25165824

# Increase the maximum total buffer-space allocatable
# This is measured in units of pages (4096 bytes)
net.ipv4.tcp_mem = 65536 131072 262144
net.ipv4.udp_mem = 65536 131072 262144

# Increase the read-buffer space allocatable
net.ipv4.tcp_rmem = 8192 87380 16777216
net.ipv4.udp_rmem_min = 16384

# Increase the write-buffer-space allocatable
net.ipv4.tcp_wmem = 8192 65536 16777216
net.ipv4.udp_wmem_min = 16384

# Increase the tcp-time-wait buckets pool size to prevent simple DOS attacks
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
```

At this point, reboot the server.

### Description of the changes

* `fs.file-max` - this increases the number of available descriptors for performing IO operations
* `vm.swappiness` - the defaul Ubuntu setting is 60... this lowers that setting so that swap is used RAM usage is near 90%

## GeoIP install

### Step 1. Add the PPA for geoipupdate and install it

```bash
sudo apt-add-repository ppa:maxmind/ppa
sudo apt-get update
sudo apt-get install geoipupdate -y
sudo apt-get install libgeoip-dev -y
```

### Step 2. Configure geoipupdate

Open `/etc/GeoIP.conf` and ensure it looks like the following:

```bash
# The following UserId and LicenseKey are required placeholders:
UserId 999999
LicenseKey 000000000000

# Include one or more of the following ProductIds:
# * GeoLite2-City - GeoLite 2 City
# * GeoLite2-Country - GeoLite2 Country
# * GeoLite-Legacy-IPv6-City - GeoLite Legacy IPv6 City
# * GeoLite-Legacy-IPv6-Country - GeoLite Legacy IPv6 Country
# * 506 - GeoLite Legacy Country
# * 517 - GeoLite Legacy ASN
# * 533 - GeoLite Legacy City
ProductIds GeoLite2-City GeoLite2-Country GeoLite-Legacy-IPv6-City GeoLite-Legacy-IPv6-Country 506 517 533
```

### Step 3. Create autoupdate crontab entry

To edit the root crontab, use the following command:

```bash
sudo crontab -e
```

Add the following entry (update at 1:45am each Wednesday each month):

```bash
45 1 * * 3 /usr/bin/geoipupdate
```

### Step 4. Run geoipupdate

```bash
sudo geoipupdate
```

## NGINX install

### Step 1. Grab the nginx source and dependencies

Add the nginx repository and signing PGP key:

```bash
sudo apt-add-repository -s 'deb http://nginx.org/packages/ubuntu trusty nginx'
sudo wget -qO - http://nginx.org/keys/nginx_signing.key | sudo apt-key add -
sudo apt-get update
```

Now let's grab the source and compile it as needed:

```bash
cd /opt
sudo apt-get build-dep nginx -y
sudo apt-get source nginx -y
sudo apt-get install dpkg-dev -y
```

### Step 2. Configure additional dependencies

For this step, edits are required to `/opt/nginx-1.8.0/debian/rules`. In the section of the document below `override_dh_auto_build:` add a flag to include ngx_http_geoip_module (`--with-http_geoip_module`). See below example of what the section should look like after adding the flag:

```bash
override_dh_auto_build:
        dh_auto_build
        mv objs/nginx objs/nginx.debug
        CFLAGS="" ./configure \
                --prefix=/etc/nginx \
                --sbin-path=/usr/sbin/nginx \
                --conf-path=/etc/nginx/nginx.conf \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --pid-path=/var/run/nginx.pid \
                --lock-path=/var/run/nginx.lock \
                --http-client-body-temp-path=/var/cache/nginx/client_temp \
                --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
                --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
                --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
                --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
                --user=nginx \
                --group=nginx \
                --with-http_ssl_module \
                --with-http_realip_module \
                --with-http_addition_module \
                --with-http_sub_module \
                --with-http_dav_module \
                --with-http_flv_module \
                --with-http_mp4_module \
                --with-http_geoip_module \
                --with-http_gunzip_module \
                --with-http_gzip_static_module \
                --with-http_random_index_module \
                --with-http_secure_link_module \
                --with-http_stub_status_module \
                --with-http_auth_request_module \
                --with-mail \
                --with-mail_ssl_module \
                --with-file-aio \
                $(WITH_SPDY) \
                --with-cc-opt="$(CFLAGS)" \
                --with-ld-opt="$(LDFLAGS)" \
                --with-ipv6
        dh_auto_build
```

### Step 3. Compile it

Compile a new nginx debian package:

```bash
cd /opt/nginx-1.8.0
sudo dpkg-buildpackage -uc -b
```

_Note: Once this package is compiled, it can be used to install nginx on other machines if needed, rapidly. The GeoIP installation steps are still required, however._

### Step 4. Install nginx

Optional: If nginx has previously been installed with `apt-get`, it must be uninstalled first:

```bash
sudo apt-get remove nginx
```

Now, install the newly compiled Debian nginx package that contains the modules we need:

```bash
sudo dpkg --install /opt/nginx_1.8.0-1~trusty_amd64.deb
```

Verify the necessary flags are installed by running the following:

```bash
nginx -V
```

You should see the flags `--with-http_realip_module` and `--with-http_geoip_module`.
