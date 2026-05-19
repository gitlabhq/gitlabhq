# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Callbacks, feature_category: :database do
  # Around each example, reset the state of the callbacks so that specs don't pollute state
  around do |example|
    metrics_host_gauge_proc = described_class.metrics_host_gauge_proc
    track_exception_proc = described_class.track_exception_proc

    example.run

    described_class.configure! do |cb|
      cb.metrics_host_gauge_proc = metrics_host_gauge_proc
      cb.track_exception_proc = track_exception_proc
    end
  end

  describe '.track_exception' do
    let(:error) { RuntimeError.new('error') }

    subject(:track_exception) { described_class.track_exception(error) }

    context 'when track_exception_proc is configured' do
      let(:probe) { instance_double(Proc) }

      before do
        described_class.configure! { |cb| cb.track_exception_proc = probe }
      end

      it 'calls the proc with the exception' do
        expect(probe).to receive(:call).with(error)

        track_exception
      end
    end

    context 'when track_exception_proc is nil' do
      before do
        described_class.configure! { |cb| cb.track_exception_proc = nil }
      end

      it 'does not raise' do
        expect { track_exception }.not_to raise_error
      end
    end
  end

  describe '.metrics_host_gauge' do
    let(:labels) { { role: :replica } }
    let(:value) { 1 }

    subject(:metrics_host_gauge) { described_class.metrics_host_gauge(labels, value) }

    context 'when metrics_host_gauge_proc is configured' do
      let(:probe) { instance_double(Proc) }

      before do
        described_class.configure! { |cb| cb.metrics_host_gauge_proc = probe }
      end

      it 'calls the proc with labels and value' do
        expect(probe).to receive(:call).with(labels, value)

        metrics_host_gauge
      end
    end

    context 'when metrics_host_gauge_proc is nil' do
      before do
        described_class.configure! { |cb| cb.metrics_host_gauge_proc = nil }
      end

      it 'does not raise' do
        expect { metrics_host_gauge }.not_to raise_error
      end
    end
  end
end
