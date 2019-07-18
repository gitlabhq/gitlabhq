# frozen_string_literal: true

require 'fast_spec_helper'

describe Prometheus::PidProvider do
  describe '.worker_id' do
    subject { described_class.worker_id }

    let(:sidekiq_module) { Module.new }

    before do
      allow(sidekiq_module).to receive(:server?).and_return(false)
      stub_const('Sidekiq', sidekiq_module)
    end

    context 'when running in Sidekiq server mode' do
      before do
        expect(Sidekiq).to receive(:server?).and_return(true)
      end

      it { is_expected.to eq 'sidekiq' }
    end

    context 'when running in Unicorn mode' do
      before do
        stub_const('Unicorn::Worker', Class.new)
        hide_const('Puma')
      end

      context 'when `Prometheus::Client::Support::Unicorn` provides worker_id' do
        before do
          expect(::Prometheus::Client::Support::Unicorn).to receive(:worker_id).and_return(1)
        end

        it { is_expected.to eq 'unicorn_1' }
      end

      context 'when no worker_id is provided from `Prometheus::Client::Support::Unicorn`' do
        before do
          expect(::Prometheus::Client::Support::Unicorn).to receive(:worker_id).and_return(nil)
        end

        it { is_expected.to eq 'unicorn_master' }
      end
    end

    context 'when running in Puma mode' do
      before do
        stub_const('Puma', Module.new)
        hide_const('Unicorn::Worker')
      end

      context 'when cluster worker id is specified in process name' do
        before do
          expect(described_class).to receive(:process_name).and_return('puma: cluster worker 1: 17483 [gitlab-puma-worker]')
        end

        it { is_expected.to eq 'puma_1' }
      end

      context 'when no worker id is specified in process name' do
        before do
          expect(described_class).to receive(:process_name).and_return('bin/puma')
        end

        it { is_expected.to eq 'puma_master' }
      end
    end

    context 'when running in unknown mode' do
      before do
        hide_const('Puma')
        hide_const('Unicorn::Worker')
      end

      it { is_expected.to eq "process_#{Process.pid}" }
    end
  end
end
