# copied from google/cloud-sdk with latest alpine and sdk versions
FROM alpine:3.8

ENV CLOUD_SDK_VERSION=211.0.0 \
    PATH=/google-cloud-sdk/bin:$PATH

COPY ./ /

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
# fix short socket timeout
    echo -e '[compute]\ngce_metadata_read_timeout_sec = 30' >> /google-cloud-sdk/properties && \
# install beta components
    gcloud components install beta -q && \
# prepare config folder for non-root user
    mkdir /.config && chmod 777 /.config && \
    apk add --no-cache jq coreutils && \
    chmod +x /*.sh

ENTRYPOINT ["/entrypoint.sh"]
