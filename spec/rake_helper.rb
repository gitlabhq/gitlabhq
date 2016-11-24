require 'spec_helper'
require 'rake'

RSpec.configure do |config|
  config.include RakeHelpers

  # Redirect stdout so specs don't have so much noise
  config.before(:all) do
    $stdout = StringIO.new

    Rake.application.rake_require 'tasks/gitlab/task_helpers'
    Rake::Task.define_task :environment
  end

  # Reset stdout
  config.after(:all) do
    $stdout = STDOUT
  end
end
