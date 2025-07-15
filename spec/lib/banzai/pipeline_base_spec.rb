# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::PipelineBase, feature_category: :markdown do
  it 'subclasses HTML::Pipeline' do
    expect(described_class <= ::HTML::Pipeline).to be_truthy
  end

  describe '#filter_subscription_name' do
    it 'adds thread id to subscription name' do
      expect(described_class.filter_subscription_name)
        .to eq "call_filter.html_pipeline_#{Thread.current.object_id}"
    end
  end

  describe '.perform_filter' do
    it 'overrides the perform_filter method' do
      expect(described_class).to receive(:filter_subscription_name).and_call_original.at_least(:once)

      Banzai::Pipeline::QuickActionPipeline.call('foo', project: nil)
    end
  end
end
