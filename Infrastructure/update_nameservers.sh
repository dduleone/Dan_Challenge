echo "Rotue53 Zone created. Updating domain nameservers."
aws route53domains update-domain-nameservers \
    --region us-east-1 \
    --domain-name ${DOMAIN_NAME} \
    --profile dduleone\
    --nameservers \
        Name=${NS1} \
        Name=${NS2} \
        Name=${NS3} \
        Name=${NS4}
