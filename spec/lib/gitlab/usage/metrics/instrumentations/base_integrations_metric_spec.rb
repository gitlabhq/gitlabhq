# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::BaseIntegrationsMetric,
  feature_category: :integrations do
  it "raises an exception if options are not present" do
    expect do
      described_class.new(options: {}, time_frame: 'all')
    end.to raise_error(ArgumentError, %r{^'type' option is required})
  end

  it "is not available if options have an invalid value" do
    available = described_class.new(options: { type: 'blahblah' }, time_frame: 'all').available?
    expect(available).to be(false)
  end

  it "is available when options have a valid value" do
    available = described_class.new(options: { type: 'pivotaltracker' }, time_frame: 'all').available?
    expect(available).to be(true)
  end
end
