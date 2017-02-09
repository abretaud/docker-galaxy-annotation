FROM bgruening/galaxy-stable
MAINTAINER Eric Rasche <esr@tamu.edu>

ENV GALAXY_CONFIG_BRAND=Annotation \
    GALAXY_LOGGING=full

WORKDIR /galaxy-central

# install-repository sometimes needs to be forced into updating the repo
ENV CACHE_BUST=2

RUN install-repository "--url https://toolshed.g2.bx.psu.edu/ -o iuc --name jbrowse --panel-section-name JBrowse"

ADD tool_conf.xml /etc/config/apollo_tool_conf.xml
ENV GALAXY_CONFIG_TOOL_CONFIG_FILE /galaxy-central/config/tool_conf.xml.sample,/galaxy-central/config/shed_tool_conf.xml,/etc/config/apollo_tool_conf.xml
# overwrite current welcome page
ADD welcome.html $GALAXY_CONFIG_DIR/web/welcome.html

# Mark folders as imported from the host.
VOLUME ["/export/", "/apollo-data/", "/jbrowse/data/", "/var/lib/docker"]

ADD setup_data_libraries.py /bin/setup_data_libraries.py

ADD postinst.sh /bin/postinst
RUN postinst && \
    chmod 777 /apollo-data && \
    chmod 777 /jbrowse/data

RUN git clone https://github.com/abretaud/galaxy-apollo tools/apollo && \
    cd tools/apollo && \
    git checkout bipaa

RUN git clone https://github.com/galaxy-genome-annotation/galaxy-tools /tmp/galaxy-tools/ && \
    cp -RT /tmp/galaxy-tools/tools/ tools/ && \
    rm -rf /tmp/galaxy-tools/

# Install a miniconda2 version until https://github.com/galaxyproject/galaxy/issues/3299 is resolved
# By default miniconda3 is installed, but we want to use python 2.7 for apollo scripts
RUN rm -rf $GALAXY_CONDA_PREFIX/ && \
    wget https://repo.continuum.io/miniconda/Miniconda2-4.0.5-Linux-x86_64.sh && \
    bash Miniconda2-4.0.5-Linux-x86_64.sh -b -p $GALAXY_CONDA_PREFIX && \
    rm Miniconda2-4.0.5-Linux-x86_64.sh && \
    $GALAXY_CONDA_PREFIX/bin/conda install -y conda==4.2.13 && \
    chown -R $GALAXY_USER:$GALAXY_USER $GALAXY_CONDA_PREFIX

ENV GALAXY_WEBAPOLLO_URL="http://apollo:8080/apollo" \
    GALAXY_WEBAPOLLO_USER="admin@local.host" \
    GALAXY_WEBAPOLLO_PASSWORD=password \
    GALAXY_WEBAPOLLO_EXT_URL="/apollo" \
    GALAXY_SHARED_DIR="/apollo-data" \
    GALAXY_JBROWSE_SHARED_DIR="/jbrowse/data" \
    GALAXY_JBROWSE_SHARED_URL="/jbrowse"
