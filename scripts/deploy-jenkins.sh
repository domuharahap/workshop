#!/usr/bin/env bash
if [ "$(id -u)" != "0" ]
then
sudo $0 $*
exit 0
fi

CREDS=./script-inputs.json

if ! [ -f "$CREDS" ]; then
  echo "Aborting: Missing $CREDS file"
  echo "Please run ./enter-script-inputs.sh first"
  exit 1
fi

export DT_TENANT_URL=$(cat $CREDS | jq -r '.dynatraceTenantUrl')
export DT_API_TOKEN=$(cat $CREDS | jq -r '.dynatraceApiToken')
export GITHUB_ORGANIZATION=$(cat $CREDS | jq -r '.githubOrg')
export NL_WEB_API_KEY=$(cat $CREDS | jq -r '.nlwebapikey')

#CONF=/var/jenkins_home/jobs/pipeline/config.xml

#if ! [ -f "$CONF" ]; then
 apt install default-jre -y
 apt install openjdk-8-jre-headless -y
 apt-get update -y
 apt-get install -y git curl gosu
#fi

rm -rf /var/lib/apt/lists/*
echo "building jenkins!"
user=jenkins
group=jenkins
uid=10000
gid=10000
http_port=8080
agent_port=60000

export JENKINS_SLAVE_AGENT_PORT=${agent_port}
export JENKINS_HOME=/var/jenkins_home

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
mkdir -p $JENKINS_HOME \
  && groupadd -g ${gid} -o ${group} \
  && useradd -d "$JENKINS_HOME" -u ${uid} -o -g ${gid}  -s /bin/bash ${user} \
  && chown ${uid}:${gid} $JENKINS_HOME \
  && usermod -a -G docker jenkins


mkdir -p $JENKINS_HOME/jobs \
  && chown ${uid}:${gid} $JENKINS_HOME/jobs

mkdir -p $JENKINS_HOME/workspaces \
  && chown ${uid}:${gid} $JENKINS_HOME/workspaces


# `/usr/share/jenkins/ref/` contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
mkdir -p /usr/share/jenkins/ref/init.groovy.d
cp configs/init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

JENKINS_VERSION=2.249.2
# jenkins.war checksum, download will be validated using it
JENKINS_SHA=ecb84b6575e86957b902cce5e68e360e6b0768b0921baa405e61d314239e5b27

# Can be used to customize where jenkins.war get downloaded from
JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war
# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum
# see https://github.com/docker/docker/issues/8331
curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war

export JENKINS_UC=https://repo.jenkins-ci.org
export JENKINS_LATEST=https://updates.jenkins.io
export JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
export JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals
chown -R ${uid}:${gid} "$JENKINS_HOME" /usr/share/jenkins/ref

export COPY_REFERENCE_FILE_LOG=$JENKINS_HOME/copy_reference_file.log

cp  configs/jenkins-support /usr/local/bin/jenkins-support
cp  start-jenkins.sh /usr/local/bin/start-jenkins.sh

chmod +x /usr/local/bin/start-jenkins.sh

cp configs/config.xml "$JENKINS_HOME"/config.xml

cp -r  configs/jobs /tmp/jobs
cp -r configs/users "$JENKINS_HOME"/users

# from a derived Dockerfile, can use `RUN plugins.sh active.txt` to setup /usr/share/jenkins/ref/plugins from a support bundle
cp install-jenkins-plugins.sh /usr/local/bin/install-jenkins-plugins.sh
chmod 755 /usr/local/bin/install-jenkins-plugins.sh

# install jenkins plugins
/usr/local/bin/install-jenkins-plugins.sh \
workflow-job:2.39 \
workflow-aggregator:2.6 \
credentials-binding:1.23 \
git:4.0.0 \
google-oauth-plugin:1.0.0 \
google-source-plugin:0.4 \
github-branch-source:2.5.8 \
ws-cleanup:0.38 \
docker-compose-build-step:1.0 \
docker-build-step:2.0 \
docker-plugin:latest \
performance-signature-dynatracesaas:3.1.5 \
performance-signature-ui:3.1.5 \
performance-signature-viewer:3.1.5 \
performance:3.17 

cp -r /tmp/jobs/* "$JENKINS_HOME"/jobs/
chown -R ${uid}:${gid} "$JENKINS_HOME"
chmod -R 777 "$JENKINS_HOME"
chmod -R 777 /root


#if ! [ -f "$CONF" ]; then
 apt install openjdk-8-jdk -y
 update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
#fi

# Configure Jenkins files global environment variables
sed -i 's/GITHUB_ORGANIZATION_PLACEHOLDER/'"$GITHUB_ORGANIZATION"'/' $JENKINS_HOME/config.xml
sed -i 's,DT_TENANT_URL_PLACEHOLDER,'"$DT_TENANT_URL"',' $JENKINS_HOME/config.xml
sed -i 's/DT_API_TOKEN_PLACEHOLDER/'"$DT_API_TOKEN"'/' $JENKINS_HOME/config.xml
sed -i 's/NL_WEB_API_KEY_PLACEHOLDER/'"$NL_WEB_API_KEY"'/' $JENKINS_HOME/config.xml

# Configure Jenkins jobs with the github org
find $JENKINS_HOME/jobs -type f -name 'config.xml' -exec sed -i 's/GITHUB_ORGANIZATION_PLACEHOLDER/'"$GITHUB_ORGANIZATION"'/' {} +

# adjust from https to http so that plugin pages data in jenkins is viewable
cp configs/hudson.model.UpdateCenter.xml $JENKINS_HOME/hudson.model.UpdateCenter.xml

#sudo su ${user}
echo "========================================="
echo Running start-jenkins.sh...
./start-jenkins.sh &>jenkins.log
echo Ready!!
echo "========================================="
./show-jenkins.sh
