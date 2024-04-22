# SECOND SEMESTER EXAM PROJECT

## QUESTION

Automate the provisioning of two Ubuntu-based servers, named “Master” and “Slave”, using Vagrant.
On the Master node, create a bash script to automate the deployment of a LAMP (Linux, Apache, MySQL, PHP) stack.

This script should clone a PHP application from GitHub, install all necessary packages, and configure Apache web server and MySQL.

Ensure the bash script is reusable and readable.

Using an Ansible playbook:

1. Execute the bash script on the Slave node and verify that the PHP application is accessible through the VM’s IP address (take screenshot of this as evidence)
2. Create a cron job to check the server’s uptime every 12 am.

Requirements

1. Submit the bash script and Ansible playbook to (publicly accessible) GitHub repository.
2. Document the steps with screenshots in md files, including proof of the application’s accessibility (screenshots taken where necessary)
3. Use either the VM’s IP address or a domain name as the URL.

PHP Laravel GitHub Repository:

https://github.com/laravel/laravel

# STEPS (DOCUMENTATIONS)

## Bash script

`sudo apt update`

`sudo apt upgrade -y`

First, system is update and upgraded with the commands above

1. `echo -e "\n" | sudo add-apt-repository ppa:ondrej/php`

This command adds a Personal Package Archive (PPA) maintained by Ondřej Surý, which contains PHP packages, to the system's list of repositories. This enables the system to install PHP8.2 packages from this PPA using the APT package manager

2. `sudo apt install php8.2 -y`

`sudo apt install php8.2-curl php8.2-dom php8.2-mbstring php8.2-xml php8.2-mysql zip unzip -y`

`sudo apt install apache2 -y`

These commands intalls apache, php8.2 which is the least version of php needed to work with laravel and also the php dependencies

3.  `sudo a2enmod rewrite`

`sudo systemctl restart apache2`

These commands tells Apache to enable the rewrite module provided by Apahe HTTP server distributions, allowing you to use its features in configuring how Apache handles incoming requests and URLs. And the next command restarts apache

4. `cd /usr/bin`

`curl -sS https://getcomposer.org/installer | sudo php`

`sudo mv composer.phar composer`

These commands goes into the /usr/bin/ directory, downloads and install composer from a remote website and renames the composer.phar to composer which helps us run composer commands more conveniently

5. `cd /var/www`

`sudo git clone $Git_Repo`

These commands goes into the /var/www/ directory and clones the laravel github repository

6.  `sudo composer install --optimize-autoloader --no-dev --no-interaction`
    `composer update --no-interaction`
    `sudo cp .env.example .env`

These commands will install the project dependencies (composer.json), optimize the autoloader for better performance, skips installation of development dependencies, copying the .env.example into the a new file .env which we can customize with our configuration settings

7. `sudo php artisan key:generate`

with this command, Laravel will generate a new random application key and update your .env file with this new key.

8. `ps aux | grep "apache" | awk '{print $1}' | grep -v root | head -n 1`

`sudo chown -R www-data storage`
`sudo chown -R www-data bootstrap/cache`

These commands first gives us the username of the first non-root process related to Apache HTTP Server "www-data" so that we change the ownership of storage and bootstrap/cache to the username of the first non-root process.

9.  `cd /etc/apache2/sites-available/`
    `sudo tee /etc/apache2/sites-available/laravel.conf` <<`EOF`
    `<VirtualHost *:80>`
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/laravel/public

        <Directory /var/www/laravel>
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log`
        CustomLog ${APACHE_LOG_DIR}/access.log combined

    `</VirtualHost>`
    `EOF`

These command goes into the sites-availale directory, creates a new configuration file called "laravel.conf" and populate it with the configuration above

10. `sudo a2dissite 000-default.conf`
    `sudo a2ensite laravel.conf`
    `sudo systemctl reload apache2`

These commands disables the apache default configuration, enables the new configuration that was created and reloads apache

11. `sudo apt install mysql-server -y`
    `sudo apt install mysql-client -y`

These commands installs mySQL server and mySQL client

12. `sudo mysql -uroot -e "CREATE DATABASE Jovals;"`
    `sudo mysql -uroot -e "CREATE USER 'Kene'@'localhost' IDENTIFIED BY 'Kene@12345';"`
    `sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON Jovals.* TO 'Kene'@'localhost';"`
    `sudo mysql -uroot -e "FLUSH PRIVILEGES;"`

These command are setting up a new mySQL database. It creates a new database "Jovals", a new user "Kene" with a password "Kene@12345", grants all privileges on the database to the new user and reloads the privileges from the grant tables in the mySQL database

13. `cd /var/www/laravel/`

`sudo sed -i 's/DB_CONNECTION=sqlite/DB_CONNECTION=mysql\nDB_HOST=127.0.0.1\nDB_PORT=3306\nDB_DATABASE=Jovals\nDB_USERNAME=Kene\nDB_PASSWORD=Kene@12345/' .env`

These commands first moves to the laravel directory and then modifies the .env file with the contents in single quotes ('')database connection settings related to SQLite and mySQL settings as specified with the stream editor command(sed).

14. `sudo php artisan migrate --no-interaction`
    `sudo systemctl restart apache2`

with these commands, Laravel will generate a new random application key and update your .env file with this new key and then apache is restarted.

## Ansible Playbook
There are 2 ansible playbooks here. One is the normal playbook and another one is much cleaner with the use of roles.

For more explaination i will write on the one with roles

`---
- hosts: all
  become: true
  roles:
    - role: Change_Own
    - role: LAMP_stack
    - role: Check_PHP_App_Access
    - role: Cronjob`

This ansible playbook makes use of roles to change owner of the bash scrip using the copy module with the "Change_Own" role. It runs a bash script with the "LAMP_stack" role. It creates a cronjob that checks the uptime of the server at midnight with the "Cronjob" role. It also checks the php appliction is accessible with the "Check_PHP_App_Acess" role.

Below is the task for the Change_Own role

`#Changing Script ownership
- name: Change ownership of Script
  copy:
    src: /home/vagrant/Exam_Project/LAMP_stack.sh
    dest: /home/vagrant/LAMP_stack.sh
    mode: "0775"`

Below is the task for the LAMP_stack role

`#Installing LAMP stack
- name: install LAMP stack with bash script
  tags: ubuntu, LAMP, php, mySQL
  shell: ./LAMP_stack.sh`

Below is the task for the Cronjob role

`#Cronjob to check server uptime at 12am
- name: Add cron Job for uptime check
  cron:
    name: "Check server Uptime Check"
    minute: "0"
    hour: "0"
    job: "uptime >> /var/log/server_uptime.log"

- name: Notify user
  command: "server uptime is save in /var/log/server_uptime.log"`

Below is the task for the Check_PHP_App_Acess

`#Check PHP application accessibility
- name: Check if PHP application homepage is accessible
  uri:
    url: "http://192.168.56.27"
  register: php_out
  ignore_errors: true

- name: Display message if PHP application is accessible
  debug:
    msg: "PHP application is accessible"
  when: php_out.status == 200`

## Screenshots documentations
This is the IP address for my slave node
![screenshot of the above IP for slave node](/images/IP_Slave.PNG)

This is the screenshot of my playbook running on my master node
![screenshot of playbook sucess!!](/images/Playbook2_output.PNG)

This is the screenshot of my slave IP on a web browser
![screenshot of IP on a web browser](/images/Slave_page.PNG)

This is the screenshot of some of the erros i got
![Some errors!!](/images/error2.PNG)
This is the screenshot of some of the erros i got
![Some errors!!](/images/error.PNG)
