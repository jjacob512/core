#!/bin/bash
# Copyright 2014, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export RAILS_ENV=production
[[ $1 ]] || {
    echo "Must pass the FQDN you want the admin node to have as the first argument!"
    exit 1
}
./bootstrap.sh && \
    ./setup/01-crowbar-rake-tasks.install && \
    ./setup/02-make-machine-key.install || {
    echo "Failed to bootstrap the Crowbar UI"
    exit 1
}

export CROWBAR_KEY=$(cat /etc/crowbar.install.key)
export PATH=$PATH:/opt/opencrowbar/core/bin
FQDN=$1

DOMAINNAME=${FQDN#*.}
if [[ $container != lxc ]]; then
    HOSTNAME=${FQDN%%.*}
    # Fix up the localhost address mapping.
    sed -i -e "s/\(127\.0\.0\.1.*\)/127.0.0.1 $FQDN $HOSTNAME localhost.localdomain localhost/" /etc/hosts
    sed -i -e "s/\(127\.0\.1\.1.*\)/127.0.1.1 $FQDN $HOSTNAME localhost.localdomain localhost/" /etc/hosts
    # Fix Ubuntu/Debian Hostname
    echo "$FQDN" > /etc/hostname
    hostname $FQDN
else
    HOSTNAME=$(cat /etc/hostname)
    FQDN="${HOSTNAME}.${DOMAINNAME}"
fi

export FQDN
# Fix CentOs/RedHat Hostname
if [ -f /etc/sysconfig/network ] ; then
  sed -i -e "s/HOSTNAME=.*/HOSTNAME=$FQDN/" /etc/sysconfig/network
fi

# Set domainname (for dns)
echo "$DOMAINNAME" > /etc/domainname

set -e
set -x
admin_net='
{
  "name": "admin",
  "deployment": "system",
  "conduit": "1g0",
  "ranges": [
    {
      "name": "admin",
      "first": "192.168.124.10/24",
      "last": "192.168.124.11/24"
    },
    {
      "name": "host",
      "first": "192.168.124.81/24",
      "last": "192.168.124.254/24"
    },
    {
      "name": "dhcp",
      "first": "192.168.124.21/24",
      "last": "192.168.124.80/24"
    }
  ]
}'

admin_node="
{
  \"name\": \"$FQDN\",
  \"admin\": true,
  \"alive\": false,
  \"bootenv\": \"local\"
}
"
###
# This should vanish once we have a real bootstrapping story.
###
ip_re='([0-9a-f.:]+/[0-9]+)'

# Update the provisioner server template to use whatever
# proxy the admin node should be using.
if [[ $http_proxy ]]; then
    crowbar roles set provisioner-server \
        attrib provisioner-upstream_proxy \
        to "{\"value\": \"${http_proxy}\"}"
fi
crowbar roles set provisioner-os-install \
    attrib provisioner-target_os \
    to '{"value": "centos-6.5"}'

# Create a stupid default admin network
crowbar networks create "$admin_net"
#curl -s -f --digest -u $(cat /etc/crowbar.install.key) \
#    -X POST http://localhost:3000/network/api/v2/networks \
#    -d "name=admin" \
#    -d "deployment=system" \
#    -d "conduit=1g0"  \
#    -d 'ranges='

# Create the admin node entry.
crowbar nodes create "$admin_node"
#curl -s -f --digest -u $(cat /etc/crowbar.install.key) \
#    -X POST http://localhost:3000/api/v2/nodes \
#    -d "name=$FQDN" \
#    -d 'admin=true' \
#    -d 'alive=false' \
#    -d 'bootenv=local'

# Figure out what IP addresses we should have, and add them.
netline=$(curl -f --digest -u $CROWBAR_KEY \
    -X GET "http://localhost:3000/api/v2/networks/admin/allocations" \
    -d "node=$FQDN")
nets=(${netline//,/ })
for net in "${nets[@]}"; do
    [[ $net =~ $ip_re ]] || continue
    net=${BASH_REMATCH[1]}
    # Make this more complicated and exact later.
    ip addr add "$net" dev eth0 || :
    echo "${net%/*} $FQDN" >> /etc/hosts || :
done

# flag allows you to stop before final step
if ! [[ $* = *--zombie* ]]; then

  # Mark the node as alive.
  crowbar nodes update "$FQDN" '{"alive": true}'
  #curl -s -f --digest -u $(cat /etc/crowbar.install.key) \
  #    -X PUT "http://localhost:3000/api/v2/nodes/$FQDN" \
  #    -d 'alive=true'
  echo "Configuration Complete, you can watch annealing from the UI"
  # Converge the admin node.
  crowbar converge && exit 0
  echo "Could not converge all noderoles!"
  exit 1
else
  echo "To complete configuration, mark node alive using: crowbar nodes update 1 '{""alive"": true}'"
fi
