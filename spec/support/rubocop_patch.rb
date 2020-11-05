# frozen_string_literal: true

# There is an issue between rubocop versions 0.86 and 0.87 (verified by testing locally)
# where the monkey patching in cop_helper is referencing class Cop and should really be referencing class Base instead
# the gem's version of the cop_helper causes this issue when testing a rubocop cop locally and in CI
# The only difference in this file as compared to gem source file is that we include our own cop_helper instead
# which is a direct copy with a fix for the monkey patching part.
# Doing this, resolves the issue.
# Ideally we should move away from using the cop_helper at all as is the direction of rubocop as seen
# here - https://github.com/rubocop-hq/rubocop/issues/8003
# more info https://gitlab.com/gitlab-org/gitlab/-/merge_requests/46477

require_relative 'helpers/cop_helper'
require 'rubocop/rspec/host_environment_simulation_helper'
require 'rubocop/rspec/shared_contexts'
require 'rubocop/rspec/expect_offense'

RSpec.configure do |config|
  config.include CopHelper
  config.include HostEnvironmentSimulatorHelper
end
