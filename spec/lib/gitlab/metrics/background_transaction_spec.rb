# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::BackgroundTransaction do
  let(:test_worker_class) { double(:class, name: 'TestWorker') }

  subject { described_class.new(test_worker_class) }

  describe '#label' do
    it 'returns labels based on class name' do
      expect(subject.labels).to eq(controller: 'TestWorker', action: 'perform', feature_category: '')
    end

    it 'contains only the labels defined for metrics' do
      expect(subject.labels.keys).to contain_exactly(*described_class.superclass::BASE_LABELS.keys)
    end

    it 'includes the feature category if there is one' do
      expect(test_worker_class).to receive(:get_feature_category).and_return('source_code_management')
      expect(subject.labels).to include(feature_category: 'source_code_management')
    end
  end
end
