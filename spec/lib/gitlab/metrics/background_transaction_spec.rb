require 'spec_helper'

describe Gitlab::Metrics::BackgroundTransaction do
  let(:test_worker_class) { double(:class, name: 'TestWorker') }

  subject { described_class.new(test_worker_class) }

  describe '#action' do
    it 'returns transaction action name' do
      expect(subject.action).to eq('TestWorker#perform')
    end
  end

  describe '#label' do
    it 'returns labels based on class name' do
      expect(subject.labels).to eq(controller: 'TestWorker', action: 'perform')
    end
  end
end
