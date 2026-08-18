# frozen_string_literal: true

# This replicates `require 'rubocop/rspec/support'` to workaround the issue
# in https://gitlab.com/gitlab-org/gitlab/-/issues/382452.
#
# All helpers are only included in rubocop specs (type: :rubocop/:rubocop_rspec).

require 'rubocop/rspec/cop_helper'
require 'rubocop/rspec/shared_contexts'
require 'rubocop/rspec/expect_offense'
require 'rubocop/rspec/parallel_formatter'

RSpec.configure do |config|
  config.include CopHelper, type: :rubocop
  config.include CopHelper, type: :rubocop_rspec
  config.include_context 'config', :config

  # Load `rubocop/server` for `:isolated_environment` groups only, so that
  # `RuboCop::Server::Cache` is defined. The 'isolated environment' shared
  # context guards its server-cache reset with `RuboCop.const_defined?(:Server)`,
  # which (default `inherit: true`) also matches an unrelated top-level `::Server`
  # constant leaked by another spec in a batched run. This must run at
  # group-definition time (before the shared context is included), which
  # `define_derived_metadata` does, preventing a
  # `NameError: uninitialized constant RuboCop::Server`.
  config.define_derived_metadata(:isolated_environment) do |_metadata|
    require 'rubocop/server'
  end
  config.include_context 'isolated environment', :isolated_environment
  config.include_context 'maintain registry', :restore_registry
  config.include_context 'ruby 3.1', :ruby31
  config.include_context 'ruby 3.2', :ruby32
  config.include_context 'ruby 3.3', :ruby33
end
