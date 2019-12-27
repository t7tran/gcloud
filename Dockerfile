FROM alpine/helm:2.16.1 AS helm

# copied from google/cloud-sdk with latest alpine and sdk versions
FROM alpine:3.11

ENV CLOUD_SDK_VERSION=274.0.0 \
    PATH=/google-cloud-sdk/bin:$PATH

COPY --from=helm /usr/bin/helm /usr/local/bin/helm
COPY ./entrypoint.sh /

RUN apk --no-cache add \
        curl \
        python \
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
    curl https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -o /usr/local/bin/cloud_sql_proxy && \
    chmod +x /usr/local/bin/cloud_sql_proxy && \
# install rclone
    cd /tmp && \
    curl https://downloads.rclone.org/rclone-current-linux-amd64.zip -o rclone.zip && \
    unzip rclone.zip && \
    mv rclone-v*/rclone* /usr/local/bin && \
    rm -rf rclone* && \
# install kubectl
    kubectlversion=1.14.9 && \
    cd /usr/local/bin && \
    wget https://storage.googleapis.com/kubernetes-release/release/v${kubectlversion}/bin/linux/amd64/kubectl -O kubectl-${kubectlversion} && \
    chmod +x kubectl-${kubectlversion} && \
    ln -s kubectl-${kubectlversion} kubectl && \
# prepare config folder for non-root user
    mkdir /.config && chmod 777 /.config && \
    apk add --no-cache jq coreutils mysql-client grep && \
    chmod +x /*.sh

ENV HOME /home/alpine
USER alpine
WORKDIR /home/alpine

ENTRYPOINT ["/entrypoint.sh"]
