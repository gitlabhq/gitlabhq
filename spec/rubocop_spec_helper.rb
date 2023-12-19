# frozen_string_literal: true

# All RuboCop specs may use fast_spec_helper.
require 'fast_spec_helper'

# To prevent load order issues we need to require `rubocop` first.
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47008
require 'rubocop'
require 'rubocop/rspec/shared_contexts/default_rspec_language_config_context'
require 'gitlab/rspec/next_instance_of'

require_relative 'rubocop/support_workaround'

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{spec/rubocop}) do |metadata|
    metadata[:type] = :rubocop
  end

  config.define_derived_metadata(file_path: %r{spec/rubocop/cop/rspec}) do |metadata|
    metadata[:type] = :rubocop_rspec
  end

  config.include RuboCop::RSpec::ExpectOffense, type: :rubocop
  config.include RuboCop::RSpec::ExpectOffense, type: :rubocop_rspec
  config.include NextInstanceOf

  config.include_context 'config', type: :rubocop
  config.include_context 'with default RSpec/Language config', type: :rubocop_rspec
end
