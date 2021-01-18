#!/bin/bash

clear

# number of seconds
if [ $# -lt 1 ]
then
  version="1"
else
  version=$1 
fi

#CREDS=$(cat ../helper-scripts/config.json | jq -r '.credsfile')
CREDS=~/workshop/scripts/script-inputs.json

if ! [ -f "$CREDS" ]; then
  echo "Aborting: Missing $CREDS file"
  exit 1
fi

DT_TENANT_URL=$(cat $CREDS | jq -r '.dynatraceTenantUrl')
DYNATRACE_API_URL="https://${DT_TENANT_URL}/api/v1/events"
DYNATRACE_API_TOKEN=$(cat $CREDS | jq -r '.dynatraceApiToken')

# build up the API request payload
POST_DATA=$(cat <<EOF
{
    "eventType": "CUSTOM_DEPLOYMENT",
    "attachRules": {
            "tagRule": [
                {
                    "meTypes":"SERVICE",
                    "tags": [
                        {
                            "context": "ENVIRONMENT",
                            "key": "app",
                            "value": "keptn-orders"
                        }
                    ]
                }
            ]
    },
    "deploymentName" : "Deploy Version ${version}",
    "deploymentVersion" : "${version}",
    "deploymentProject" : "keptn-orders",
    "source" : "unix pushevent.sh script",
    "ciBackLink" : "http://mock-ci-link",
    "customProperties" : {
        "JenkinsUrl" : "http://mock-jenkins-link",
        "BuildUrl" : "http://mock-build-link",
        "GitCommit" : "Mock commit 1234"
    }
  }
EOF
)

# make the API call 
echo "Pushing event to: ${DYNATRACE_API_URL}"
echo ""

curl -X POST "${DYNATRACE_API_URL}" \
    -H "Content-type: application/json" \
    -H "Authorization: Api-Token ${DYNATRACE_API_TOKEN}" \
    -d "${POST_DATA}"

echo ""
echo ""
