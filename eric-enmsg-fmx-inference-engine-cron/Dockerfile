ARG ERIC_ENM_SLES_BASE_IMAGE_NAME=eric-enm-sles-base
ARG ERIC_ENM_SLES_BASE_IMAGE_REPO=armdocker.rnd.ericsson.se/proj-enm
ARG ERIC_ENM_SLES_BASE_IMAGE_TAG=1.64.0-33

FROM ${ERIC_ENM_SLES_BASE_IMAGE_REPO}/${ERIC_ENM_SLES_BASE_IMAGE_NAME}:${ERIC_ENM_SLES_BASE_IMAGE_TAG}

USER root
ARG SGUSER=189692

ARG CONSUL_NEXUS_URL=https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/service/local/repositories/thirdparty/content/com/github/hashicorp/consul
ARG CONSUL_VERSION=1.14.9
ARG SUPERCRONIC_NEXUS_URL=https://arm1s11-eiffel004.eiffel.gic.ericsson.se:8443/nexus/service/local/repositories/thirdparty/content/com/github/aptible/supercronic
ARG SUPERCRONIC_VERSION=0.2.29

# Certs needed for self-signed cert in CI portal
RUN zypper in -l -y ca-certificates-mozilla wget \
    && wget --quiet ${CONSUL_NEXUS_URL}/${CONSUL_VERSION}/consul-${CONSUL_VERSION}.tar.gz && tar -zxvf consul-${CONSUL_VERSION}.tar.gz \
    && chmod +x /usr/bin/consul \
    && wget --quiet ${SUPERCRONIC_NEXUS_URL}/${SUPERCRONIC_VERSION}/supercronic-${SUPERCRONIC_VERSION}.tar.gz && tar -zxvf supercronic-${SUPERCRONIC_VERSION}.tar.gz \
    && chmod +x /usr/bin/supercronic-linux-amd64 \
    && ln -s /usr/bin/supercronic-linux-amd64 /usr/bin/supercronic \
    && zypper clean -a

RUN zypper install -y catatonit \
    bc && \
    ln -s /ericsson/tor/data/fmx/ /var/opt/ericsson && \
    zypper install -y python3-requests \
                      ERICfmxengine_CXP9031791 \
                      ERICfmxenmadapter_CXP9031801 \
                      ERICvaultloginmodule_CXP9036201 \
                      ERICfmxutilbasic_CXP9031797 \
                      ERICfmxenmutilbasic_CXP9031802 && \
    zypper download ERICfmxranautomationrules_CXP9037197 \
                    ERICfmxtools_CXP9031793 \
                    ERICfmxenmcfg_CXP9032402  \
                    ERICfmxcli_CXP9031796 && \
    rpm -ivh /var/cache/zypp/packages/enm_iso_repo/*.rpm --nodeps --noscripts && \
    zypper clean -a

RUN mkdir /opt/ericsson/fmx/rabbitmq/
RUN find /opt/ericsson/fmx /etc/opt/ericsson/fmx -type d -exec chmod 775 {} +
RUN find /opt/ericsson/fmx/rabbitmq -type d -exec chmod 775 {} +
COPY image_content/rabbitmq-env.conf /etc/rabbitmq/
COPY image_content/rabbitmqconf.sh /etc/rabbitmq/
RUN chmod 775 /etc/rabbitmq
RUN chmod 775 /etc/rabbitmq/rabbitmqconf.sh
RUN chown $SGUSER:$SGUSER /etc/rabbitmq/rabbitmqconf.sh
RUN sed -i 's/127.0.0.1/fmx-rabbitmq/g' $(find /etc/opt/ericsson/fmx/engine/kernel.properties )
RUN sed -i 's/127.0.0.1/fmx-rabbitmq/g' $(find /etc/opt/ericsson/fmx/cli/fmxcli.properties )
RUN sed -i 's/localhost:7001,localhost:7002,localhost:7003/eric-data-key-value-database-rd-operand:6379/g' $(find  /etc/opt/ericsson/fmx/cli/fmxcli.properties )
RUN sed -i 's/http:\/\/localhost:8500/http:\/\/kvstore:8500\//g' opt/ericsson/fmx/tools/lib/kvstore
RUN mkdir /var/tmp/cron.d_copy
RUN cp /etc/cron.d/* /var/tmp/cron.d_copy

RUN echo "$SGUSER:x:$SGUSER:210:An Identity for fmx-engine-cron:/nonexistent:/bin/false" >> /etc/passwd && \
    echo "$SGUSER:!::0:::::" >> /etc/shadow

RUN chmod 775 /var/tmp/cron.d_copy
RUN chmod 775 /var/lib/misc
RUN chmod 775 /usr/local/bin

COPY image_content/entrypoint.sh /usr/local/bin
COPY image_content/logrotate.cron /var/tmp/cron.d_copy
COPY image_content/logrotate_syslog /etc/logrotate.d/syslog
COPY image_content/populate_and_load_crontab_from_etc_crond.sh /usr/local/bin

ENTRYPOINT ["/usr/bin/catatonit", "--", "/bin/bash",  "/usr/local/bin/entrypoint.sh"]

USER $SGUSER
