#!bin/bash

sources='https://raw.githubusercontent.com/yuukuun/v2fly/main/'
export sources

read -p "Please inter domain : " url
###判断 8
temp=$(cat /etc/redhat-release)
if [[ "$temp" == "CentOS Linux release 8"* ]];then
echo "$temp"
dnf remove -y epel-release
dnf install -y epel-release
dnf install -y certbot python3-certbot-nginx
###判断 7
elif [[ "$temp" == "CentOS Linux release 7"* ]];then
echo "$temp"
yum remove -y epel-release
yum install -y epel-release
yum install -y yum-utils certbot python2-certbot-nginx 
else
    echo "##### install f2fly error !!! #####"
fi
### 安装nginx
mkdir -p /usr/local/nginx/ssl /usr/local/nginx/conf.d
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config
yum install -y gcc gcc-c++ vim libtool zip perl-core zlib-devel wget pcre* unzip automake autoconf make curl

cd /tmp
wget https://www.openssl.org/source/openssl-1.1.1a.tar.gz && tar xzvf openssl-1.1.1a.tar.gz 
wget http://nginx.org/download/nginx-1.18.0.tar.gz && tar xf nginx-1.18.0.tar.gz && rm nginx-1.18.0.tar.gz
cd nginx-1.18.0
./configure --prefix=/usr/local/nginx --with-openssl=../openssl-1.1.1a --with-openssl-opt='enable-tls1_3' \
--with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module \
--with-http_sub_module --with-stream --with-stream_ssl_module && make && make install

### nginx 配置
rm -rf /usr/local/nginx/conf/nginx.conf
if [[ "$temp" == "CentOS Linux release 8"* ]]; then
wget -c "$sources"bash/nginx8.conf -O /usr/local/nginx/conf/nginx.conf 
elif [[ "$temp" == "CentOS Linux release 7"* ]];then
wget -c "$sources"bash/nginx.conf -O /usr/local/nginx/conf/nginx.conf 
else
    echo "##### Nginx config error !!! #####"
fi
###nginx 启动
cat >/etc/systemd/system/nginx.service<<-EOF
[Unit]
Description=nginx
After=network.target
[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

systemctl start firewalld.service
firewall-cmd --add-service=http
firewall-cmd --add-service=https
firewall-cmd --add-port=19631/tcp
firewall-cmd --runtime-to-permanent
firewall-cmd --reload 
systemctl enable firewalld.service

/usr/local/nginx/sbin/nginx -t
/usr/local/nginx/sbin/nginx -s reload
systemctl restart nginx.service
systemctl enable nginx.service
### ssl
rm -rf /usr/local/nginx/conf.d/$url.conf
certbot certonly --webroot -w /usr/local/nginx/html/ -d $url -m 0@yahoo.com --agree-tos
rm -rf /usr/local/nginx/conf/nginx.conf

if [[ "$temp" == "CentOS Linux release 8"* ]]; then
wget -c "$sources"bash/nginxSSL8.conf -O /usr/local/nginx/conf.d/$url.conf 
elif [[ "$temp" == "CentOS Linux release 7"* ]];then
wget -c "$sources"bash/nginxSSL.conf -O /usr/local/nginx/conf.d/$url.conf 
else
    echo "##### Nginx config SSL error !!! #####"
fi

mkdir /usr/local/nginx/$url
cp -r /usr/local/nginx/html/* /usr/local/nginx/$url/
sed -i "s%\$urls%$url%g" /usr/local/nginx/conf.d/$url.conf

/usr/local/nginx/sbin/nginx -t
/usr/local/nginx/sbin/nginx -s reload
systemctl restart nginx.service

### v2fly install
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
uuid=$(cat /proc/sys/kernel/random/uuid)
cat >/usr/local/etc/v2ray/config.json<<-EOF
{
  "log" : {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbound": {
    "port": 11234,
    "listen":"127.0.0.1",
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$uuid",
          "level": 1,
          "alterId": 64,
          "email": "akcp1234@gmail.com"
        }
      ]
    },
     "streamSettings": {
      "network": "ws",
      "wsSettings": {
         "path": "/7ba7"
        }
     }
  },
  "outbound": {
    "protocol": "freedom",
    "settings": {}
  }
}
EOF
systemctl start v2ray.service
systemctl enable v2ray.service
systemctl status v2ray.service
