FROM ruby:2.4.1

RUN apt-get -q update \
  && DEBIAN_FRONTEND=noninteractive apt-get -q -y install \
    openssl \
    libssl-dev \
    git \
    g++ \
    libxml2-dev \
    libxslt-dev \
    libgmp-dev \
    make \
  && apt-get -q -y clean \
  && rm -rf /var/lib/apt/lists

COPY . /app
WORKDIR /app

RUN bundle install

CMD ["bundle", "exec", "rspec", "spec"]
