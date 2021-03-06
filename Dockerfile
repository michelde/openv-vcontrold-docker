FROM debian:stable-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y build-essential vim subversion automake autoconf telnet libxml2-dev mosquitto-clients git cmake python-docutils jq
RUN mkdir openv && cd openv && \
    git clone https://github.com/openv/vcontrold.git vcontrold-code && \
    cd vcontrold-code && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install

COPY ./startup.sh /etc/vcontrold/

EXPOSE 3002/udp
ENTRYPOINT ["sh","/etc/vcontrold/startup.sh"]
