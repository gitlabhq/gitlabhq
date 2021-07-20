# frozen_string_literal: true

# Require the provided spec helper and matchers.
require 'gitlab/experiment/rspec'
require_relative 'stub_snowplow'

RSpec.configure do |config|
  config.include StubSnowplow, :experiment

  # Disable all caching for experiments in tests.
  config.before do
    allow(Gitlab::Experiment::Configuration).to receive(:cache).and_return(nil)
  end

  config.before(:each, :experiment) do
    stub_snowplow
  end
end
