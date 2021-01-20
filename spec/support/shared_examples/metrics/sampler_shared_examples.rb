# frozen_string_literal: true

RSpec.shared_examples 'metrics sampler' do |env_prefix|
  context 'when sampling interval is passed explicitly' do
    subject { described_class.new(42) }

    specify { expect(subject.interval).to eq(42) }
  end

  context 'when sampling interval is passed through the environment' do
    subject { described_class.new }

    before do
      stub_env("#{env_prefix}_INTERVAL_SECONDS", '42')
    end

    specify { expect(subject.interval).to eq(42) }
  end

  context 'when no sampling interval is passed anywhere' do
    subject { described_class.new }

    it 'uses the hardcoded default' do
      expect(subject.interval).to eq(described_class::DEFAULT_SAMPLING_INTERVAL_SECONDS)
    end
  end
end
