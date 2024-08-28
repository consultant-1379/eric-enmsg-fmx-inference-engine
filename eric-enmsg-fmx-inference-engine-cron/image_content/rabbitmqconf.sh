#!/bin/bash
logfile="/var/log/messages"
retrieve_vault_token() {
while true; do
VAULT_TOKEN=$(curl -k -X GET "https://vault-service:8107/vault-service/1.0/token")
if [ $? -eq 0 ] ; then
echo "Retrieved token from Vaultserv" >> "$logfile"
break
else
echo "No Vaultserv VM available yet" >> "$logfile"
sleep 5
fi
done
}

write_rabbitmq_password() {
while true; do
retrieve_vault_token
result=$(curl -k -H "Accept:application/json" -H "Content-Type:application/json" -H "Vault-Token:${VAULT_TOKEN}" -X POST 'https://vault-service:8107/vault-service/1.0/secret/fmx/rabbitmmqSecret' -d '{"YWRtaW4=":"U2FsdGVkX1/Pa3pIhpt6hWZBMeR1a7KM7UAxv9u3hmg="}')
if [ $? -eq 0 ] ; then
echo "writing password to vaultservice is successful" >> "$logfile"
break
else
echo "writing password to vaultservice is failed" >> "$logfile"
sleep 5
fi
done
}


retrieve_rabbitmq_password() {
while true; do
retrieve_vault_token
result=$(curl -k -H "Accept:application/json" -H "Content-Type:application/json" -H "Vault-Token:${VAULT_TOKEN}" -X GET 'https://vault-service:8107/vault-service/1.0/secret/fmx/rabbitmmqSecret')
if echo "${result}" | grep -q "data"; then
echo "Retrieved rabbitmq values from Vaultserv" >> "$logfile"
break
else
echo "could not retrieve password" >> "$logfile"
sleep 5
fi
done
data=$(echo $result | grep -o '"data":{[^}]*}')
values=$(echo "$data"| sed 's/"data":{\([^}]*\)}/\1/')
echo "$values">/opt/ericsson/fmx/rabbitmq/rabbitmq.conf
}

write_rabbitmq_password
retrieve_rabbitmq_password
