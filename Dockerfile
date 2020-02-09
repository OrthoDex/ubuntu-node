# --- base node build --------- #
FROM ubuntu:18.10 as base

ARG NODE_VERSION=${NODE_VERSION:-10.13.0}
ARG NPM_VERSION=${NPM_VERSION:-6.4.1}

# Create non sudo node user
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# Install base required libraries
RUN apt-get clean && apt-get update && apt-get -y install curl gpg python

# gpg keys listed at https://github.com/nodejs/node#release-keys
RUN set -ex \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done

# Install node from nodejs org binaries
RUN ARCH=x64 \
  && curl -fsSLO --compressed https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz \
  && curl -fsSLO --compressed https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt.asc \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep node-v${NODE_VERSION}-linux-${ARCH}.tar.xz SHASUMS256.txt | sha256sum -c - \
  && tar -xJf node-v${NODE_VERSION}-linux-${ARCH}.tar.xz -C /usr/local --strip-components=1 --no-same-owner \
  && rm node-v${NODE_VERSION}-linux-${ARCH}.tar.xz SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Configure TINI, a lightweight init system.
# See https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md#handling-kernel-signals
ARG TINI_VERSION=v0.18.0

ADD --chown=node:node https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini
ADD --chown=node:node https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /usr/local/bin/tini.asc
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
 && gpg --verify /usr/local/bin/tini.asc \
 && chmod +x /usr/local/bin/tini \
 && apt-get autoremove -y

# Set our NODE_ENV. Default to "production" since most libraries such as express use this to optimize for production environments
ARG NODE_ENV=${NODE_ENV:-production}
ENV NODE_ENV $NODE_ENV

# Set entrypoint as Tini
ENTRYPOINT ["tini", "--"]

FROM base as builder

## Install all base librariers
RUN apt-get install -y build-essential

# Run the process as a non root user
# Make sure we are running this container with this user namespace mapping to reduce the attack service in production
# run docker daemon with `dockerd --userns-remap=default`

ONBUILD ARG CODE_HOME=${CODE_HOME:-/home/node/app}

# Put code inside this dir
ONBUILD RUN mkdir -p $CODE_HOME && chown -R node:node $CODE_HOME

ONBUILD WORKDIR $CODE_HOME

ONBUILD USER node

ONBUILD COPY --chown=node:node package*.json $CODE_HOME/

# Install npm deps.
# This is done before the full directory is copied to allow node_modules caching between docker layer builds
ONBUILD RUN npm install --production

# Keep the actual copy last to maximize caching
ONBUILD COPY --chown=node:node . $CODE_HOME/

CMD ["node"]
