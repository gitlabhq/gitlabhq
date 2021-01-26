# frozen_string_literal: true

# Require the provided spec helper and matchers.
require 'gitlab/experiment/rspec'

# Disable all caching for experiments in tests.
Gitlab::Experiment::Configuration.cache = nil
