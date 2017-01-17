FROM ruby:2.3.0
MAINTAINER Brian Hogan <brianhogan@napcs.com>

# Install gems
WORKDIR /tmp
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install
# Install gems

RUN mkdir /app
WORKDIR /app

# Upload source
COPY . /app


# Start server
EXPOSE 9292
CMD ["foreman", "start"]
