# directadmin-wp

Pre-requisite: wp-cli
Install with the following commands:

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

chmod +x wp-cli.phar

mv wp-cli.phar /usr/local/bin/wp

Why was this created?

Manually installing WordPress for each domain on a DirectAdmin server can be time-consuming and error-prone. This Bash script will automate this process and streamline the installation. It creates MySQL databases, and configures WordPress with ease. The script uses wp-cli to handle WordPress installations and database setup.

Why Use wp-cli?
wp-cli (WordPress Command Line Interface) is a tool for managing WordPress installations from the command line. While you can manually handle everything, wp-cli simplifies and automates many common tasks such as:

Installing WordPress;
Populating the WordPress database schema;
Creating an admin user;
Ensuring that all WordPress installation steps are completed without errors.

We use wp-cli here to handle the complexities of WordPress installation in an automated way, while maintaining the critical link with DirectAdmin. Although wp-cli can be used on its own to manage WordPress, this script integrates wp-cli and DirectAdmin to ensure everything is properly set up from both a WordPress and a DirectAdmin perspective.

This script performs the following tasks:

User Input and Confirmation: It accepts the DirectAdmin username and domain name as input. Before proceeding, it warns the user that the destination directory will be cleared and prompts for confirmation.
Database and User Setup: The script reads the MySQL access credentials from /usr/local/directadmin/conf/setup.txt and then creates a new MySQL database and user for WordPress. If the database already exists, it appends a random 3-digit suffix to ensure uniqueness.
Downloading and Installing WordPress: The script downloads the latest version of WordPress, extracts it into the domain’s public_html directory, and configures the wp-config.php file.
Populating the Database and Admin User Creation: Using wp-cli, the script populates the WordPress database with the default schema and creates an admin user (admin) with a randomly generated password.
DirectAdmin Integration: The script ensures that the newly created MySQL database and user are reflected in DirectAdmin’s configuration.
Displaying Admin Credentials: The script displays the WordPress admin credentials, including the login URL, username, and password, at the end of the process.

Usage: ./install_wordpress.sh <directadmin_username> <target_domain>

Feel free to modify as needed.

Cheers,
Ray
entexion.com
