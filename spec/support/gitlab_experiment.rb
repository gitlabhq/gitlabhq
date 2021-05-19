# frozen_string_literal: true

# Require the provided spec helper and matchers.
require 'gitlab/experiment/rspec'
require_relative 'stub_snowplow'

# This is a temporary fix until we have a larger discussion around the
# challenges raised in https://gitlab.com/gitlab-org/gitlab/-/issues/300104
require Rails.root.join('app', 'experiments', 'application_experiment')
class ApplicationExperiment # rubocop:disable Gitlab/NamespacedClass
  def initialize(...)
    super(...)
    Feature.persist_used!(feature_flag_name)
  end
end

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
