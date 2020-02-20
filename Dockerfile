FROM ubuntu:18.04
RUN apt-get -y update
RUN apt-get update && apt-get install -y \
    sudo\
    git \
    vim \
    zip \
    unzip \
    ssh

ENV GEM_HOME="/usr/local/bundle"
ENV PATH $GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH
ENV BUILD_DEPS="make gcc g++ libc-dev libffi-dev autoconf git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common"
ENV PACKER_VERSION="1.3.3"

RUN apt-get install --no-install-recommends -y ${BUILD_DEPS} ruby-full net-tools
RUN wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip
RUN unzip packer_${PACKER_VERSION}_linux_amd64.zip
RUN mv packer /usr/local/bin
RUN rm packer_${PACKER_VERSION}_linux_amd64.zip

RUN gem install bundler -v '2.0.2'
RUN mkdir /builderator
WORKDIR /builderator

RUN echo "source 'https://rubygems.org'" >> Gemfile
RUN echo "gem 'builderator', :git => 'https://github.com/rapid7/builderator.git', :branch => 'docker'" >> Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install --binstubs
ENTRYPOINT ["/builderator/bin/build"]
