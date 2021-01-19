#!/bin/bash

# $1 = from date utc
# $2 = to date utc
# $3 = service level target 1
# $4 = service level target 2
# $5 = service level target 3

# get the start stop times or set defaults
# if did not pass in start/stop times in UTC format
# then use last few hours and now
if [ $# -lt 2 ]
then
  START_TIME=$(date -d "`date -u` - 10 minutes" +'%s')000
  END_TIME=$(date -d "`date -u`"  +'%s')000
else
  START_TIME=$1
  END_TIME=$2
fi

# service level objectives
# with pass them all in or just default the values
if [ $# -lt 5 ]
then
  response_time_target=10000000
  server_error_target=5
  cpu_time_target=5000000
else
  response_time_target=$3 
  server_error_target=$4
  cpu_time_target=$5
fi

build_query() {

  # $1 = metric
  # $2 = from date utc
  # $3 = to date utc

  PARM="metricSelector=${1}&"
  PARM="${PARM}resolution=Inf&"
  PARM="${PARM}from=${2}&"
  PARM="${PARM}to=${3}&"
  PARM="${PARM}entitySelector=type(SERVICE),tag(service:order),tag([ENVIRONMENT]app:keptn-orders)"

  PARM=`echo $PARM | sed 's/:/%3A/g' `
  PARM=`echo $PARM | sed 's/(/%28/g' `
  PARM=`echo $PARM | sed 's/)/%29/g' `
  PARM=`echo $PARM | sed 's/\[/%5B/g' `
  PARM=`echo $PARM | sed 's/]/%5D/g' `

}

execute_query() {

  # $1 = service level objective name
  # $2 = service level objective target
  target=$2

  # set to -s for silent, -v for verbose debugging
  echo "==============================================="
  echo "Calling ${DYNATRACE_API_URL})"
  echo "==============================================="
  json_result=$(curl -v --get -d ${PARM} \
      -H "Content-type: application/json" \
      -H "Authorization: Api-Token ${DYNATRACE_API_TOKEN}" \
      ${DYNATRACE_API_URL})

  # for debugging
  echo "==============================================="
  echo "query result:"
  echo "$json_result" | jq -r "."
  echo "==============================================="
  
  result=$(echo $json_result | jq -r '.result[0].data[0].values[0]')
  result_pass=$(awk -v result="$result" -v target="$target" 'BEGIN { print (result <= target) ? "YES" : "NO" }')

  # evaluate result against the service level objective
  echo "${1} target = $target"
  echo "${1} result = $result"
  if [ "$result_pass" == "NO" ] || [ "$result" == "null" ]; then
    echo "Violated ${1} service level objective"
    exit 1
  else
    echo "Passed ${1} service level objective" 
  fi

}

# validate have Dynatrace credentials
#CREDS=$(cat config.json | jq -r '.credsfile')
CREDS=~/workshop/scripts/script-inputs.json

if ! [ -f "$CREDS" ]; then
  echo "Aborting: Missing $CREDS file"
  exit 1
fi

DT_TENANT_URL=$(cat $CREDS | jq -r '.dynatraceTenantUrl')
DYNATRACE_API_URL="https://${DT_TENANT_URL}/api/v2/metrics/query"
DYNATRACE_API_TOKEN=$(cat $CREDS | jq -r '.dynatraceApiToken')

# process the service level checks

build_query "builtin:service.response.time:percentile(95)" $START_TIME $END_TIME
execute_query "response time 95 pct" $response_time_target

build_query "builtin:service.errors.server.rate" $START_TIME $END_TIME
execute_query "error count" $server_error_target

build_query "builtin:service.cpu.time" $START_TIME $END_TIME
execute_query "cpu time" $cpu_time_target
