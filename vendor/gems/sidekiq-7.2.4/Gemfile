source "https://rubygems.org"

gemspec

gem "rake"
RAILS_VERSION = "~> 7.1"
gem "actionmailer", RAILS_VERSION
gem "actionpack", RAILS_VERSION
gem "activejob", RAILS_VERSION
gem "activerecord", RAILS_VERSION
gem "railties", RAILS_VERSION
gem "redis-client"
# gem "bumbler"
# gem "debug"

gem "sqlite3", "~> 1.4", platforms: :ruby
gem "activerecord-jdbcsqlite3-adapter", platforms: :jruby
gem "after_commit_everywhere", require: false
gem "yard"

group :test do
  gem "maxitest"
  gem "simplecov"
end

group :development, :test do
  gem "standard", require: false
end

group :load_test do
  gem "toxiproxy"
  gem "ruby-prof"
end
