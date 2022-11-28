FROM debian:bullseye-slim

ENV LANG=en_EN.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8


RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests --allow-unauthenticated -y \
        gnupg \
        ca-certificates \
        wget \
        locales \
    && localedef -i en_US -f UTF-8 en_US.UTF-8 \
    # Add the current key for package downloading
    # Please refer to QGIS install documentation (https://www.qgis.org/fr/site/forusers/alldownloads.html#debian-ubuntu)
    && mkdir -m755 -p /etc/apt/keyrings \
    && wget -O /etc/apt/keyrings/qgis-archive-keyring.gpg https://download.qgis.org/downloads/qgis-archive-keyring.gpg \
    # Add repository for latest version of qgis-server
    # Please refer to QGIS repositories documentation if you want other version (https://qgis.org/en/site/forusers/alldownloads.html#repositories)
    && echo "deb [signed-by=/etc/apt/keyrings/qgis-archive-keyring.gpg] https://qgis.org/debian bullseye main" | tee /etc/apt/sources.list.d/qgis.list \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests --allow-unauthenticated -y \
        spawn-fcgi \
        xauth \
        xvfb \
        # extras needed for compilation
        build-essential \
        # from qgis INSTALL.md
        bison ca-certificates ccache cmake cmake-curses-gui dh-python doxygen expect flex flip gdal-bin git graphviz grass-dev libexiv2-dev libexpat1-dev libfcgi-dev libgdal-dev libgeos-dev libgsl-dev libpdal-dev libpq-dev libproj-dev libprotobuf-dev libqca-qt5-2-dev libqca-qt5-2-plugins libqscintilla2-qt5-dev libqt5opengl5-dev libqt5serialport5-dev libqt5sql5-sqlite libqt5svg5-dev libqt5webkit5-dev libqt5xmlpatterns5-dev libqwt-qt5-dev libspatialindex-dev libspatialite-dev libsqlite3-dev libsqlite3-mod-spatialite libyaml-tiny-perl libzip-dev libzstd-dev lighttpd locales ninja-build ocl-icd-opencl-dev opencl-headers pandoc pdal pkg-config poppler-utils protobuf-compiler pyqt5-dev pyqt5-dev-tools pyqt5.qsci-dev python3-all-dev python3-autopep8 python3-dateutil python3-dev python3-future python3-gdal python3-httplib2 python3-jinja2 python3-lxml python3-markupsafe python3-mock python3-nose2 python3-owslib python3-plotly python3-psycopg2 python3-pygments python3-pyproj python3-pyqt5 python3-pyqt5.qsci python3-pyqt5.qtpositioning python3-pyqt5.qtsql python3-pyqt5.qtsvg python3-pyqt5.qtwebkit python3-requests python3-sip python3-sip-dev python3-termcolor python3-tz python3-yaml qt3d-assimpsceneimport-plugin qt3d-defaultgeometryloader-plugin qt3d-gltfsceneio-plugin qt3d-scene2d-plugin qt3d5-dev qt5keychain-dev qtbase5-dev qtbase5-private-dev qtpositioning5-dev qttools5-dev qttools5-dev-tools saga spawn-fcgi xauth xfonts-100dpi xfonts-75dpi xfonts-base xfonts-scalable xvfb \
    \    
    && apt-get remove --purge -y \
        gnupg \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch final-3_28_1 https://github.com/qgis/QGIS.git \
    && cd QGIS \
    && mkdir build \
    && cd build \
    && cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DWITH_ANALYSIS=FALSE \
        -DWITH_BINDINGS=FALSE \
        -DWITH_DESKTOP=FALSE \
        -DWITH_GRASS7=FALSE \
        -DWITH_GRASS8=FALSE \
        -DWITH_GUI=FALSE \
        -DWITH_QGIS_PROCESS=FALSE \
        -DENABLE_TESTS=FALSE \
        -DWITH_SERVER=TRUE \
        .. \
    && ninja \
    && ninja install \
    && cd ../.. \
    && rm -rf QGIS

RUN ldconfig  # update linker cache with the new libs we have just installed

RUN useradd -m qgis

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

ENV QGIS_PREFIX_PATH /usr
ENV QGIS_SERVER_LOG_STDERR 1
ENV QGIS_SERVER_LOG_LEVEL 2

COPY cmd.sh /home/qgis/cmd.sh
RUN chmod -R 777 /home/qgis/cmd.sh
RUN chown qgis:qgis /home/qgis/cmd.sh

USER qgis
WORKDIR /home/qgis

ENTRYPOINT ["/tini", "--"]

CMD ["/home/qgis/cmd.sh"]
