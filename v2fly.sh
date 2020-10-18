#!/bin/bash
### centos 8 centos 7 ubuntu 20
# --test-cert 是测试参数 67行
###初始化
# bash <(curl -L https://raw.githubusercontent.com/yuukuun/v2fly/main/v2fly.sh)

sources='https://raw.githubusercontent.com/yuukuun/v2fly/main/'
export sources
export redhat
export ubuntu
export url
export uuid

#######################函数#######################
centos8() {
	echo "CentOS 8"
dnf remove -y epel-release
dnf install -y epel-release
dnf install -y certbot python3-certbot-nginx gcc gcc-c++ vim libtool zip perl-core zlib-devel wget pcre* unzip automake autoconf make curl
}

centos7() {
 	echo "CentOS 7"
  yum remove -y epel-release
  yum install -y epel-release
  yum install -y yum-utils certbot python2-certbot-nginx gcc gcc-c++ vim libtool zip perl-core zlib-devel wget pcre* unzip automake autoconf make curl 
}

ubuntu20() {
	echo "Ubuntu 20"
apt-get update
apt-get install gcc vim libtool zip wget unzip build-essential libpcre3 libpcre3-dev zlib1g-dev automake autoconf make curl -y
snap install core; snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
}

insNginx() {
	echo "insNginx"
###安装 ningx
mkdir -p /usr/local/nginx/conf.d
cd /tmp
wget -c https://www.openssl.org/source/openssl-1.1.1a.tar.gz && tar xzvf openssl-1.1.1a.tar.gz 
wget -c http://nginx.org/download/nginx-1.18.0.tar.gz && tar xf nginx-1.18.0.tar.gz && rm nginx-1.18.0.tar.gz
cd nginx-1.18.0
./configure --prefix=/usr/local/nginx --with-openssl=../openssl-1.1.1a --with-openssl-opt='enable-tls1_3' \
--with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module \
--with-http_sub_module --with-stream --with-stream_ssl_module && make && make install
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
rm -rf /usr/local/nginx/conf/nginx.conf
}

addSSL() {
	echo "addSSL"
#certbot certonly --webroot -w /usr/local/nginx/html/ -d $url -m 0@yahoo.com --agree-tos --test-cert -n
certbot certonly --webroot -w /usr/local/nginx/html/ -d $url -m 0@yahoo.com --agree-tos -n
echo '10 4 * * * /usr/bin/certbot renew --dry-run "/usr/local/nginx/sbin/nginx -s reload"' >> /var/spool/cron/root
}

server() {
	echo "v2fly Server"
#bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
wget -c https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh && chmod +x install-release.sh && bash install-release.sh 
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
}

