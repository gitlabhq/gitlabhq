# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::BackgroundTransaction do
  let(:test_worker_class) { double(:class, name: 'TestWorker') }

  subject { described_class.new(test_worker_class) }

  describe '#label' do
    it 'returns labels based on class name' do
      expect(subject.labels).to eq(controller: 'TestWorker', action: 'perform')
    end
  end
end
