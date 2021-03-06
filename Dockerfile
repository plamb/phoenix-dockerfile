# This image is designed as a base image to use in building actual releases. I've
# added a phoenix run at the end so that it will work out of the box.
# It includes quite a few things that you would not need for just a pure runtime
# but is also suitable to use as a base for a phoenix app including npm and sass

FROM debian:jessie

MAINTAINER Paul Lamb <paul@oil-law.com>

ENV REFRESHED_AT 2016-01-02
# 2015-12-20 update erlang to 18.* so that it will pick up the latest one (18.2 isn't in repo yet)

ENV DEBIAN_FRONTEND noninteractive

# Get base packages, dev tools, and set the locale
RUN apt-get update && apt-get install -y -qq --no-install-recommends \
    apt-transport-https \
    automake \
    build-essential \
    ca-certificates \
    curl \
    git \
    libicu-dev \
    libtool \
    locales \
    lsb-release \
    openssl \
    rlwrap \
    unzip \
    wget && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN curl -o /tmp/erlang.deb http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
    dpkg -i /tmp/erlang.deb && \
    rm -rf /tmp/erlang.deb && \
    apt-get update && apt-get install -y -qq --no-install-recommends \
    # erlang-base=1:18.1 erlang-dev=1:18.1 erlang-eunit=1:18.1 erlang-xmerl=1:18.1 \
    erlang=1:18.* &&\
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download and Install Specific Version of Elixir
WORKDIR /elixir
RUN wget -q https://github.com/elixir-lang/elixir/releases/download/v1.2.0/Precompiled.zip && \
    unzip Precompiled.zip && \
    rm -f Precompiled.zip && \
    ln -s /elixir/bin/elixirc /usr/local/bin/elixirc && \
    ln -s /elixir/bin/elixir /usr/local/bin/elixir && \
    ln -s /elixir/bin/mix /usr/local/bin/mix && \
    ln -s /elixir/bin/iex /usr/local/bin/iex

# debian has old version of node, so we install current one
# https://github.com/nodesource/docker-node/tree/master/debian/jessie/node/5.3.0
RUN curl https://deb.nodesource.com/node_5.x/pool/main/n/nodejs/nodejs_5.3.0-1nodesource1~jessie1_amd64.deb > node.deb \
 && dpkg -i node.deb \
     && rm node.deb

# Install local Elixir hex and rebar
RUN /usr/local/bin/mix local.hex --force && \
    /usr/local/bin/mix local.rebar --force && \
    /usr/local/bin/mix hex.info

ADD build_sass.sh /tmp/
RUN /tmp/build_sass.sh

WORKDIR /home/app/webapp

# Again, we're caching node_modules if you don't change package.json
ADD package.json /home/app/webapp/
RUN npm install

ENV PORT 4000
ENV MIX_ENV prod
# This prevents us from installing devDependencies
ENV NODE_ENV production
# This causes brunch to build minified and hashed assets
ENV BRUNCH_ENV production

COPY . /home/app/webapp

RUN mix deps.get && \
   mix deps.compile && \
   mix compile && \
   node node_modules/brunch/bin/brunch build && \
   mix phoenix.digest

EXPOSE 4000
CMD ["mix","phoenix.server"]
