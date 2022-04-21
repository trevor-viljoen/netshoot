FROM rockylinux:8.5 as fetcher
COPY build/fetch_binaries.sh /tmp/fetch_binaries.sh

RUN dnf upgrade -y \
 && dnf install -y \
    wget

RUN /tmp/fetch_binaries.sh

FROM registry.access.redhat.com/ubi8/ubi:8.5 as websocat-build
RUN dnf install -y \
    rust-toolset \
    git \
    openssl-devel \
 && git clone https://github.com/vi/websocat.git \
 && cd websocat \
 && cargo build --release --features=ssl \
 && cp target/release/websocat /usr/local/bin/

FROM rockylinux:8.5
COPY --from=websocat-build /usr/local/bin/websocat /usr/local/bin/
RUN dnf -y upgrade \
 && dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
 && dnf install -y http://repo.okay.com.mx/centos/8/x86_64/release/okay-release-1-5.el8.noarch.rpm \
 && sed -i '/^failovermethod/d' /etc/yum.repos.d/okay.repo \
 && dnf install -y \
    httpd-tools \
    bind-utils \
    ldns-utils \
    bridge-utils \
    conntrack-tools \
    dhcping \
    dnstracer \
    ethtool \
    file\
    fping \
    iftop \
    iperf \
    iperf3 \
    iproute \
    ipset \
    iptables \
    iptraf-ng \
    iputils \
    ipvsadm \
    jq \
    glibc \
    liboping \
    mtr \
    net-snmp-utils \
    netcat \
    nftables \
    ngrep \
    nmap \
    openssl \
    python3-pip \
    python3-setuptools \
    scapy \
    socat \
    speedtest-cli \
    strace \
    tcpdump \
    #traceroute-3 \
    util-linux \
    vim \
    git \
    zsh \
    wireshark-cli \
    swaks

# Installing httpie ( https://httpie.io/docs#installation)
RUN pip3 install --upgrade httpie

# Installing ctop - top-like container monitor
COPY --from=fetcher /tmp/ctop /usr/local/bin/ctop

# Installing calicoctl
COPY --from=fetcher /tmp/calicoctl /usr/local/bin/calicoctl

# Installing termshark
COPY --from=fetcher /tmp/termshark /usr/local/bin/termshark

# Setting User and Home
USER root
WORKDIR /root
ENV HOSTNAME netshoot

# ZSH Themes
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
COPY zshrc .zshrc
COPY motd motd

# Fix permissions for OpenShift and tshark
RUN chmod -R g=u /root
RUN chown root:root /usr/bin/dumpcap

# Running ZSH
CMD ["zsh"]
