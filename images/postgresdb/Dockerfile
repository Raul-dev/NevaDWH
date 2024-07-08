
#FROM debian:bullseye-slim
FROM debian:bookworm-slim
#bookworm
ENV PG_VER=16.1
ENV PG_MAJOR 16
ENV PATH $PATH:/usr/lib/postgresql/$PG_MAJOR/bin

# explicitly set user/group IDs
RUN set -eux; \
	groupadd -r postgres --gid=999; \
# https://salsa.debian.org/postgresql/postgresql-common/blob/997d842ee744687d99a2b2d95c1083a2615c79e8/debian/postgresql-common.postinst#L32-35
	useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres; \
# also create the postgres user's home directory with appropriate permissions
# see https://github.com/docker-library/postgres/issues/274
	mkdir -p /var/lib/postgresql; \
	chown -R postgres:postgres /var/lib/postgresql

RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		gnupg \
	; \
	rm -rf /var/lib/apt/lists/*

#Get sources
#RUN	curl -sSL "https://ftp.postgresql.org/pub/source/v${PG_VER}/postgresql-${PG_VER}.tar.gz" | tar -xz 
#RUN wget "https://ftp.postgresql.org/pub/source/v${PG_VER}/postgresql-${PG_VER}.tar.gz"
# grab gosu for easy step-down from root
# https://github.com/tianon/gosu/releases
ENV GOSU_VERSION 1.17
RUN set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends ca-certificates wget ; \
	rm -rf /var/lib/apt/lists/*; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	wget "https://ftp.postgresql.org/pub/source/v$PG_VER/postgresql-$PG_VER.tar.gz" ; \
	wget -q -O pg_repack.zip "https://api.pgxn.org/dist/pg_repack/1.5.0/pg_repack-1.5.0.zip"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true

#TODO compile pg_repack-1.5.0

# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN set -eux; \
	if [ -f /etc/dpkg/dpkg.cfg.d/docker ]; then \
# if this file exists, we're likely in "debian:xxx-slim", and locales are thus being excluded so we need to remove that exclusion (since we need locales)
		grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; \
		sed -ri '/\/usr\/share\/locale/d' /etc/dpkg/dpkg.cfg.d/docker; \
		! grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; \
	fi; \
	apt-get update; apt-get install -y --no-install-recommends locales; rm -rf /var/lib/apt/lists/*; \
	echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen; \
	locale-gen; \
	locale -a | grep 'en_US.utf8'
ENV LANG en_US.utf8

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libnss-wrapper \
		xz-utils \
		zstd \
	; \
	rm -rf /var/lib/apt/lists/*

RUN apt update
#RUN apt install -y libtool libtool-bin
#RUN apt install -y build-essential libreadline-dev zlib1g-dev flex bison libxml2-dev libxslt-dev libssl-dev libxml2-utils xsltproc ccache


USER root
RUN BUILD_DEPS="clang \
		dirmngr \
		gnupg \
		icu-devtools \ 
		libicu72 \
		libclang-dev \
		libossp-uuid-dev \
		libicu-dev \
		libipc-run-perl \
		libkrb5-dev \
		libldap2-dev \
		liblz4-dev \
		libpam-dev \
		libperl-dev \
		libpython3-dev \
		libreadline-dev \
		libssl-dev \
		libxml2-dev \
		libxslt1-dev \
		llvm \
		llvm-dev \
		postgresql-server-dev-all \
		python3-dev \
		tcl-dev \
		uuid-dev" && \
	apt-get update && apt-get install -y --no-install-recommends \
	gosu \
	locales \
	$BUILD_DEPS \
	&& \
	rm -rf /var/lib/apt/lists/* && \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 


RUN mkdir /docker-entrypoint-initdb.d

RUN mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql && chmod 3777 /var/run/postgresql

ENV PGDATA /var/lib/postgresql/data
# this 1777 will be replaced by 0700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 1777 "$PGDATA"
VOLUME /var/lib/postgresql/data

RUN set -x && \
    apt-get update -qq -y 
#	apt install -y curl


RUN tar -xvzf postgresql-${PG_VER}.tar.gz

#Replace define NAMEDATALEN 64 to 128
COPY ./pg_config_manual.h /postgresql-${PG_VER}/src/include/pg_config_manual.h

#RUN	cd /postgresql-${PG_VER} && \
#    ./configure --without-icu \
#	--with-uuid=ossp

RUN	cd /postgresql-${PG_VER} && \
    ./configure --without-icu \
		--prefix=/usr/lib/postgresql/$PG_MAJOR \
		--enable-integer-datetimes \
		--enable-thread-safety \
		--with-python \
		--with-includes=/usr/local/include \
		--with-libraries=/usr/local/lib \
		--with-libxml \
		--with-uuid=ossp 

#		--with-pgport=5432 \
#		--with-includes=/usr/local/include \
#		--with-libraries=/usr/local/lib \
#		--with-krb5 \
#		--with-gssapi \
#		--with-ldap \
#		--with-pam \
#		--with-tcl \
#		--with-perl \
#		--with-python \
#		--with-openssl \
#		--with-libxml \
#		--with-libxslt \
#		--with-llvm \
#		--with-lz4
#--with-system-tzdata=/usr/share/zoneinfo \

USER root
RUN cd /postgresql-${PG_VER} && \
	make install

RUN cd /postgresql-${PG_VER}/contrib && \
	make install

#remove libs
#RUN cd / && rm -rf postgresql-${PG_VER} && \
#   apt-get purge -y --auto-remove $BUILD_DEPS

COPY docker-entrypoint.sh docker-ensure-initdb.sh /usr/local/bin/
RUN ln -sT docker-ensure-initdb.sh /usr/local/bin/docker-enforce-initdb.sh

#Replace "listen_addresses = 'localhost' to "listen_addresses = '*'
RUN	sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/lib/postgresql/${PG_MAJOR}/share/postgresql.conf.sample
#grep -F "listen_addresses = '*'" /usr/lib/postgresql/16/share/postgresql.conf.sample

ENTRYPOINT ["docker-entrypoint.sh"]

STOPSIGNAL SIGINT
#
# An additional setting that is recommended for all users regardless of this
# value is the runtime "--stop-timeout" (or your orchestrator/runtime's
# equivalent) for controlling how long to wait between sending the defined
# STOPSIGNAL and sending SIGKILL (which is likely to cause data corruption).
#
# The default in most runtimes (such as Docker) is 10 seconds, and the
# documentation at https://www.postgresql.org/docs/12/server-start.html notes
# that even 90 seconds may not be long enough in many instances.

EXPOSE 5432
CMD ["postgres"]