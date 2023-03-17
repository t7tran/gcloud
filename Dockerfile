FROM alpine/helm:2.17.0 AS helm

# copied from google/cloud-sdk with latest alpine and sdk versions
FROM alpine:3.17

    # https://cloud.google.com/sdk/docs/release-notes
ENV CLOUD_SDK_VERSION=413.0.0 \
    # https://github.com/kubernetes/kubernetes/releases
    KUBECTL_VERSION=1.26.1 \
    # https://github.com/GoogleCloudPlatform/cloud-sql-proxy/releases
    SQLPROXY_VERSION=2.1.1 \
   # https://github.com/msoap/shell2http/releases
    SHELL2HTTP_VERSION=1.15.0 \
    PATH=/google-cloud-sdk/bin:$PATH

COPY --from=helm /usr/bin/helm /usr/local/bin/helm
COPY ./entrypoint.sh /

RUN apk --no-cache add \
        tar \
        curl \
        python3 \
        py-crcmod \
        bash \
        libc6-compat \
        openssh-client \
        git \
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    ln -s /lib /lib64 && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version && \
# finish copied
# add non-privileged user
    addgroup alpine && adduser -s /bin/bash -D -G alpine alpine && \
    chmod 777 /home/alpine && \
# fix short socket timeout
    echo -e '[compute]\ngce_metadata_read_timeout_sec = 30' >> /google-cloud-sdk/properties && \
# install beta components
    gcloud components install beta -q && \
# install cloud_sql_proxy
    curl -fsSL https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v$SQLPROXY_VERSION/cloud-sql-proxy.linux.amd64 -o /usr/local/bin/cloud_sql_proxy && \
    chmod +x /usr/local/bin/cloud_sql_proxy && \
# install rclone
    cd /tmp && \
    curl -fsSL https://downloads.rclone.org/rclone-current-linux-amd64.zip -o rclone.zip && \
    unzip rclone.zip && \
    mv rclone-v*/rclone* /usr/local/bin && \
    rm -rf rclone* && \
# install kubectl
    cd /usr/local/bin && \
    curl -fsSL https://dl.k8s.io/v${KUBECTL_VERSION}/bin/linux/arm64/kubectl -o kubectl-${KUBECTL_VERSION} && \
    chmod +x kubectl-${KUBECTL_VERSION} && \
    ln -s kubectl-${KUBECTL_VERSION} kubectl && \
# install shell2http
    curl -fsSL https://github.com/msoap/shell2http/releases/download/v${SHELL2HTTP_VERSION}/shell2http_${SHELL2HTTP_VERSION}_linux_amd64.tar.gz | \
    tar -C /usr/local/bin -xvzf -  --wildcards --no-anchored shell2http && \
# prepare config folder for non-root user
    mkdir /.config && chmod 777 /.config && \
    apk add --no-cache jq coreutils mysql-client mariadb-connector-c grep screen && \
    chmod +x /*.sh && \
# clean up
    rm -rf /apk /tmp/* /var/cache/apk/*

ENV HOME /home/alpine
USER alpine
WORKDIR /home/alpine

ENTRYPOINT ["/entrypoint.sh"]
