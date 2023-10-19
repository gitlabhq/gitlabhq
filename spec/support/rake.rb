# frozen_string_literal: true

require_relative 'helpers/rake_helpers'

RSpec.configure do |config|
  config.include RakeHelpers, type: :task

  config.before(:all, type: :task) do
    require 'rake'

    Rake.application.rake_require 'tasks/gitlab/helpers'
    Rake::Task.define_task :environment
  end

  config.after(:all, type: :task) do
    # Fast specs cannot load `spec/support/database_cleaner` and its RSpec
    # helper DbCleaner.
    delete_from_all_tables!(except: deletion_except_tables) if defined?(DbCleaner)
  end
end
