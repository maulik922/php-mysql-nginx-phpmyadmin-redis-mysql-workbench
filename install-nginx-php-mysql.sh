#!/bin/bash

# Declare the required packages
install=("nginx" "php7.4-fpm" "php8.2-fpm" "phpmyadmin" "mysql-server" "redis" "mysql-workbench" "git")

# Declare the required extensions
extensions=("php-redis" "json" "curl/php" "intl" "mbstring" "mysqlnd" "imagick" "gd" "simplexml" "curl" "php-intl")

# Declare the required variables
db_name="database_name"
db_user="database_user"
db_password="database_password"

# Declare the paths for nginx configuration files
php7_path="/etc/nginx/sites-available/php7"
php8_path="/etc/nginx/sites-available/php8"

# Declare the paths for .env files
env7_path="/var/www/html/php7.4/.env"
env8_path="/var/www/html/php8.2/.env"

# Declare the paths Log
LOG_FILE="install.log"


# Update package repositories
echo "Updating package repositories..." | tee -a $LOG_FILE
sudo apt-get update >> $LOG_FILE 2>&1

# Check the version of Linux
echo "Check the version of Linux..." | tee -a $LOG_FILE
version=$(lsb_release -sr)
if [ $version -lt 20 ]; then
    echo "Your Linux version is less than 20. Installation stopped."
    exit 1
fi >> $LOG_FILE 2>&1

# Install the required packages and extensions
echo "Install the required packages and extensions" | tee -a $LOG_FILE
for package in "${install[@]}"; do
    apt-get install -y $package
done

for extension in "${extensions[@]}"; do
    apt-get install -y $extension
done >> $LOG_FILE 2>&1

# Create the database and user
echo "Create the database and user" | tee -a $LOG_FILE
mysql -u root  << EOF
CREATE DATABASE $db_name;
CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';
EOF
>> $LOG_FILE 2>&1

# Unlink defult file  & delete 
sudo unlink /etc/nginx/sites-enabled/default
sudo rm /etc/nginx/sites-enabled/default

# create the directory 
sudo mkdir /var/www/html/php7.4
sudo mkdir /var/www/html/php8.2

# Create the nginx configuration files
echo "Create the nginx configuration files" | tee -a $LOG_FILE

echo "server {
    listen 80;
    listen [::]:80;

    root /var/www/html/php7.4/;
    index index.php index.html index.htm;

    server_name your_domain.com;

       location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        
    }

    location /phpmyadmin {
    root /usr/share/;
    index index.php index.html index.htm;
    location ~ ^/phpmyadmin/(.+\.php)$ {
   #     try_files $uri =404;
        root /usr/share/;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        fastcgi_index index.php;
    #    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }

    location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
        root /usr/share/;
    }
}
      location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }
    
    location ~ /\.ht {
        deny all;
    }
}" > $php7_path
ln -s $php7_path /etc/nginx/sites-enabled/
service nginx restart 

echo "server {
    listen 81;
    listen [::]:81;

    root /var/www/html/php8.2/;
    index index.php index.html index.htm;

    server_name your_domain.com;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        
    }

    location /phpmyadmin {
    root /usr/share/;
    index index.php index.html index.htm;
    location ~ ^/phpmyadmin/(.+\.php)$ {
     #   try_files $uri =404;
        root /usr/share/;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
      #  fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }

    location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
        root /usr/share/;
    }
}

      location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }
    location ~ /\.ht {
        deny all;
    }
}" > $php8_path
ln -s $php8_path /etc/nginx/sites-enabled/
service nginx restart >> $LOG_FILE 2>&1

# Create the .env files
echo "Create the .env files" | tee -a $LOG_FILE

echo "DB_NAME=$db_name
DB_USER=$db_user
DB_PASSWORD=$db_password" > $env7_path

echo "DB_NAME=$db_name
DB_USER=$db_user
DB_PASSWORD=$db_password" > $env8_path

>> $LOG_FILE 2>&1

# Restart services
systemctl restart nginx php7.4-fpm php8.2-fpm mysql redis-server

# Done
echo "Installation complete. See installation.txt for details."

# Store all installations with details in a text file
echo "Installed packages:" > installations.txt
printf '%s\n' "${install[@]}" >> installations.txt
echo "Installed extensions:" >> installations.txt
printf '%s\n' "${extensions[@]}" >> installations.txt
echo "Database name: $db_name" >> installations.txt
echo "Database user: $db_user" >> installations.txt
echo "Nginx configuration path for PHP 7.4: $php7_path" >> installations.txt
echo "Nginx configuration path for PHP 8.2: $php8_path" >> installations.txt

#sudo apt list --installed > installation.log
