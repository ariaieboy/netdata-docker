#!/bin/bash
set -e
DEBIAN_FRONTEND=noninteractive

# install dependencies for build
# source: https://learn.netdata.cloud/docs/agent/packaging/installer/methods/manual
apt-get -qq update
apt-get -y install curl git
curl -Ss 'https://raw.githubusercontent.com/netdata/netdata/master/packaging/installer/install-required-packages.sh' >/tmp/install-required-packages.sh
chmod +x ./tmp/install-required-packages.sh
./tmp/install-required-packages.sh -i netdata-all

# fetch netdata

git clone --depth=100 --recursive https://github.com/firehol/netdata.git /netdata.git
cd /netdata.git
TAG=$(</git-tag)
if [ ! -z "$TAG" ]; then
	echo "Checking out tag: $TAG"
	git checkout tags/$TAG
else
	echo "No tag, using master"
fi

# fix for https://github.com/netdata/netdata/issues/11652

git submodule update --init --recursive

# use the provided installer

./netdata-installer.sh --dont-wait --dont-start-it --disable-telemetry

# removed hack on 2017/1/3
#chown root:root /usr/libexec/netdata/plugins.d/apps.plugin
#chmod 4755 /usr/libexec/netdata/plugins.d/apps.plugin

# remove build dependencies

cd /
rm -rf /netdata.git

dpkg -P zlib1g-dev uuid-dev libmnl-dev make git autoconf autogen automake pkg-config libuv1-dev liblz4-dev libjudy-dev libssl-dev cmake libelf-dev libprotobuf-dev protobuf-compiler g++
apt-get -y autoremove
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# symlink access log and error log to stdout/stderr

ln -sf /dev/stdout /var/log/netdata/access.log
ln -sf /dev/stdout /var/log/netdata/debug.log
ln -sf /dev/stderr /var/log/netdata/error.log