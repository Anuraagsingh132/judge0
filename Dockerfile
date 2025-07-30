FROM ubuntu:20.04 AS production

ENV DEBIAN_FRONTEND=noninteractive

# Metadata
ENV JUDGE0_VERSION="1.13.1"
LABEL version=$JUDGE0_VERSION
ENV JUDGE0_HOMEPAGE="https://judge0.com"
ENV JUDGE0_SOURCE_CODE="https://github.com/judge0/judge0"
ENV JUDGE0_MAINTAINER="Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com>"

LABEL homepage=$JUDGE0_HOMEPAGE
LABEL source_code=$JUDGE0_SOURCE_CODE
LABEL maintainer=$JUDGE0_MAINTAINER

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl gnupg build-essential software-properties-common \
    libpq-dev nodejs postgresql-client redis cron \
    sudo ruby-full git && \
    rm -rf /var/lib/apt/lists/*

# Setup Ruby
ENV PATH="/usr/local/ruby-2.7.0/bin:/opt/.gem/bin:$PATH"
ENV GEM_HOME="/opt/.gem/"
RUN gem install bundler:2.1.4

# Optional: aglio for docs
RUN npm install -g --unsafe-perm aglio@2.3.0 || true

# App working directory
WORKDIR /api

# Copy Ruby app files and install
COPY Gemfile* ./
RUN bundle install

# Copy the rest of the application
COPY . .

# Setup cron
COPY cron /etc/cron.d
RUN cat /etc/cron.d/* | crontab -

# Setup Judge0 user
RUN useradd -u 1000 -m -r judge0 && \
    echo "judge0 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers && \
    chown judge0: /api/tmp/

USER judge0

EXPOSE 2358

ENTRYPOINT ["/api/docker-entrypoint.sh"]
CMD ["/api/scripts/server"]

# Optional: dev stage
FROM production AS development
CMD ["sleep", "infinity"]
