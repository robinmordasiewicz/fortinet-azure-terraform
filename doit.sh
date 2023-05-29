#!/bin/bash
#

#az login

az account list | jq -r '.[].tenantId'

exit

az ad sp create-for-rbac --display-name="rmordasiewicz-sp" --role="Contributor" --scopes="/subscriptions/cf72478e-c3b0-4072-8f60-41d037c1d9e9"
