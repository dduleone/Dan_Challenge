#!/bin/bash
#
# Automated tests to validate the correctness of the server configuration
#
# What we're validating:
#   - For both dule1.com and www.dule1.com:
#       - Validate that http requests return 301 redirect responses
#       - Validate that http request 301 redirects to the https content
#       - Validate that https requests return the correct content
#

# Baseline hash of expected content
CHECKSUM="$(echo '<html> <head> <title>Hello World</title> </head> <body> <h1>Hello World!</h1> </body> </html>' | md5)";

# Get status code from http://dule1.com
STATUS_ON_HTTP_ROOT="$(curl -s 'http://dule1.com' -I | head -n1 | awk '{print $2}')";

# Get status code from http://www.dule1.com
STATUS_ON_HTTP_WWW="$(curl -s 'http://www.dule1.com' -I | head -n1 | awk '{print $2}')";

# Get hash from content returned from http://dule1.com, post redirect
HASH_ON_HTTP_ROOT_REDIRECTS="$(curl -Ls 'http://dule1.com' | md5)";

# Get hash from content returned from http://www.dule1.com, post redirect
HASH_ON_HTTP_WWW_REDIRECTS="$(curl -Ls 'http://www.dule1.com' | md5)";

# Get hash from content returned from https://dule1.com
HASH_ON_HTTPS_ROOT="$(curl -s 'https://dule1.com' | md5)";

# Get hash from content returned from https://www.dule1.com
HASH_ON_HTTPS_WWW="$(curl -s 'https://www.dule1.com' | md5)";

# Correct response (301 redirect) on http://dule1.com
if [[ "${STATUS_ON_HTTP_ROOT}" == "301" ]]; then
    echo "Successfully received 301 redirect on http://dule1.com";
else
    echo "ERROR! http://dule1.com is not returning a 301 redirect";
fi

# Correct response (301 redirect) on http://www.dule1.com
if [[ "${STATUS_ON_HTTP_WWW}" == "301" ]]; then
    echo "Successfully received 301 redirect on http://www.dule1.com";
else
    echo "ERROR! http://www.dule1.com is not returning a 301 redirect";
fi

# Correctly redirects http://dule1.com to https://dule1.com
if [[ "${HASH_ON_HTTP_ROOT_REDIRECTS}" == "${HASH_ON_HTTPS_ROOT}" ]]; then
    echo "Successfully received correct payload on http://dule1.com (after redirect to HTTPS)";
else
    echo "ERROR! http://dule1.com is not redirecting to https://dule1.com";
fi

# Correctly redirects http://www.dule1.com to https://www.dule1.com
if [[ "${HASH_ON_HTTP_WWW_REDIRECTS}" == "${HASH_ON_HTTPS_WWW}" ]]; then
    echo "Successfully received correct payload on http://www.dule1.com (after redirect to HTTPS)";
else
    echo "ERROR! http://www.dule1.com is not redirecting to https://www.dule1.com";
fi

# Correctly serves https://dule1.com
if [[ "${HASH_ON_HTTPS_ROOT}" == "${CHECKSUM}" ]]; then
    echo "Successfully received correct payload on https://dule1.com";
else
    echo "ERROR! https://dule1.com serving the wrong content";
fi

# Correctly serves https://www.dule1.com
if [[ "${HASH_ON_HTTPS_WWW}" == "${CHECKSUM}" ]]; then
    echo "Successfully received correct payload on https://www.dule1.com";
else
    echo "ERROR! https://www.dule1.com serving the wrong content";
fi

# Can SSH to EC2 instances
EC2_INSTANCES="$(aws ec2 describe-instances --filters Name=tag:Application,Values=dule1.com --profile dduleone | jq -r '.Reservations[].Instances[].PublicIpAddress')";
for ec2 in ${EC2_INSTANCES}; do
    IP=$(ssh -i ~/.ssh/DuLeoneAWSKey.pem -o StrictHostKeyChecking=no ec2-user@${ec2} "curl -s http://ifconfig.me")
    if [[ "${IP}" == "${ec2}" ]]; then
        echo "Successfully connected to ${IP} via SSH (Port: 22)";
    else
        echo "ERROR! Failed to connect to ${ec2} via SSH (Port: 22)";
    fi
done;