client() {
	echo "v2fly Client"
cat >/usr/local/nginx/$url/index.html<<-EOF
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- 上述3个meta标签*必须*放在最前面，任何其他内容都*必须*跟随其后！ -->
    <title>v2ray 客户端</title>
    <!-- Bootstrap -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@3.3.7/dist/css/bootstrap.min.css">
  </head>
  <body>
<div class="container"><div class="row">
<!-- 下载客户端 -->
<h4><div class="alert alert-success" align="center">下载客户端</div></h4>
<a type="button" class="btn btn-primary btn-lg" href="v2rayN-Core.zip" target="_blank">Windows客户端 v2rayN</a>
<a type="button" class="btn btn-primary btn-lg" href="v2rayNG.apk" target="_blank">安卓客户端 v2rayNG</a>
<a type="button" class="btn btn-primary btn-lg" href="https://apps.apple.com/us/app/shadowrocket/id932747118" target="_blank">苹果手机客户端 Shadowrocket</a>
<!--<a type="button" class="btn btn-primary btn-lg" href="v2rayNG_1.1.14.apk" target="_blank">IOS客户端</a>-->
<!-- 参数设置 -->
<h4><div class="alert alert-success" align="center">客户端参数</div></h4>
  <div class="table-responsive">
    <table class="table table-striped table-bordered table-hover">
      <tr><th>属性</tH><th>参数</th></tr>
      <tr><td>协议：</td><td>vmess</td></tr>
      <tr><td>域名地址：</td><td>$url</td></tr>
      <tr><td>UUID：</td><td>$uuid</td></tr>
      <tr><td>端口：</td><td>443</td></tr>
      <tr><td>额外ID：</td><td>64</td></tr>
      <tr><td>传输协议：</td><td>ws</td></tr>
      <tr><td>PATH：</td><td>/7ba7</td></tr>
      <tr><td>传输安全：</td><td>TLS</td></tr>
    </table>
  </div>  
<!-- 安卓客户端参数 -->
<h4><div class="alert alert-success " align="center">安卓客户端：域名和UUID修改成自己的</div>
<img class="img-responsive col-sm-12 col-md-6" src="android_1.jpg"/>
<img class="img-responsive col-sm-12 col-md-6" src="android_2.jpg"/>
</h4>
</div></div>
<!-- 这里写script -->
  </body>
</html>
EOF
cd /usr/local/nginx/$url/
wget -c "$sources"android_1.jpg
wget -c "$sources"android_2.jpg
wget -c "$sources"v2rayNG.apk
wget -c https://github.com/2dust/v2rayN/releases/download/3.23/v2rayN-Core.zip && unzip v2rayN-Core.zip && rm -rf /usr/local/nginx/$url/*.zip
cat >/usr/local/nginx/$url/v2rayN-Core/guiNConfig.json<<-EOP
{
  "inbound": [
    {
      "localPort": 10808,
      "protocol": "socks",
      "udpEnabled": true,
      "sniffingEnabled": true
    }
  ],
  "logEnabled": false,
  "loglevel": "warning",
  "index": 0,
  "vmess": [
    {
      "configVersion": 2,
      "address": "$url",
      "port": 443,
      "id": "$uuid",
      "alterId": 64,
      "security": "auto",
      "network": "ws",
      "remarks": "",
      "headerType": "none",
      "requestHost": "",
      "path": "/7ba7",
      "streamSecurity": "tls",
      "allowInsecure": "",
      "configType": 1,
      "testResult": "",
      "subid": ""
    }
  ],
  "muxEnabled": true,
  "domainStrategy": "IPIfNonMatch",
  "routingMode": "0",
  "useragent": [],
  "userdirect": [],
  "userblock": [],
  "kcpItem": {
    "mtu": 1350,
    "tti": 50,
    "uplinkCapacity": 12,
    "downlinkCapacity": 100,
    "congestion": false,
    "readBufferSize": 2,
    "writeBufferSize": 2
  },
  "listenerType": 2,
  "speedTestUrl": "http://speedtest-sgp1.digitalocean.com/10mb.test",
  "speedPingTestUrl": "https://www.google.com/generate_204",
  "urlGFWList": "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt",
  "allowLANConn": false,
  "enableStatistics": false,
  "keepOlderDedupl": false,
  "statisticsFreshRate": 2000,
  "remoteDNS": null,
  "defAllowInsecure": false,
  "subItem": [],
  "uiItem": {
    "mainSize": "968, 632",
    "mainLvColWidth": {
      "def": 30,
      "configType": 80,
      "remarks": 100,
      "address": 120,
      "port": 50,
      "security": 90,
      "network": 70,
      "subRemarks": 50,
      "testResult": 70
    }
  },
  "userPacRule": []
}
EOP
zip -r /usr/local/nginx/$url/v2rayN-Core.zip v2rayN-Core/ && rm -rf v2rayN-Core
}

#######################程序开始#######################
read -p "请输入自己的域名: " url
###判断安装
if [[ -f /etc/redhat-release ]]; then
systemctl start firewalld.service
firewall-cmd --add-service=http
firewall-cmd --add-service=https
firewall-cmd --runtime-to-permanent
firewall-cmd --reload 
systemctl enable firewalld.servic
systemctl stop firewalld.servic
	echo "v2fly redhat"
	redhat=$(cat /etc/redhat-release)
	if [[ "$redhat" == "CentOS Linux release 8"* ]]; then
		centos8 #
		insNginx
		wget -c "$sources"nginx8.conf -O /usr/local/nginx/conf/nginx.conf
		systemctl restart nginx.service
		wget -c "$sources"nginxSSL8.conf -O /usr/local/nginx/conf.d/$url.conf
	elif [[ "$redhat" == "CentOS Linux release 7"* ]]; then
		centos7 #
		insNginx
		wget -c "$sources"nginx.conf -O /usr/local/nginx/conf/nginx.conf
		systemctl restart nginx.service
		wget -c "$sources"nginxSSL.conf -O /usr/local/nginx/conf.d/$url.conf
	fi
elif [[ -f /etc/lsb-release ]]; then
	echo "v2fly lsb"
	ubuntu=$(cat /etc/lsb-release)
	if [[ "$ubuntu" == *"Ubuntu 20"* ]]; then
		ubuntu20
		insNginx
		wget -c "$sources"nginx.conf -O /usr/local/nginx/conf/nginx.conf
		systemctl restart nginx.service
		wget -c "$sources"nginxSSL.conf -O /usr/local/nginx/conf.d/$url.conf
	fi
fi
###SSL
mkdir /usr/local/nginx/$url
cp -r /usr/local/nginx/html/* /usr/local/nginx/$url/
sed -i "s%\$urls%$url%g" /usr/local/nginx/conf.d/$url.conf

addSSL
server
client

###备份与时间同步
mkdir ~/$url && cp -r /usr/local/nginx/$url ~/$url
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime


systemctl restart nginx.service
systemctl enable nginx.service

systemctl restart v2ray.service
systemctl enable v2ray.service

systemctl status nginx.service
systemctl status v2ray.service

# centos8
# centos7
# ubuntu20
# insNginx
# addSSL
# v2flySercer
# v2flyClient