# frozen_string_literal: true

# This replicates `require 'rubocop/rspec/support'` to workaround the issue
# in https://gitlab.com/gitlab-org/gitlab/-/issues/382452.
#
# All helpers are only included in rubocop specs (type: :rubocop/:rubocop_rspec).

require 'rubocop/rspec/cop_helper'
require 'rubocop/rspec/host_environment_simulation_helper'
require 'rubocop/rspec/shared_contexts'
require 'rubocop/rspec/expect_offense'
require 'rubocop/rspec/parallel_formatter'

RSpec.configure do |config|
  config.include CopHelper, type: :rubocop
  config.include CopHelper, type: :rubocop_rspec
  config.include HostEnvironmentSimulatorHelper, type: :rubocop
  config.include HostEnvironmentSimulatorHelper, type: :rubocop_rspec
  config.include_context 'config', :config
  config.include_context 'isolated environment', :isolated_environment
  config.include_context 'maintain registry', :restore_registry
  config.include_context 'ruby 2.0', :ruby20
  config.include_context 'ruby 2.1', :ruby21
  config.include_context 'ruby 2.2', :ruby22
  config.include_context 'ruby 2.3', :ruby23
  config.include_context 'ruby 2.4', :ruby24
  config.include_context 'ruby 2.5', :ruby25
  config.include_context 'ruby 2.6', :ruby26
  config.include_context 'ruby 2.7', :ruby27
  config.include_context 'ruby 3.0', :ruby30
  config.include_context 'ruby 3.1', :ruby31
  config.include_context 'ruby 3.2', :ruby32
end
