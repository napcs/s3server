FROM ruby:2.3.0
MAINTAINER Brian Hogan <brianhogan@napcs.com>

# Install gems
WORKDIR /tmp
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install

# make app folder and copy over the app
RUN mkdir /app
WORKDIR /app
COPY . /app

# Start server
EXPOSE 9292
CMD ["foreman", "start"]
