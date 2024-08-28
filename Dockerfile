ARG ERIC_ENM_SLES_BASE_IMAGE_NAME=eric-enm-sles-base
ARG ERIC_ENM_SLES_BASE_IMAGE_REPO=armdocker.rnd.ericsson.se/proj-enm
ARG ERIC_ENM_SLES_BASE_IMAGE_TAG=1.64.0-33

FROM ${ERIC_ENM_SLES_BASE_IMAGE_REPO}/${ERIC_ENM_SLES_BASE_IMAGE_NAME}:${ERIC_ENM_SLES_BASE_IMAGE_TAG}

ARG BUILD_DATE=unspecified
ARG IMAGE_BUILD_VERSION=unspecified
ARG GIT_COMMIT=unspecified
ARG ISO_VERSION=unspecified
ARG RSTATE=unspecified
ARG SGUSER=110599

LABEL \
com.ericsson.product-number="CXC Placeholder" \
com.ericsson.product-revision=$RSTATE \
enm_iso_version=$ISO_VERSION \
org.label-schema.name="ENM fmx engine Service Group" \
org.label-schema.build-date=$BUILD_DATE \
org.label-schema.vcs-ref=$GIT_COMMIT \
org.label-schema.vendor="Ericsson" \
org.label-schema.version=$IMAGE_BUILD_VERSION \
org.label-schema.schema-version="1.0.0-rc1"

RUN /usr/sbin/groupadd -g 5004 "fmexportusers" > /dev/null 2>&1 && \
    /usr/sbin/usermod -a -G "fmexportusers" jboss_user > /dev/null 2>&1 && \
    /usr/sbin/groupadd -g 5000 "mm-smrsusers" > /dev/null 2>&1 && \
    /usr/sbin/usermod -a -G "mm-smrsusers" jboss_user > /dev/null 2>&1  && \
    /usr/sbin/groupadd -g 210 "nmx" > /dev/null 2>&1 && \
    /usr/sbin/useradd -m -g nmx -u 210 nmxadm > /dev/null 2>&1 && \
    /usr/sbin/usermod -a -G "root" nmxadm > /dev/null 2>&1

RUN zypper install -y   ERICfmxengine_CXP9031791 \
                        ERICfmxenmadapter_CXP9031801 \
                        ERICvaultloginmodule_CXP9036201 \
                        ERICfmxutilbasic_CXP9031797 \
                        ERICfmxenmutilbasic_CXP9031802 && \
    zypper download ERICfmxtools_CXP9031793 \
                        ERICfmxcli_CXP9031796 \
                        ERICfmxenmcfg_CXP9032402 && \
    zypper install -y rsync \
                      python && \
    rpm -ivh /var/cache/zypp/packages/enm_iso_repo/*.rpm --nodeps --noscripts && \
    zypper clean -a

ENV ENM_JBOSS_SDK_CLUSTER_ID="fmx" \
    ENM_JBOSS_BIND_ADDRESS="0.0.0.0" \
    GLOBAL_CONFIG="/gp/global.properties"

RUN find /opt/ericsson/fmx /etc/opt/ericsson/fmx -type d -exec chmod 775 {} +
RUN mv /usr/lib/ocf/resource.d/* /var/tmp/
RUN mv /var/tmp/rsyslog-healthcheck.sh /usr/lib/ocf/resource.d/
COPY image-content/check_application_startup_has_completed.sh /usr/lib/ocf/resource.d/
COPY image-content/global.properties /tmp/ericsson/tor/data/
COPY image-content/rabbitmq-env.conf /etc/rabbitmq/
COPY image-content/fmxie_entrypoint.sh /var/run/fmx/scripts/
RUN chmod 775 /var/run/fmx/scripts/fmxie_entrypoint.sh
COPY image-content/postInstall.sh /var/run/fmx/scripts/
COPY image-content/fmx_preconfig.sh /var/run/fmx/scripts/
COPY image-content/enable_jmx_opts.sh /var/run/fmx/scripts/
RUN chmod 775 /var/run/fmx/scripts/
RUN chmod 775 /var/run/fmx/scripts/fmx_preconfig.sh
RUN chmod 775 /var/run/fmx/scripts/postInstall.sh
RUN chmod 775 /var/run/fmx/scripts/enable_jmx_opts.sh
RUN sed -i 's/127.0.0.1/fmx-rabbitmq/g' $(find /etc/opt/ericsson/fmx/engine/kernel.properties )
RUN sed -i 's/localhost:7001,localhost:7002,localhost:7003/eric-data-key-value-database-rd-operand:6379/g' $(find /etc/opt/ericsson/fmx/engine/kernel.properties )
RUN sed -i 's/127.0.0.1/fmx-rabbitmq/g' $(find /etc/opt/ericsson/fmx/cli/fmxcli.properties )
RUN sed -i 's/localhost:7001,localhost:7002,localhost:7003/eric-data-key-value-database-rd-operand:6379/g' $(find  /etc/opt/ericsson/fmx/cli/fmxcli.properties )
RUN sed -i 's/port="514"/port="5140"/g' /etc/opt/ericsson/fmx/engine/log4j2.xml

RUN sed -i 's/\$CACHED_GLOBAL_CONFIG/\$GLOBAL_CONFIG/g' /opt/ericsson/fmx/tools/lib/functions

RUN mkdir /var/tmp/cron.d_from_image && \
    chmod 775 /var/tmp/cron.d_from_image && \
    cp -p /etc/cron.d/fmxstats /var/tmp/cron.d_from_image

RUN mv /usr/bin/sudo /usr/bin/sudo.real
COPY image-content/fake_sudo.sh /var/run/fmx/scripts/
RUN chmod 775 /var/run/fmx/scripts/fake_sudo.sh
RUN ln -s /var/run/fmx/scripts/fake_sudo.sh /usr/bin/sudo

RUN echo "$SGUSER:x:$SGUSER:210:An Identity for fmx-engine:/nonexistent:/bin/false" >>/etc/passwd && \
    echo "$SGUSER:!::0:::::" >>/etc/shadow

ENTRYPOINT ["/bin/sh", "-c" , "/var/run/fmx/scripts/fmxie_entrypoint.sh"]

EXPOSE 3528 4447 8009 8080 9990 9999 12986 12987 54200 56127 56142 56145 56185 56193 56199 56203 56214 56216 56219 56227 56235 7001 7002 7003 7004 7005 7006

USER $SGUSER
