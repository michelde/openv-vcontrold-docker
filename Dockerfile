FROM debian:stable-slim

RUN apt-get update && \
    apt-get upgrade -y
RUN apt-get install -y build-essential vim subversion automake autoconf libxml2-dev mosquitto-clients git cmake jq iputils-ping 
RUN mkdir openv && cd openv && \
    git clone https://github.com/openv/vcontrold.git vcontrold-code && \
    cmake ./vcontrold-code -DVSIM=ON -DMANPAGES=OFF && \
    make && \
    make install

ADD config /etc/vcontrold/
#ADD mqtt_publish.sh /etc/vcontrold/
#ADD mqtt_sub.sh /etc/vcontrold/
#ADD vito.xml /etc/vcontrold/
#ADD vcontrold.xml /etc/vcontrold/
ADD startup.sh /

EXPOSE 3002/udp
ENTRYPOINT ["sh","/startup.sh"]
