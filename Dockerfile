FROM ubuntu:18.04

ARG OPENTTD_VERSION="1.10.1"
ARG OPENGFX_VERSION="0.5.5"

ADD prepare.sh /tmp/prepare.sh
ADD cleanup.sh /tmp/cleanup.sh
ADD buildconfig /tmp/buildconfig
ADD --chown=1000:1000 openttd.sh /openttd.sh
ADD openttd.cfg /tmp/openttd.cfg
ADD openttdscripts /tmp/openttdscripts

VOLUME /home/openttd/.openttd

RUN chmod +x /tmp/prepare.sh /tmp/cleanup.sh /openttd.sh
RUN /tmp/prepare.sh \
    && /tmp/cleanup.sh

EXPOSE 3979/tcp
EXPOSE 3979/udp
EXPOSE 3978/udp
EXPOSE 3977/tcp

STOPSIGNAL 3
ENTRYPOINT [ "/usr/bin/dumb-init", "--rewrite", "15:3", "--rewrite", "9:3", "--" ]
CMD [ "/openttd.sh" ]
