#!/bin/bash

#Variable to store the Git Repository
Git_Repo="https://github.com/laravel/laravel"

#update and upgrade the system
sudo apt update

sudo apt upgrade -y

#Install the required packages
echo -e "\n" | sudo add-apt-repository ppa:ondrej/php

sudo apt install php8.2 -y

sudo apt install php8.2-curl php8.2-dom php8.2-mbstring php8.2-xml php8.2-mysql zip unzip -y

sudo apt install apache2 -y

#Enable the required modules
sudo a2enmod rewrite

#Restart the apache2 service
sudo systemctl restart apache2

cd /usr/bin
#Install composer
curl -sS https://getcomposer.org/installer | sudo php

sudo mv composer.phar composer


cd /var/www

#Clone the laravel repository
sudo git clone $Git_Repo

cd laravel/

#Install the laravel dependencies
sudo composer install --optimize-autoloader --no-dev --no-interaction 
composer update --no-interaction
sudo cp .env.example .env

#Generate the application key
sudo php artisan key:generate

#Change the ownership of the laravel directory
ps aux | grep "apache" | awk '{print $1}' | grep -v root | head -n 1

sudo chown -R www-data storage
sudo chown -R www-data bootstrap/cache

#Create a virtual host for the laravel application
cd /etc/apache2/sites-available/
sudo tee /etc/apache2/sites-available/laravel.conf <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/laravel/public

    <Directory /var/www/laravel>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF


#Disable the default site and enable the laravel site
sudo a2dissite 000-default.conf
sudo a2ensite laravel.conf
sudo systemctl reload apache2

#Install MySQL
sudo apt install mysql-server -y
sudo apt install mysql-client -y

#Create a database and user for the laravel application
sudo mysql -uroot -e "CREATE DATABASE Jovals;"
sudo mysql -uroot -e "CREATE USER 'Kene'@'localhost' IDENTIFIED BY 'Kene@12345';"
sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON Jovals.* TO 'Kene'@'localhost';"
sudo mysql -uroot -e "FLUSH PRIVILEGES;"

cd /var/www/laravel/

#Update the .env file with the database details
sudo sed -i 's/DB_CONNECTION=sqlite/DB_CONNECTION=mysql\nDB_HOST=127.0.0.1\nDB_PORT=3306\nDB_DATABASE=Jovals\nDB_USERNAME=Kene\nDB_PASSWORD=Kene@12345/' .env

#Migrate the database
sudo php artisan migrate --no-interaction 

#Restart the apache2 service
sudo systemctl restart apache2

echo "LAMP Stack deployment and laravel Appliction is now available"