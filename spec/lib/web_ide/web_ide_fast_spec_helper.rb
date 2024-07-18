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
require 'gitlab/rspec/next_instance_of'

RSpec.configure do |config|
  # Set up rspec features required by the fast specs
  config.include NextInstanceOf
  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = false
  end
end
