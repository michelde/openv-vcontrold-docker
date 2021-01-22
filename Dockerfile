FROM debian:stable-slim

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y build-essential vim subversion automake autoconf telnet libxml2-dev mosquitto-clients git cmake python-docutils
RUN mkdir openv && cd openv
RUN git clone https://github.com/openv/vcontrold.git vcontrold-code && \
    cd vcontrold-code && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install

COPY ./startup.sh /etc/vcontrold/

EXPOSE 3002/udp
ENTRYPOINT ["sh","/etc/vcontrold/startup.sh"]
