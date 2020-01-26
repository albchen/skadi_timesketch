# Use the official Docker Hub aorlikoski/CDQR image
FROM aorlikoski/cdqr:20191226
MAINTAINER aorlikoski

# Install uwsgi
RUN apt-get update && \
  apt-get -y install uwsgi uwsgi-plugin-python3

# Download MANS-related files from albchen / LDO-CERT
RUN curl -sL -o /usr/local/bin/mans_to_es.py https://raw.githubusercontent.com/albchen/mans_to_es/master/mans_to_es/mans_to_es.py
RUN chmod 755 /usr/local/bin/mans_to_es.py
RUN curl -sL -o /usr/local/lib/python3.6/dist-packages/timesketch/lib/forms.py https://raw.githubusercontent.com/LDO-CERT/timesketch/master/timesketch/lib/forms.py
RUN curl -sL -o /usr/local/lib/python3.6/dist-packages/timesketch/lib/tasks.py https://raw.githubusercontent.com/LDO-CERT/timesketch/master/timesketch/lib/tasks.py
RUN curl -sL -o /usr/local/lib/python3.6/dist-packages/timesketch/templates/sketch/timelines.html https://raw.githubusercontent.com/LDO-CERT/timesketch/master/timesketch/templates/sketch/timelines.html

# Install packages for mans_to_es.py not already previously installed for timesketch
RUN pip3 install certifi lxml ciso8601

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
