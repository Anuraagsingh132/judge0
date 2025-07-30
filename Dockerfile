# Base Image
FROM ubuntu:20.04 AS production

ENV DEBIAN_FRONTEND=noninteractive

# Metadata
ENV JUDGE0_VERSION="1.13.1"
ENV JUDGE0_HOMEPAGE="https://judge0.com"
ENV JUDGE0_SOURCE_CODE="https://github.com/judge0/judge0"
ENV JUDGE0_MAINTAINER="Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com>"

LABEL version=$JUDGE0_VERSION
LABEL homepage=$JUDGE0_HOMEPAGE
LABEL source_code=$JUDGE0_SOURCE_CODE
LABEL maintainer=$JUDGE0_MAINTAINER

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl gnupg build-essential software-properties-common \
  libpq-dev nodejs postgresql-client redis cron \
  ruby-full git && \
  rm -rf /var/lib/apt/lists/*

# Set Ruby env
ENV GEM_HOME="/opt/.gem"
ENV PATH="$GEM_HOME/bin:$PATH"

# Install bundler
RUN gem install bundler:2.1.4

# Install aglio for docs (optional)
RUN npm install -g --unsafe-perm aglio@2.3.0 || true

# App directory
WORKDIR /api

# Install Ruby dependencies
COPY Gemfile* ./
RUN bundle install

# Copy the app
COPY . .

# Setup cron
COPY cron /etc/cron.d/
RUN cat /etc/cron.d/* | crontab -

# Create non-root user
RUN useradd -u 1000 -m -r judge0 && \
  chown -R judge0:judge0 /api

USER judge0

# Make sure server script is executable
RUN chmod +x scripts/server

# Render expects the app to bind to PORT environment variable
EXPOSE 8080

# Final command
CMD ["./scripts/server"]

# Optional development/debug stage
FROM production AS development
CMD ["sleep", "infinity"]
