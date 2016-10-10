# Set the base image to Ubuntu
FROM ubuntu:xenial

# File Author / Maintainer
MAINTAINER Michael Gregorowicz <michael.gregorowicz@wayne.edu>
LABEL "org.osris.vendor"="MI-OSiRIS Project"
LABEL description="Container for aa_services daemons"

RUN echo " #### INSTALLING DISTRO SUPPLIED DEPENDENCIES #### " && \
 apt-get update && \
 apt-get install -y libterm-readline-gnu-perl libreadline-dev libjson-xs-perl libyaml-perl \
 libuuid-tiny-perl libtie-ixhash-perl libev-perl libmodule-util-perl libarray-utils-perl \
 libcrypt-x509-perl libfile-finder-perl libdata-treedumper-perl libtest-class-perl \
 memcached libcache-memcached-fast-perl postgresql-9.5 libdbd-pg-perl cpanminus libsodium-dev \
 libnet-ldap-perl libxml2-dev build-essential unzip net-tools rsync lsof strace

RUN echo " #### BUILDING CPAN DEPENDENCIES #### " && \
 cpanm --notest Crypt::Sodium CryptX Number::Bytes::Human Date::Parse Mojolicious \
  Unix::Uptime Mojo::Pg CGI XML::CanonicalizeXML Minion Log::Syslog::Fast \
  Net::Netmask Mail::Sender BSD::Resource Linux::Inotify2 App::Prove App::cpanminus

# create an oaasvc user
RUN useradd -d /opt/osiris/aa_services -s /bin/bash -c "OSiRIS AA Services" -m oaasvc

ENV HOME=/opt/osiris/aa_services \
 PATH=/opt/osiris/aa_services/bin:/usr/lib/postgresql/9.5/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin \
 PGDATA=/opt/osiris/var/pgsql/data