# frozen_string_literal: true

if $LOADED_FEATURES.include?(File.expand_path('../../spec_helper.rb', __dir__.to_s))
  # return if spec_helper is already loaded, so we don't accidentally override any configuration in it
  return
end

require_relative '../../fast_spec_helper'
require_relative '../../support/matchers/result_matchers'
require_relative '../../support/railway_oriented_programming'

require 'rspec-parameterized'
require 'json_schemer'
require 'devfile'
require 'gitlab/rspec/next_instance_of'

RSpec.configure do |config|
  # Ensure that all specs which require this fast_spec_helper have the `:rd_fast` tag at the top-level describe
  config.after(:suite) do
    RSpec.world.example_groups.each do |example_group|
      # Check only top-level describes
      next unless example_group.metadata[:parent_example_group].nil?

      unless example_group.metadata[:rd_fast]
        raise "Top-level describe blocks must have the `:rd_fast` tag when `rd_fast_spec_helper` is required. " \
          "It is missing on example group: #{example_group.description}"
      end
    end
  end

  # Set up rspec features required by the remote development specs
  config.include NextInstanceOf
  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = false
  end
end
