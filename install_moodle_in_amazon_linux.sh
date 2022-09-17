#!/bin/sh
sudo yum update -y
sudo amazon-linux-extras install nginx1 php7.4 -y
sudo yum clean metadata
sudo yum install git mariadb-server php-{pear,cgi,common,curl,mbstring,gd,mysqlnd,gettext,bcmath,json,xml,fpm,intl,zip} -y
# Back up existing config
sudo cp -R /etc/nginx /etc/nginx-backup
sudo chmod -R 777 /var/log
sudo chown -R ec2-user:ec2-user /usr/share/nginx/html
echo "<?php phpinfo(); ?>" > /usr/share/nginx/html/index.php
sudo sed -i 's|;*user = nginx|user = nginx|g' /etc/php-fpm.d/www.conf
sudo sed -i 's|;*group = nginx|group = nginx|g' /etc/php-fpm.d/www.conf
sudo sed -i 's|;*pm = ondemand|pm = ondemand|g' /etc/php-fpm.d/www.conf
# configure php
sudo sed -i 's|;cgi.fix_pathinfo=1|cgi.fix_pathinfo=0|g' /etc/php.ini
sudo sed -i 's|;*expose_php=.*|expose_php=0|g' /etc/php.ini
#sudo sed -i 's|;*memory_limit = 128M|memory_limit = 512M|g' /etc/php.ini
sudo sed -i 's|;*post_max_size = 8M|post_max_size = 50M|g' /etc/php.ini
sudo sed -i 's|;*upload_max_filesize = 2M|upload_max_filesize = 10M|g' /etc/php.ini
sudo sed -i 's|;*max_file_uploads = 20|max_file_uploads = 20|g' /etc/php.ini
# nginx.conf
cat << EOF > /etc/nginx/nginx.conf
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;
events {
    worker_connections 1024;
}
http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;
    server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html/moodle;
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Content-Type-Options "nosniff";
        index index.php;
        charset utf-8;
        location / {
            try_files \$uri \$uri/ /index.php?\$query_string;
        }
        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt { access_log off; log_not_found off; }
        error_page 404 /index.php;
        location ~ \.php$ {
            fastcgi_pass unix:/var/run/php-fpm/www.sock;
            fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
            include fastcgi_params;
        }
        location ~ /\.(?!well-known).* {
            deny all;
        }
    }
}
EOF
for i in nginx php-fpm mariadb; do sudo systemctl enable $i --now; done
for i in nginx php-fpm mariadb; do sudo systemctl start $i; done
# lets encrypt
#sudo amazon-linux-extras install epel -y
#sudo yum install certbot certbox-nginx -y 
#sudo systemctl restart nginx.service

# Install Moodle
sudo yum install git -y
git clone https://github.com/moodle/moodle.git
cp -R moodle /usr/share/nginx/html
chown -R nginx:nginx /usr/share/nginx/html/moodle
chmod -R 777 /usr/share/nginx/html/moodle

# Setup Moodle Data Folder
mkdir /usr/share/nginx/html/moodle_data
chmod -R 777 /usr/share/nginx/html/moodle_data