# frozen_string_literal: true

# All RuboCop specs may use fast_spec_helper.
require 'fast_spec_helper'

# To prevent load order issues we need to require `rubocop` first.
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47008
require 'rubocop'
require 'rubocop/rspec/support'

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense, type: :rubocop

  config.define_derived_metadata(file_path: %r{spec/rubocop}) do |metadata|
    metadata[:type] = :rubocop
  end

  # Include config shared context for all cop specs.
  config.include_context 'config', type: :rubocop
end
