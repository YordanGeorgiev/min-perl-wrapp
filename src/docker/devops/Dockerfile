FROM ubuntu:20.04

ARG UID
ARG GID

ENV PRODUCT_NAME="min-perl-wrapp"
ENV PRODUCT_DIR="/opt/min-perl-wrapp"
ENV USR="ubuntu"
ENV GRP="ubuntu"
ENV TERM="xterm-256color"
ENV TZ="Etc/UTC"
VOLUME $PRODUCT_DIR

ENV TERM="xterm-256color"
ENV TZ="Etc/UTC"

RUN echo \n\
XKBMODEL="pc105" \n\
XKBLAYOUT="se" \n\
XKBVARIANT="" \n\
XKBOPTIONS="" \n\
BACKSPACE="guess" \n\
 > /etc/default/keyboard

# ubuntu 20.04 os utils
RUN export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get upgrade -y && \
   apt-get install -y --no-install-recommends apt-utils
RUN export DEBIAN_FRONTEND=noninteractive && ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
   apt-get install -y --no-install-recommends tzdata && \
   dpkg-reconfigure --frontend noninteractive tzdata
RUN export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        lsb-release sudo curl net-tools wget \
        git zip unzip build-essential linux-headers-5.4.0-1037-aws \
        perl make vim ufw jq snapd debconf-utils dialog telnet graphviz
RUN export DEBIAN_FRONTEND=noninteractive && apt-get clean all && apt-get install --fix-missing

# Enable host to container edit of proj code on ubuntu and mac.
RUN test -z $(getent group $GID | cut -d: -f1) || \
      groupmod -g $((GID+1000)) $(getent group $GID | cut -d: -f1)

RUN addgroup --gid $GID $GRP
RUN adduser \
      --gid $GID \
      --shell "/bin/bash" \
      --home "/home/$USR" \
      --uid $UID \
      $USR && exit 0 

RUN echo "ubuntu:1432@lAFk" | chpasswd
RUN echo "$USR ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER $USR
ENV USER=$USR
ENV GROUP=$GRP

ADD --chown=$USR:$GRP "." "/opt/kafka-poc"


USER ubuntu
ENV USER=ubuntu

ADD --chown=$USR:$GRP "." "/home/ubuntu/$PRODUCT_DIR"

# install the perl modules
RUN /home/ubuntu/$PRODUCT_DIR/src/bash/deploy/ubuntu/run.sh -a do_check_install_perl_modules

WORKDIR $PRODUCT_DIR
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
