ARG ARCH

FROM astroswarm/base-$ARCH:latest

# Install X dependencies
RUN apt-get -y update && apt-get -y install \
  x11vnc \
  xvfb

# Install build dependencies
RUN apt-get -y update && apt-get -y install \
  build-essential \
  cmake \
  git \
  libindi-dev \
  libnova-dev \
  libwxgtk3.0-dev \
  pkg-config \
  wget \
  wx-common \
  wx3.0-i18n \
  zlib1g-dev
  
# Configure application
ARG VERSION

# Build
RUN wget https://github.com/OpenPHDGuiding/phd2/archive/v$VERSION.tar.gz
RUN gunzip v$VERSION.tar.gz
RUN tar xf v$VERSION.tar
RUN rm v$VERSION.tar
WORKDIR /phd2-$VERSION
RUN mkdir /phd2-$VERSION/tmp
WORKDIR /phd2-$VERSION/tmp
RUN cmake ..
RUN make -j $(grep -c ^processor /proc/cpuinfo)
RUN make -j $(grep -c ^processor /proc/cpuinfo) install # Installs help file to /usr/local/share/phd2/PHD2GuideHelp.zip
WORKDIR /tmp
RUN rm -rf /phd2-$VERSION

# Configure display
ENV BIT_DEPTH 16
ENV GUI_HEIGHT 1260
ENV GUI_WIDTH 1660

# Create startup script to run full graphical environment followed by phd2
RUN echo "#!/usr/bin/env sh" > /start.sh
# Docker doesn't clean the file system on restart, so clean any old lock that may exist
RUN echo "/bin/rm -f /tmp/.X0-lock" >> /start.sh
RUN echo "/usr/bin/Xvfb :0 -screen 0 ${GUI_WIDTH}x${GUI_HEIGHT}x${BIT_DEPTH} &" >> /start.sh
RUN echo "/usr/bin/x11vnc -display :0 -forever &" >> /start.sh
RUN echo "DISPLAY=:0 /usr/local/bin/phd2" >> /start.sh
RUN echo "" >> /start.sh
RUN chmod +x /start.sh

EXPOSE 5900

CMD "/start.sh"
