FROM ruby:2.4-alpine

# Edit with nodejs, mysql-client, postgresql-client, sqlite3, etc. for your needs.
# Or delete entirely if not needed.
RUN apk --no-cache add nodejs postgresql-client

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock /usr/src/app/
RUN bundle install

COPY . /usr/src/app

# For Sinatra
#EXPOSE 4567
#CMD ["ruby", "./config.rb"]

# For Rails
EXPOSE 3000
CMD ["rails", "server"]
