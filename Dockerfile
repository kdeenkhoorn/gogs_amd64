FROM kdedesign/debian-stretch_amd64 AS build

# Update basic OS image
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y git gcc 

# Start specific part for this first stage of the build
WORKDIR /opt
ENV GOPATH=/opt 

# Download GO and GOGS version and start build

ADD https://dl.google.com/go/go1.11.2.linux-amd64.tar.gz /opt/go.tar.gz
ADD https://github.com/gogs/gogs/archive/v0.11.66.tar.gz /opt/GOGS.tar.gz
RUN tar -zxf ./go.tar.gz \
    && rm ./go.tar.gz \
    && mkdir -p $GOPATH/src/github.com/gogs/gogs \
    && cd $GOPATH/src/github.com/gogs/gogs \
    && tar -zxf /opt/GOGS.tar.gz --strip 1 \
    && rm /opt/GOGS.tar.gz 

RUN cd $GOPATH/src/github.com/gogs/gogs \
    && /opt/go/bin/go build -tags "sqlite cert" 

# Start second stage of the build
# Build final image

RUN groupadd -g 3000 git \
    && useradd -u 3000 -g 3000 -c "GIT user" -d /opt/src/github.com/gogs/gogs  -s /bin/bash git \
    && mkdir -p /opt/gogs \
    && mkdir -p /data \
    && chown -R git:git /data \
    && chown -R git:git /opt/src


FROM kdedesign/debian-stretch_amd64

# Update basic OS image
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 3000 git \
    && useradd -u 3000 -g 3000 -c "GIT user" -d /opt/gogs  -s /bin/bash git \
    && mkdir -p /opt/gogs/custom \
    && mkdir -p /data \
    && chown -R git:git /data \
    && chown -R git:git /opt/gogs

# Copy binaries files and config from first stage build
COPY --from=build /opt/src/github.com/gogs/gogs/gogs \
                                    /opt/src/github.com/gogs/gogs/LICENSE \
                                    /opt/src/github.com/gogs/gogs/README.md \
                                    /opt/src/github.com/gogs/gogs/README_ZH.md \
                                    /opt/gogs/

COPY --from=build /opt/src/github.com/gogs/gogs/public /opt/gogs/public
COPY --from=build /opt/src/github.com/gogs/gogs/scripts /opt/gogs/scripts
COPY --from=build /opt/src/github.com/gogs/gogs/templates /opt/gogs/templates

RUN chown -R 3000:3000 /opt/gogs

# Configure Docker Container
VOLUME ["/data"]
EXPOSE 3022 3000
USER git
ENV USER=git

ENTRYPOINT ["/opt/gogs/gogs"]
CMD [ "web", "--config=/data/app.ini" ]
