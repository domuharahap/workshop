#!/bin/bash

###################################################
# process arguments
###################################################

clear

# number of seconds
if [ $# -lt 1 ]
then
  duration=120
else
  duration=$1
fi

# verify ready application is up
. ../helper-scripts/wait-till-ready.sh

###################################################
# set variables used by script
###################################################

# url to the order app
url="http://localhost"

# Calculate how long this test maximum runs!
thinktime=5  # default the think time
currTime=`date +%s`
timeSpan=$duration
endTime=$(($timeSpan+$currTime))

###################################################
# Run test
###################################################

echo "Send Traffic Test Started."
echo "DURATION=$duration URL=$url THINKTIME=$thinktime"
echo ""

# loop until run out of time.  use thinktime between loops
while [ $currTime -lt $endTime ];
do
  currTime=`date +%s`
  echo "Loop Start: $(date +%H:%M:%S)"

  testStepName=FrontendLanding
  echo "  calling TSN=$testStepName; $(curl -s "$url" -w "%{http_code}"  -o /dev/nul)"

  testStepName=CatalogSearchLanding
  echo "  calling TSN=$testStepName; $(curl -s "$url:8082/searchForm.html" -w "%{http_code}"  -o /dev/nul)"

  testStepName=CatalogSearch
  echo "  calling TSN=$testStepName; $(curl -s "$url:8082/searchByName.html?query=iPod&submit=" -w "%{http_code}"  -o /dev/nul)"

  testStepName=CatalogItemView
  echo "  calling TSN=$testStepName; $(curl -s "$url:8082/1.html" -w "%{http_code}"  -o /dev/nul)"
  echo "  calling TSN=$testStepName; $(curl -s "$url:8082/2.html" -w "%{http_code}"  -o /dev/nul)"
  echo "  calling TSN=$testStepName; $(curl -s "$url:8082/3.html" -w "%{http_code}"  -o /dev/nul)"
  echo "  calling TSN=$testStepName; $(curl -s "$url:8082/4.html" -w "%{http_code}"  -o /dev/nul)"

  testStepName=CustomerList
  echo "  calling TSN=$testStepName; $(curl -s "$url:8081/list.html" -w "%{http_code}"  -o /dev/nul)"

  testStepName=OrderAdd
  echo "  calling TSN=$testStepName; $(curl -s "$url:8083/form.html" -w "%{http_code}"  -o /dev/nul)"

  testStepName=OrderAddLine
  echo "  calling TSN=$testStepName; $(curl -X POST -s "$url:8083/line" -w "%{http_code}"  -o /dev/nul)"

  sleep $thinktime
done;

echo Done.
