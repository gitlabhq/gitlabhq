# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Prometheus::PidProvider do
  describe '.worker_id' do
    subject { described_class.worker_id }

    before do
      allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(false)
    end

    context 'when running in Sidekiq server mode' do
      before do
        allow(Gitlab::Runtime).to receive(:sidekiq?).and_return(true)
      end

      context 'in a clustered setup' do
        before do
          stub_env('SIDEKIQ_WORKER_ID', '123')
        end

        it { is_expected.to eq 'sidekiq_123' }
      end

      context 'in a single process setup' do
        it { is_expected.to eq 'sidekiq' }
      end
    end

    context 'when running in Puma mode' do
      before do
        allow(Gitlab::Runtime).to receive(:puma?).and_return(true)

        expect(described_class).to receive(:process_name)
          .at_least(:once)
          .and_return(process_name)
      end

      context 'when cluster worker id is specified in process name' do
        let(:process_name) { 'puma: cluster worker 1: 17483 [gitlab-puma-worker]' }

        it { is_expected.to eq 'puma_1' }
      end

      context 'when no worker id is specified in process name' do
        let(:process_name) { 'bin/puma' }

        it { is_expected.to eq 'puma_master' }
      end
    end

    context 'when running in unknown mode' do
      it { is_expected.to eq "process_#{Process.pid}" }
    end
  end
end
