# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.configure do |config|
  config.include RakeHelpers

  config.before(:all) do
    Rake.application.rake_require 'tasks/gitlab/helpers'
    Rake::Task.define_task :environment
  end

  config.after(:all, type: :task) do
    delete_from_all_tables!(except: deletion_except_tables)
  end
end
