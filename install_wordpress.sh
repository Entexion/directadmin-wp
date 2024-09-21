#!/bin/bash

# Check if user and domain are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directadmin_user> <domain>"
    exit 1
fi

DA_USER=$1
DOMAIN=$2
WP_PATH="/home/$DA_USER/domains/$DOMAIN/public_html"
WP_URL="https://wordpress.org/latest.tar.gz"

# Extract MySQL root password from DirectAdmin setup.txt
MYSQL_ROOT_PASSWORD=$(grep -oP 'mysql=\K.*' /usr/local/directadmin/conf/setup.txt)

# Ensure the MySQL root password is found
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    echo "Error: MySQL root password not found in /usr/local/directadmin/conf/setup.txt"
    exit 1
fi

# Ensure the domain directory exists
if [ ! -d "$WP_PATH" ]; then
    echo "Error: The directory $WP_PATH does not exist."
    echo "Make sure the domain $DOMAIN is already set up via DirectAdmin."
    exit 1
fi

# Warn the user about clearing the directory
echo "Warning: All files in the directory $WP_PATH will be deleted before the installation."
read -p "Are you sure you want to proceed? (y/n): " confirm

# Check user confirmation
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Installation aborted."
    exit 1
fi

# Step 0: Clear the destination directory
echo "Clearing the destination directory..."
rm -rf ${WP_PATH}/*
echo "Directory cleared."

# Function to check if a MySQL database exists
function database_exists() {
    DB_NAME=$1
    RESULT=$(mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES LIKE '$DB_NAME';" 2>/dev/null)
    if [ "$RESULT" ]; then
        return 0  # Database exists
    else
        return 1  # Database does not exist
    fi
}

# Generate database and user details, and check for existing databases
BASE_DB_NAME="${DA_USER}_wpdb"
BASE_DB_USER="${DA_USER}_wpuser"

DB_NAME=$BASE_DB_NAME
DB_USER=$BASE_DB_USER

# Check if database already exists, append random digits if it does
while database_exists $DB_NAME; do
    RANDOM_SUFFIX=$(shuf -i 100-999 -n 1)
    DB_NAME="${BASE_DB_NAME}${RANDOM_SUFFIX}"
    DB_USER="${BASE_DB_USER}${RANDOM_SUFFIX}"
    echo "Database $DB_NAME already exists. Trying $DB_NAME with random suffix."
done

# Generate a random password for the new MySQL user
DB_PASSWORD=$(openssl rand -base64 12)

# Ensure DirectAdmin user exists
if [ ! -d "/home/$DA_USER" ]; then
    echo "DirectAdmin user '$DA_USER' does not exist."
    exit 1
fi

# Step 1: Create MySQL database and user
echo "Creating MySQL database and user..."
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE $DB_NAME;"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

# Step 2: Download and extract WordPress
echo "Downloading and installing WordPress..."
cd $WP_PATH
wget $WP_URL -O latest.tar.gz
tar -xzf latest.tar.gz --strip-components=1
rm latest.tar.gz

# Step 3: Setup wp-config.php with database details
echo "Configuring wp-config.php..."
cp wp-config-sample.php wp-config.php
# Use | as delimiter for sed to avoid issues with / in variables
sed -i "s|database_name_here|$DB_NAME|" wp-config.php
sed -i "s|username_here|$DB_USER|" wp-config.php
sed -i "s|password_here|$DB_PASSWORD|" wp-config.php

# Step 4: Generate and Insert WordPress Salts
echo "Fetching and adding WordPress salts..."
SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
if [ -z "$SALT" ]; then
    echo "Error: Unable to fetch salts from WordPress API."
    exit 1
fi
# Insert the salts into wp-config.php by replacing the placeholder section
sed -i "/#@-/r /dev/stdin" wp-config.php <<< "$SALT"
sed -i "/#@+/,/#@-/d" wp-config.php

# Step 5: Install WordPress using WP-CLI
echo "Installing WordPress..."
# Generate a random admin password
WP_ADMIN_PASSWORD=$(openssl rand -base64 12)
WP_ADMIN_EMAIL="admin@$DOMAIN"

# Use WP-CLI to run the installation
wp core install --path=$WP_PATH --url="http://$DOMAIN" --title="$DOMAIN" --admin_user="admin" --admin_password="$WP_ADMIN_PASSWORD" --admin_email="$WP_ADMIN_EMAIL" --skip-email --allow-root

# Step 6: Update DirectAdmin configuration for MySQL
echo "Updating DirectAdmin configuration..."
echo "action=create&name=$DB_NAME&user=$DB_USER&passwd=$DB_PASSWORD&userlist=$DA_USER" > /usr/local/directadmin/data/users/$DA_USER/mysql.conf

# Ensure proper permissions
chown -R $DA_USER:$DA_USER $WP_PATH

# Step 7: Display WordPress admin credentials
WP_ADMIN_URL="http://$DOMAIN/wp-admin"
echo "WordPress installation complete for $DOMAIN"
echo "Admin Username: admin"
echo "Admin Password: $WP_ADMIN_PASSWORD"
echo "Login URL: $WP_ADMIN_URL"
