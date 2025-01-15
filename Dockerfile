FROM ruby:3.2.6-alpine AS builder

# Install all needed *build* dependencies
RUN apk add --no-cache \
  build-base \
  libxml2-dev \
  libxslt-dev \
  pcre-dev \
  libffi-dev

WORKDIR /app

# Copy Gemfiles first to leverage Docker’s caching mechanism
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

# Install gems (they go into /usr/local/bundle by default)
RUN bundle install --jobs=4 --retry=3

# ------------------------
# 2. FINAL STAGE
# ------------------------
FROM ruby:3.2.6-alpine

# Install only the runtime dependencies needed by the gems
# (If you’re not certain which you need, you can start with the same set
# and remove any that aren't required at runtime.)
RUN apk add --no-cache \
  libxml2 \
  libxslt \
  pcre \
  libffi

# Copy the bundled gems from the builder stage into this final stage
COPY --from=builder /usr/local/bundle /usr/local/bundle

WORKDIR /app

# Copy the rest of your application code
COPY ./views ./views
COPY ./lib ./lib
COPY ./public ./public
COPY ./app.rb ./app.rb
COPY ./config.ru ./config.ru
COPY ./Procfile ./Procfile

# Expose and start
EXPOSE 9292
CMD ["foreman", "start"]
