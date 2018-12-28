FROM python:3-slim-stretch
LABEL maintainer Markku Virtanen
RUN apt update && \
    apt install -y gnupg jq && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4 && \
    echo "deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.0 main" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list && \
    apt update && \
    apt install -y mongodb-org-tools groff
RUN pip install --upgrade awscli
RUN mkdir -p /backup/data

ADD backup.sh /backup/run
WORKDIR /backup

ENTRYPOINT ["./run"]
CMD ["backup"]

