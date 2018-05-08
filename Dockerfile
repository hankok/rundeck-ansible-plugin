FROM python:2.7.15-stretch
MAINTAINER David Kirstein <dak@batix.com>

# combining stuff from:
# https://github.com/colebrumley/docker-rundeck
# https://github.com/William-Yeh/docker-ansible

# install Ansible
# check newest version: https://pypi.python.org/pypi/ansible
RUN apt-get -qq update && apt-get -qq install -y sudo python python-pip openssl ca-certificates && \
  apt-get -qq update && apt-get -qq install -y build-essential python-dev libffi-dev libssl-dev && \
  pip --no-cache-dir install --upgrade pip cffi && \
  pip --no-cache-dir install ansible && \
  #apt-get remove --purge build-deps && \
  mkdir -p /etc/ansible

# install Rundeck via launcher
# check newest version: http://rundeck.org/downloads.html
ENV RDECK_BASE=/opt/rundeck
ENV RDECK_JAR=${RDECK_BASE}/rundeck-launcher.jar
ENV PATH=${PATH}:${RDECK_BASE}/tools/bin
ENV MANPATH=${MANPATH}:${RDECK_BASE}/docs/man
ENV RDECK_ADMIN_PASS=rdtest2017
RUN apt-get install -y openjdk-8-jre bash curl && \
  mkdir -p ${RDECK_BASE} && \
  mkdir ${RDECK_BASE}/libext && \
  curl -SLo ${RDECK_JAR} http://dl.bintray.com/rundeck/rundeck-maven/rundeck-launcher-2.9.2.jar
COPY docker/realm.properties ${RDECK_BASE}/server/config/
COPY docker/run.sh /
RUN chmod +x /run.sh

# install plugin from GitHub
# check newest version: https://github.com/Batix/rundeck-ansible-plugin/releases
RUN curl -SLo ${RDECK_BASE}/libext/ansible-plugin.jar https://github.com/Batix/rundeck-ansible-plugin/releases/download/1.3.2/ansible-plugin-1.3.2.jar

# install locally built plugin
#COPY build/libs/ansible-plugin-*.jar ${RDECK_BASE}/libext/

# Install Az cli
RUN apt-get -qq install -y lsb-core && AZ_REPO=$(lsb_release -cs) && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list && curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && sudo apt-get install -y --allow-unauthenticated apt-transport-https && apt-get update && apt-get install -y --allow-unauthenticated azure-cli

# Install Azure cli 1.0
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && apt-get install -y nodejs && npm install -g azure-cli --unsafe-perm

# create project
ENV PROJECT_BASE=${RDECK_BASE}/projects/Test-Project
RUN mkdir -p ${PROJECT_BASE}/acls && \
  mkdir -p ${PROJECT_BASE}/etc
COPY docker/project.properties ${PROJECT_BASE}/etc/

ENV ANSIBLE_HOST_KEY_CHECKING=false
ENV RDECK_HOST=localhost
ENV RDECK_PORT=4440

CMD /run.sh
