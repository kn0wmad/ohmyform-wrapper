#!/bin/sh

export HOST_IP=$(ip -4 route list match 0/0 | awk '{print $3}')

if [ ! -f /root/ohmyform.db ]; then
    mkdir /root/www
    mkdir /root/data
    ohmyform config init
    ohmyform config set --address=0.0.0.0 --port=3000 --root=/root/data
    password=$(cat /dev/urandom | base64 | head -c 16)
    echo 'version: 2' > /root/start9/stats.yaml
    echo 'data:' >> /root/start9/stats.yaml
    echo '  Default Username:' >> /root/start9/stats.yaml
    echo '    type: string' >> /root/start9/stats.yaml
    echo '    value: admin' >> /root/start9/stats.yaml
    echo '    description: This is your default username.' >> /root/start9/stats.yaml
    echo '    copyable: true' >> /root/start9/stats.yaml
    echo '    masked: false' >> /root/start9/stats.yaml
    echo '    qr: false' >> /root/start9/stats.yaml
    echo '  Default Password:' >> /root/start9/stats.yaml
    echo '    type: string' >> /root/start9/stats.yaml
    echo '    value: "'"$password"'"' >> /root/start9/stats.yaml
    echo '    description: This is your randomly-generated, default password.' >> /root/start9/stats.yaml
    echo '    copyable: true' >> /root/start9/stats.yaml
    echo '    masked: true' >> /root/start9/stats.yaml
    echo '    qr: false' >> /root/start9/stats.yaml
fi

lighttpd -f /etc/lighttpd/httpd.conf

exec tini ohmyform
