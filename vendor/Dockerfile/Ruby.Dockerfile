FROM ruby:2.7

# Edit with nodejs, mysql-client, postgresql-client, sqlite3, etc. for your needs.
# Or delete entirely if not needed.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nodejs \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock /usr/src/app/
RUN bundle install -j $(nproc)

COPY . /usr/src/app

# For Sinatra
#EXPOSE 4567
#CMD ["ruby", "./config.rb"]

# For Rails
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
