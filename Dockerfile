FROM bash:5
MAINTAINER Srinath Sankar

WORKDIR /home
ENTRYPOINT [ "/home/entrypoint.sh" ]

COPY entrypoint.sh critic.sh ./
