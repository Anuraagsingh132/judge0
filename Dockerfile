# Base stage
FROM ubuntu:20.04 AS production

ENV DEBIAN_FRONTEND=noninteractive

# Metadata
ENV JUDGE0_VERSION="1.13.1"
ENV JUDGE0_HOMEPAGE="https://judge0.com"
ENV JUDGE0_SOURCE_CODE="https://github.com/judge0/judge0"
ENV JUDGE0_MAINTAINER="Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com"

LABEL version=$JUDGE0_VERSION
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

# Setup Ruby (if needed)
ENV GEM_HOME="/opt/.gem/"
ENV PATH="$GEM_HOME/bin:$PATH"

RUN gem install bundler:2.1.4

# Optional: install aglio (ignore failures)
RUN npm install -g --unsafe-perm aglio@2.3.0 || true

# Working directory
WORKDIR /api

# Install Ruby dependencies
COPY Gemfile* ./
RUN bundle install

# Copy application source
COPY . .

# Setup cron
COPY cron /etc/cron.d/
RUN cat /etc/cron.d/* | crontab -

# Create and configure app user
RUN useradd -u 1000 -m -r judge0 && \
    echo "judge0 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers && \
    chown -R judge0:judge0 /api

USER judge0

# Expose the port used by the app (IMPORTANT for Render)
EXPOSE 8080

# Set working directory (in case user context resets it)
WORKDIR /api

# Ensure script is executable (make sure this is done in repo too)
RUN chmod +x scripts/server

# Start the server (your custom script)
CMD ["./scripts/server"]

# Optional: dev/debug stage
FROM production AS development
CMD ["sleep", "infinity"]
