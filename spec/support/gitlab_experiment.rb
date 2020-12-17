# frozen_string_literal: true

# Disable all caching for experiments in tests.
Gitlab::Experiment::Configuration.cache = nil
