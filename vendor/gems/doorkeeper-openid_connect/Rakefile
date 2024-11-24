# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

task default: :spec
task test: :spec

desc 'Generate and run migrations in the test application'
task :migrate do
  Dir.chdir('spec/dummy') do
    system('bin/rails generate doorkeeper:openid_connect:migration')
    system('bin/rake db:migrate')
  end
end

desc 'Run server in the test application'
task :server do
  Dir.chdir('spec/dummy') do
    system('bin/rails server')
  end
end
