# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HealthChecks::PumaCheck do
  let(:result_class) { Gitlab::HealthChecks::Result }
  let(:readiness) { described_class.readiness }
  let(:metrics) { described_class.metrics }

  shared_examples 'with state' do |(state, message)|
    it "does provide readiness" do
      expect(readiness).to eq(result_class.new('puma_check', state, message))
    end

    it "does provide metrics" do
      expect(metrics).to include(
        an_object_having_attributes(name: 'puma_check_success', value: state ? 1 : 0))
      expect(metrics).to include(
        an_object_having_attributes(name: 'puma_check_latency_seconds', value: be >= 0))
    end
  end

  context 'when Puma is not loaded' do
    before do
      allow(Gitlab::Runtime).to receive(:puma?).and_return(false)
      hide_const('Puma')
    end

    it "does not provide readiness and metrics" do
      expect(readiness).to be_nil
      expect(metrics).to be_nil
    end
  end

  context 'when Puma is loaded' do
    before do
      allow(Gitlab::Runtime).to receive(:puma?).and_return(true)
      stub_const('Puma', Module.new)
    end

    context 'when stats are missing' do
      before do
        expect(Puma).to receive(:stats).and_raise(NoMethodError)
      end

      it_behaves_like 'with state', [false, 'unexpected Puma check result: 0']
    end

    context 'for Single mode' do
      before do
        expect(Puma).to receive(:stats) do
          '{}'
        end
      end

      it_behaves_like 'with state', true
    end

    context 'for Cluster mode' do
      before do
        expect(Puma).to receive(:stats) do
          '{"workers":2}'
        end
      end

      it_behaves_like 'with state', true
    end
  end
end
