# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

group :test do
  gem "rspec", '~> 3'
  gem "pry"
  gem 'simplecov', require: false
  gem 'stub_env', '~> 1.0'
  gem 'redis', '~> 4.8'
end
