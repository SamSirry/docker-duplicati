FROM lsiobase/mono:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
ARG DUPLICATI_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="sparklyballs"

# environment settings
ENV HOME="/config" \
 XDG_CONFIG_HOME="/config"

RUN \
 echo "**** install packages ****" && \
 apt-get update && \
 apt-get install -y \
	jq && \
 echo "**** install duplicati ****" && \
 if [ -z ${DUPLICATI_RELEASE+x} ]; then \
	DUPLICATI_RELEASE=$(curl -sX GET "https://api.github.com/repos/duplicati/duplicati/releases" \
	| jq -r 'first(.[] | select(.tag_name | contains("canary"))) | .tag_name'); \
 fi && \
 mkdir -p \
	/app/duplicati && \
  duplicati_url=$(curl -s https://api.github.com/repos/duplicati/duplicati/releases/tags/"${DUPLICATI_RELEASE}" |jq -r '.assets[].browser_download_url' |grep zip |grep -v signatures) && \
 curl -o \
 /tmp/duplicati.zip -L \
	"${duplicati_url}" && \
 unzip -q /tmp/duplicati.zip -d /app/duplicati && \
 echo "**** install rclone ****" && \
 RCLONE_RELEASE=$(curl -sX GET "https://api.github.com/repos/ncw/rclone/releases/latest" \
	| jq -r '.tag_name') && \
 curl -o \
	/tmp/rclone.deb -L \
	"https://github.com/ncw/rclone/releases/download/${RCLONE_RELEASE}/rclone-${RCLONE_RELEASE}-linux-amd64.deb" && \
 dpkg -i /tmp/rclone.deb && \
 echo "**** cleanup ****" && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 8200
VOLUME /backups /config /source
