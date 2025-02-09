FROM debian:bookworm-slim as base
RUN apt-get update && apt-get -y dist-upgrade \
 && apt-get install -y \
    rtl-sdr \
    libasound2 \
    libusb-1.0-0 \
    libhamlib4 \
    libgps28 \
 && rm -rf /var/lib/apt/lists/*

FROM base as builder
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    cmake \
    libasound2-dev \
    libudev-dev \
    libgpiod2 \
    libusb-1.0-0-dev \
    libhamlib-dev \
    libgps-dev \   
 && rm -rf /var/lib/apt/lists/*

RUN git clone "https://github.com/wb2osz/direwolf.git" /tmp/direwolf \
  && cd /tmp/direwolf \
  && mkdir build && cd build \
  && cmake .. \
  && make -j4 \
  && make DESTDIR=/target install \
  && make install-conf \
  && find /target/usr/local/bin/ -type f -exec strip -p --strip-debug {} \;

FROM base
COPY --from=builder /target/usr/local/bin /usr/local/bin
COPY --from=builder /target/etc/udev/rules.d/99-direwolf-cmedia.rules /etc/udev/rules.d/99-direwolf-cmedia.rules

ENV CALLSIGN "N0CALL"
ENV PASSCODE "-1"
ENV IGSERVER "noam.aprs2.net"
ENV FREQUENCY "144.39M"
ENV COMMENT "https://github.com/pheezer/docker-direwolf"
ENV SYMBOL "igate"

RUN mkdir -p /etc/direwolf
RUN mkdir -p /var/log/direwolf
RUN addgroup -gid 242 direwolf && adduser -q -uid 242 -gid 242 --no-create-home --disabled-login --gecos "" direwolf 
RUN usermod -a -G audio direwolf; usermod -a -G dialout direwolf
COPY start.sh direwolf.conf /etc/direwolf/
RUN chown 242.242 -R /etc/direwolf
RUN chown 242.242 -R /var/log/direwolf

USER direwolf 
WORKDIR /etc/direwolf

CMD ["/bin/bash", "/etc/direwolf/start.sh"]
