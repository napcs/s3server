FROM ruby:2.6.0-alpine
MAINTAINER Brian Hogan <brianhogan@napcs.com>

run apk add --update ruby-dev build-base \
  libxml2-dev libxslt-dev pcre-dev libffi-dev

# Install gems
RUN mkdir /app
WORKDIR /app
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install

# make app folder and copy over the app
COPY ./views /app/views
COPY ./lib /app/lib
COPY ./public /app/public
COPY ./app.rb /app/app.rb
COPY ./config.ru /app/config.ru
COPY ./Procfile /app/Procfile

# Start server
EXPOSE 9292
CMD ["foreman", "start"]
