FROM bash:5

LABEL maintainer="Srinath Sankar <srinath@iambot.net>"
LABEL version="0.1.0"

WORKDIR /home
ENTRYPOINT [ "/home/entrypoint.sh" ]

RUN apk add --no-cache gawk \
    && echo 'alias awk="gawk"' >> ~/.bashrc

COPY entrypoint.sh critic.sh ./
