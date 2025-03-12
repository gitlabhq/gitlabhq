# frozen_string_literal: true
require "rake"
require "rails/all"
require "rails/generators"
require "sequel"

if ENV['DATABASE'] == 'POSTGRESQL'
  require 'pg'
else
  require "sqlite3"
end

if ENV["ISOLATION_LEVEL_FIBER"]
  ActiveSupport::IsolatedExecutionState.isolation_level = :fiber
  puts "ActiveSupport::IsolatedExecutionState: #{ActiveSupport::IsolatedExecutionState.isolation_level}"
end

require_relative "generators/base_generator_test"
require_relative "data"

def with_active_record_log(colorize: true)
  io = StringIO.new
  prev_logger = ActiveRecord::Base.logger
  ActiveRecord::Base.logger = Logger.new(io)
  yield
  str = io.string
  if !colorize
    str.gsub!(/\e\[([;\d]+)?m/, '')
  end
  str
ensure
  ActiveRecord::Base.logger = prev_logger
end

if ActiveSupport.respond_to?(:test_order=)
  ActiveSupport.test_order = :random
end
