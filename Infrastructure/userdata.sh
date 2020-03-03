#!/bin/bash
sudo yum -y install httpd

sudo echo '<html> <head> <title>Hello World</title> </head> <body> <h1>Hello World!</h1> </body> </html>' > /var/www/html/index.html;

sudo apachectl start
