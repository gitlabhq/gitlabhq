# frozen_string_literal: true

# Require the provided spec helper and matchers.
require 'gitlab/experiment/rspec'

RSpec.configure do |config|
  config.include StubSnowplow, :experiment

  # Disable all caching for experiments in tests.
  config.before do
    allow(Gitlab::Experiment::Configuration).to receive(:cache).and_return(nil)

    # Disable all deprecation warnings in the test environment, which can be
    # resolved one by one and tracked in:
    #
    # https://gitlab.com/gitlab-org/gitlab/-/issues/350944
    allow(Gitlab::Experiment::Configuration).to receive(:deprecator).and_wrap_original do |method, version|
      method.call(version).tap do |deprecator|
        deprecator.silenced = true
      end
    end
  end

  config.before(:each, :experiment) do
    stub_snowplow
  end
end
