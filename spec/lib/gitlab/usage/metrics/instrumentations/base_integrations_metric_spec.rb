# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::BaseIntegrationsMetric,
  feature_category: :integrations do
  it "raises an exception if options are not present" do
    expect do
      described_class.new(options: {}, time_frame: 'all')
    end.to raise_error(ArgumentError, %r{^Type must be one of})
  end

  it "raises an exception if options have an invalid value" do
    expect do
      described_class.new(options: { type: 'blahblah' }, time_frame: 'all')
    end.to raise_error(ArgumentError, %r{^Invalid type blahblah. Type must be one of})
  end

  it "raises no exceptions when options have a valid value" do
    expect do
      described_class.new(options: { type: 'pivotaltracker' }, time_frame: 'all')
    end.not_to raise_error
  end
end
