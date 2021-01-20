FROM debian:stable-slim

RUN apt-get update && \
    apt-get upgrade && \
    apt-get install -y build-essential vi subversion automake autoconf telnet libxml2-dev mosquitto-clients git cmake python-docutils && mkdir mqtt && mkdir openv && cd openv
RUN git clone https://github.com/openv/vcontrold.git vcontrold-code && \
    cd vcontrold-code && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install

COPY config /etc/vcontrold

EXPOSE 3002/udp
ENTRYPOINT ["sh","/etc/vcontrold/startup.sh"]
