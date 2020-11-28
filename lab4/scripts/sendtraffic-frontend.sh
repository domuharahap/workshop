#!/bin/bash

###################################################
# process arguments
###################################################

# number of seconds
if [ $# -lt 1 ]
then
  duration=120
else
  duration=$1 
fi

# default the test name to the date.  Can pass it in build number when running from a pipeline
if [ $# -lt 2 ]
then
  loadTestName="manual $(date +%Y-%m-%d_%H:%M:%S)"
else
  loadTestName=$2
fi

# verify ready application is up
. ../../helper-scripts/wait-till-ready.sh

###################################################
# set variables used by script
###################################################

# url to the order app
#url="http://$(curl -s http://checkip.amazonaws.com)"          
url="http://localhost"   

# Set Dynatrace Test Headers Values
loadScriptName="loadtest.sh"

# Calculate how long this test maximum runs!
thinktime=5  # default the think time
currTime=`date +%s`
timeSpan=$duration
endTime=$(($timeSpan+$currTime))

###################################################
# Run test
###################################################

echo "Load Test Started. NAME: $loadTestName"
echo "DURATION=$duration URL=$url THINKTIME=$thinktime"
echo "x-dynatrace-test: LSN=$loadScriptName;LTN=$loadTestName;"
echo ""

# loop until run out of time.  use thinktime between loops
while [ $currTime -lt $endTime ];
do
  currTime=`date +%s`
  echo "Loop Start: $(date +%H:%M:%S)"
  
  testStepName=FrontendLanding
  echo "  calling TSN=$testStepName; $(curl -s "$url" -w "%{http_code}" -H "x-dynatrace-test: LSN=$loadScriptName;LTN=$loadTestName;TSN=$testStepName;" -o /dev/nul)"

  sleep $thinktime
done;

echo Done.
