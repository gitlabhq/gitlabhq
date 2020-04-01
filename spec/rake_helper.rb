# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.configure do |config|
  config.include RakeHelpers

  # Redirect stdout so specs don't have so much noise
  config.before(:all) do
    $stdout = StringIO.new

    Rake.application.rake_require 'tasks/gitlab/helpers'
    Rake::Task.define_task :environment
  end

  # Reset stdout
  config.after(:all) do
    $stdout = STDOUT

    delete_from_all_tables!
  end
end
