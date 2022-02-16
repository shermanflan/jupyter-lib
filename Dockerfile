# 20.04 supports msodbcsql17
# Add platform qualifier for Mac M1 (see https://stackoverflow.com/a/69572323)
FROM  --platform=linux/amd64 ubuntu:20.04

ENV APP_HOME=/opt/jupyter-lib
ENV PATH=$PATH:${APP_HOME}

RUN  useradd -ms /bin/bash -r -d ${APP_HOME} jupyter-lib

ENV ACCEPT_EULA=Y
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York

# Download appropriate package for the OS version
# curl https://packages.microsoft.com/config/ubuntu/[##.##]/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update \
    && apt-get install -y \
        curl git \
        build-essential \
        software-properties-common \
        locales \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && apt-get install -y \
        # For odbc
        msodbcsql17 \
        mssql-tools \
        unixodbc-dev \
        # For parquet, snappy
        llvm libsnappy-dev \
        python3-pip \
        # For psycopg2
        python3-dev libpq-dev \
        python-setuptools \
    # libpostal
#    && git clone https://github.com/openvenues/libpostal \
#    && cd libpostal \
#    && ./bootstrap.sh \
#    && ./configure --datadir=$APP_HOME/data \
#    && make -j4 \
#    && make install \
#    && ldconfig \
    # End libpostal
    && apt-get purge -y curl git software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ${APP_HOME}/requirements.txt

RUN pip3 --no-cache-dir install -r ${APP_HOME}/requirements.txt \
    && rm /${APP_HOME}/requirements.txt \
    && apt-get purge -y build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=jupyter-lib:jupyter-lib ./condesa ${APP_HOME}/condesa
COPY --chown=jupyter-lib:jupyter-lib ./main.py ${APP_HOME}
# COPY --chown=jupyter-lib:jupyter-lib ./jupyter/data/locations ${APP_HOME}/data

USER jupyter-lib

WORKDIR ${APP_HOME}

ENV PATH="$PATH:/opt/mssql-tools/bin"
ENV PYTHONPATH=${APP_HOME}

CMD ["python3", "main.py"]