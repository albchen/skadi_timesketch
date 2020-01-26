# Use the official Docker Hub albchen/CDQR image
FROM albchen/cdqr_mans:dev

# Install uwsgi
RUN apt-get update && \
  apt-get -y install uwsgi uwsgi-plugin-python3

# Download MANS-related files from albchen / LDO-CERT
RUN curl -sL -o /usr/local/bin/mans_to_es.py https://raw.githubusercontent.com/albchen/mans_to_es/master/mans_to_es/mans_to_es.py
RUN chmod 755 /usr/local/bin/mans_to_es.py

# Install packages for mans_to_es.py not already previously installed for timesketch
RUN pip3 install lxml ciso8601

# Cleanup apt cache
RUN apt-get -y autoremove --purge && \
    apt-get -y clean && \
    apt-get -y autoclean && \
# Copy the Timesketch configuration file into /etc
    cp /usr/local/share/timesketch/timesketch.conf /etc

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
