# Nginx GeoIP Proof of Concept

## Getting Started

### Server Setup

Create an Ubuntu server and follow the instructions found in `optimize-app-server.md`.

### Node App

```bash
mkdir ~/source
cd ~/source
git clone https://github.com/brozeph/nginx-geoip-test
cd nginx-geoip-test
npm install
npm run generate-keys
sudo cp nginx.conf /etc/nginx
sudo cp nginx-geoip-test.conf /etc/init
sudo service nginx-geoip-test start
```
