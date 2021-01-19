#!/bin/bash

CREDS=./script-inputs.json

if [ -f "$CREDS" ]
then
    GITHUB_ORG=$(cat $CREDS | jq -r '.githubOrg')
    DT_TENANT=$(cat $CREDS | jq -r '.dynatraceTenant')
    DT_API_TOKEN=$(cat $CREDS | jq -r '.dynatraceApiToken')
    NL_WEB_API_KEY=$(cat $CREDS | jq -r '.nlwebapikey')
fi

# for perform workshop only
#GITHUB_ORG=dynatrace-neoload-perf-workshop-infra
GITHUB_ORG=domuharahap

echo "==================================================================="
echo -e "Please enter script input values"
echo "==================================================================="
#read -p "GitHub Organization                    (current: $GITHUB_ORG) : " GITHUB_ORG_NEW
read -p "Dynatrace Tenant: XXX.dynatrace-managed.com/e/xxx         (current: $DT_TENANT) : " DT_TENANT_NEW
read -p "Dynatrace API Token:                                   (current: $DT_API_TOKEN) : " DT_API_TOKEN_NEW
read -p "NeoLoad Web API Key                                    (current: $NL_WEB_API_KEY) : " NL_WEB_API_KEY_NEW

echo "==================================================================="
echo ""
# set value to new input or default to current value
GITHUB_ORG=${GITHUB_ORG_NEW:-$GITHUB_ORG}
DT_TENANT=${DT_TENANT_NEW:-$DT_TENANT}
#DT_TENANT_URL="$DT_TENANT.live.dynatrace.com"
DT_TENANT_URL="$DT_TENANT"
DT_API_TOKEN=${DT_API_TOKEN_NEW:-$DT_API_TOKEN}
NL_WEB_API_KEY=${NL_WEB_API_KEY_NEW:-$NL_WEB_API_KEY}

echo -e "Please confirm all are correct:"
echo ""
#echo "GitHub Organization          : $GITHUB_ORG"
echo "Dynatrace Tenant             : $DT_TENANT"
#echo "Dynatrace Tenant URL         : $DT_TENANT_URL"
echo "Dynatrace API Token          : $DT_API_TOKEN"
echo "NeoLoad Web API Key          : $NL_WEB_API_KEY"

echo "==================================================================="
read -p "Is this all correct? (y/n) : " -n 1 -r
echo ""
echo "==================================================================="

if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Making a backup $CREDS to $CREDS.bak"
    cp $CREDS $CREDS.bak 2> /dev/null
    rm $CREDS 2> /dev/null

    cat ./$CREDS.template | \
      sed 's~GITHUB_ORG_PLACEHOLDER~'"$GITHUB_ORG"'~' | \
      sed 's~DT_TENANT_PLACEHOLDER~'"$DT_TENANT"'~' | \
      sed 's~DT_TENANT_URL_PLACEHOLDER~'"$DT_TENANT_URL"'~' | \
      sed 's~DT_API_TOKEN_PLACEHOLDER~'"$DT_API_TOKEN"'~' | \
      sed 's~NL_WEB_API_KEY_PLACEHOLDER~'"$NL_WEB_API_KEY"'~' > $CREDS

    echo ""
    echo "The updated script inputs can be found here: $CREDS"
    echo ""
fi
