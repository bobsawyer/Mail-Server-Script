#!/bin/bash
#
#-----------------------------------------#
###Welcome to the apache setup script. Any variables that may need to be adjusted should be changed in the designated "variables" section in the main script.
#-----------------------------------------#

sudo $package_manager install httpd24 mod24_ssl -y

httpd_secure=(SSLCertificateFile SSLCertificateKeyFile SSLProtocol)

for var in ${httpd_secure[*]}; do
    temp="$(grep ^$var $httpd_ssl_conf)"
    if [ "$temp" != "" ]; then
        echo "Updating variable..." 
        sudo ./perl-find-replace "$temp" "$var ${!var}" "$httpd_ssl_conf"
    else
        echo "Writing variable..."
        echo "$var ${!var}" | sudo tee -a "$httpd_ssl_conf"
    fi
    
done

temp="$(grep ^DirectoryIndex $httpd_conf)"
if [ "$temp" != "" ]; then
    echo "Updating variable..." 
    sudo ./perl-find-replace "$temp" "DirectoryIndex index.html index.html.var index.php" "$httpd_conf"
else
    echo "Writing variable..."
    echo "DirectoryIndex index.html index.html.var index.php" | sudo tee -a "$httpd_conf"
fi

start_tag="####CURRENT BUILD !!!! LEAVE THIS TAG LINE INTACT IF YOU PLAN TO EVER USE THE SETUP SCRIPT AGAIN OR BE READY TO REINSTALL DOVECOT... DO NOT REMOVE####"
end_tag="####END OF CURRENT BUILD... YOU MAY ADJUST SETTINGS OUTSIDE OF THIS TAG, OR IF YOU WISH TO CHANGE SETTINGS IN THIS TAG, ADJUST dovecot.sh AND RERUN THE SETUP"

sudo mkdir -p "/var/www/vhosts/$mydomain/httpdocs"
sudo mkdir -p "/var/www/vhosts/$mydomain/httpsdocs"

sudo sed -i "/$start_tag/,/$end_tag/d" "$httpd_conf"

echo "$start_tag

<VirtualHost *:80>
        <Directory /var/www/vhosts/$mydomain/httpdocs>
        AllowOverride All
        </Directory>
        DocumentRoot /var/www/vhosts/$mydomain/httpdocs
        ServerName $mydomain
	Redirect permanent /mail https://$mydomain/mail
</VirtualHost>

#NameVirtualHost *:443

<VirtualHost *:443>
        SSLEngine on
        SSLProtocol all -SSLv2 -SSLv3
        SSLCertificateFile $smtpd_tls_cert_file
        SSLCertificateKeyFile $smtpd_tls_key_file
        <Directory /var/www/vhosts/$mydomain/httpsdocs>
        AllowOverride All
        </Directory>
        DocumentRoot /var/www/vhosts/$mydomain/httpsdocs
        ServerName $mydomain
	Alias /mail /usr/local/squirrelmail/www

        <Directory /usr/local/squirrelmail/www>
        Options None
        AllowOverride None
        DirectoryIndex index.php
        Require all granted
        </Directory>
        <Directory /usr/local/squirrelmail/www/*>
        Require all denied
        </Directory>
        <Directory /usr/local/squirrelmail/www/scripts>
        Require all granted
        </Directory>
        <Directory /usr/local/squirrelmail/www/images>
        Require all granted
        </Directory>
        <Directory /usr/local/squirrelmail/www/plugins>
        Require all granted
        </Directory>
        <Directory /usr/local/squirrelmail/www/src>
        Require all granted
        </Directory>
        <Directory /usr/local/squirrelmail/www/templates>
        Require all granted
        </Directory>
        <Directory /usr/local/squirrelmail/www/themes>
        Require all granted
        </Directory>
        <Directory /usr/local/squirrelmail/www/contrib>
        Require ip 127
        Require ip 10
        Require ip 192
        </Directory>
        <Directory /usr/local/squirrelmail/www/doc>
        Order Deny,Allow
        Require ip 127
        Require ip 10
        Require ip 192
        </Directory>
</VirtualHost>

$end_tag" | sudo tee -a "$httpd_conf"
