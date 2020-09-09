# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::ActionCableSampler do
  subject { described_class.new }

  describe '#interval' do
    it 'samples every five seconds by default' do
      expect(subject.interval).to eq(5)
    end

    it 'samples at other intervals if requested' do
      expect(described_class.new(11).interval).to eq(11)
    end
  end

  describe '#sample' do
    before do
      expect(::ActionCable.server.connections).to receive(:size).and_return(42)
    end

    context 'for in-app mode' do
      it 'samples statistic with correct labels attached' do
        expect(Gitlab::ActionCable::Config).to receive(:in_app?).and_return(true)

        expect(subject.metrics[:active_connections]).to receive(:set).with({ server_mode: 'in-app' }, 42)

        subject.sample
      end
    end

    context 'for standalone mode' do
      it 'samples statistic with correct labels attached' do
        expect(Gitlab::ActionCable::Config).to receive(:in_app?).and_return(false)

        expect(subject.metrics[:active_connections]).to receive(:set).with({ server_mode: 'standalone' }, 42)

        subject.sample
      end
    end
  end
end
