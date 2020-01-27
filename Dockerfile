# Use the official Docker Hub Ubuntu 16.04 base image
FROM ubuntu:18.04

# Update the base image
RUN apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade

# Setup install environment, Plaso, and Timesketch dependencies
RUN apt-get -qq -y update && \
    apt-get -qq -y --no-install-recommends install \
      software-properties-common \
      apt-transport-https && \
    add-apt-repository -u -y ppa:gift/stable && \
    apt-get -qq -y update && \
    apt-get -qq -y --assume-yes --no-install-recommends install \
      python-setuptools \
      build-essential \
      curl \
      git \
      gpg-agent \
      libffi-dev \
      lsb-release \
      locales \
      python3-dev \
      python3-setuptools \
      python3 \
      python3-pip \
      python3-psycopg2 \
      python3-wheel \
      uwsgi \
      uwsgi-plugin-python3 && \
    curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    VERSION=node_8.x && \
    DISTRO="$(lsb_release -s -c)" && \
    echo "deb https://deb.nodesource.com/$VERSION $DISTRO main" > /etc/apt/sources.list.d/nodesource.list && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
    apt-get -qq -y update && \
    apt-get -qq -y --no-install-recommends install \
      nodejs \
      yarn && \
    apt-get -y dist-upgrade && \
    apt-get -qq -y clean && \
    apt-get -qq -y autoclean && \
    apt-get -qq -y autoremove && \
    rm -rf /var/cache/apt/ /var/lib/apt/lists/

# Download and install Plaso from GitHub Release
RUN curl -sL -o /tmp/plaso-20190916.tar.gz https://github.com/log2timeline/plaso/archive/20190916.tar.gz && \
    cd /tmp/ && \
    tar zxf plaso-20190916.tar.gz && \
    cd plaso-20190916 && \
    pip3 install -r requirements.txt && \
    pip3 install mock && \
    python3 setup.py build && \
    python3 setup.py install && \
    rm -rf /tmp/*

# Build and Install latest Timesketch from GitHub Master with Pip
RUN git clone https://github.com/google/timesketch.git /tmp/timesketch && \
    sed -i -e '/pyyaml/d' /tmp/timesketch/requirements.txt && \
    pip3 install /tmp/timesketch/ && \
    rm -rf /tmp/*

# Download / Copy MANS-related files and install additional dependencies
RUN curl -sL -o /usr/local/bin/mans_to_es.py https://raw.githubusercontent.com/albchen/mans_to_es/master/mans_to_es/mans_to_es.py && \
    chmod 755 /usr/local/bin/mans_to_es.py && \
    pip3 install lxml ciso8601

# Add MANS usage to timesketch files
RUN sed -i "s/'plaso',/'plaso', 'mans',/g" /usr/local/lib/python3.6/dist-packages/timesketch/lib/forms.py && \
    sed -i "s/: .plaso,/: .plaso, .mans,/g" /usr/local/lib/python3.6/dist-packages/timesketch/lib/forms.py && \
    sed -i 's/file, JSONL,/file, MANS, JSONL,/g' /usr/local/lib/python3.6/dist-packages/timesketch/templates/sketch/timelines.html

COPY timesketch/tasks.py /usr/local/lib/python3.6/dist-packages/timesketch/lib/tasks.py

# Copy the TimeSketch uWSGI configuration file into the container
COPY uwsgi_config.ini /

# Cleanup apt cache
RUN apt-get -y autoremove --purge && \
    apt-get -y clean && \
    apt-get -y autoclean && \
# Copy the Timesketch configuration file into /etc
    cp /usr/local/share/timesketch/timesketch.conf /etc

# Set terminal to UTF-8 by default
RUN locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Copy the entrypoint script into the container
COPY docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh

# Expose the port used by Timesketch
EXPOSE 5000

# Load the entrypoint script to be run later
ENTRYPOINT ["/docker-entrypoint.sh"]

# Invoke the entrypoint script
CMD ["timesketch"]
