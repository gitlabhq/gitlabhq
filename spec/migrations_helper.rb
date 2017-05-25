require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'

ActiveRecord::Base.establish_connection(:migrate)

RSpec.configure do |config|
  config.mock_with :rspec
  config.verbose_retry = true
  config.display_try_failure_messages = true
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.raise_errors_for_deprecations!

  config.around(:each, :migration) do |example|
    ActiveRecord::Tasks::DatabaseTasks.purge_current

    example.run

    ActiveRecord::Tasks::DatabaseTasks.purge_current
  end

  config.around(:each, :redis) do |example|
    Gitlab::Redis.with(&:flushall)
    Sidekiq.redis(&:flushall)

    example.run

    Gitlab::Redis.with(&:flushall)
    Sidekiq.redis(&:flushall)
  end
end


puts "Rails environment: #{Rails.env}"
puts "Database connection: #{ActiveRecord::Base.connection_config[:database]}"
