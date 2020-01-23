# Use the official Docker Hub Ubuntu 18.04 base image
FROM ubuntu:18.04

# Update the base image
RUN apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade

# Setup install environment and Timesketch dependencies
RUN apt-get -y install apt-transport-https\
                       curl\
                       git\
                       libffi-dev\
                       lsb-release\
                       python-dev\
                       python-pip\
                       python3-pip\
                       python-psycopg2\
                       uwsgi\
                       uwsgi-plugin-python

RUN curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
RUN VERSION=node_8.x && \
    DISTRO="$(lsb_release -s -c)" && \
    echo "deb https://deb.nodesource.com/$VERSION $DISTRO main" > /etc/apt/sources.list.d/nodesource.list
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

# Install Plaso
RUN apt-get -y install software-properties-common
RUN add-apt-repository ppa:gift/stable && apt-get update
RUN apt-get update && apt-get -y install python-plaso=20190131-1ppa1~bionic plaso-tools=20190131-1ppa1~bionic nodejs yarn

# Build and Install Timesketch from GitHub (LDO-CERT, mans_to_es Branch) with Pip
RUN git clone -b mans_to_es https://github.com/LDO-CERT/timesketch.git /tmp/timesketch
RUN cd /tmp/timesketch && git checkout tags/20191220 && yarn install && yarn run build
# Remove pyyaml from requirements.txt to avoid conflits with python-yaml ubuntu package
RUN sed -i -e '/pyyaml/d' /tmp/timesketch/requirements.txt
RUN pip install /tmp/timesketch/

# Download and Copy mans_to_es.py to /usr/local/bin
RUN git clone https://github.com/albchen/mans_to_es.git /tmp/mans_to_es
RUN cp /tmp/mans_to_es/mans_to_es/mans_to_es.py /usr/local/bin/mans_to_es.py

# Install packages for mans_to_es.py
RUN pip3 install /tmp/mans_to_es/

# Copy the Timesketch configuration file into /etc
RUN cp /usr/local/share/timesketch/timesketch.conf /etc

# Copy the TimeSketch uWSGI configuration file into the container
COPY uwsgi_config.ini /

# Copy the entrypoint script into the container
COPY docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh

# Expose the port used by Timesketch
EXPOSE 5000

# Load the entrypoint script to be run later
ENTRYPOINT ["/docker-entrypoint.sh"]

# Invoke the entrypoint script
CMD ["timesketch"]
