# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Runtime, feature_category: :cloud_connector do
  shared_examples "valid runtime" do |runtime, max_threads|
    it "identifies itself" do
      expect(subject.identify).to eq(runtime)
      expect(subject.public_send("#{runtime}?")).to be(true)
    end

    it "does not identify as others" do
      (described_class::AVAILABLE_RUNTIMES - [runtime]).each do |runtime|
        expect(subject.public_send("#{runtime}?")).to eq(false)
      end
    end

    it "reports its maximum concurrency" do
      expect(subject.max_threads).to eq(max_threads)
    end
  end

  before do
    allow(described_class).to receive(:process_name).and_return('ruby')
    hide_const('::Puma::Server')
    stub_rails_env('production')
  end

  context "when unknown" do
    describe '.identify' do
      it "raises an exception when trying to identify" do
        expect { subject.identify }.to raise_error(subject::UnknownProcessError)
      end
    end

    describe '.safe_identify' do
      it "returns nil" do
        expect(subject.safe_identify).to be_nil
      end
    end
  end

  context 'with Puma' do
    before do
      stub_const('::Puma::Server', double)
    end

    describe '.puma?' do
      it 'returns true' do
        expect(subject.puma?).to be true
      end
    end
  end

  context "on multiple matches" do
    before do
      stub_const('::Puma::Server', double)
      stub_const('::Rails::Console', double)
    end

    describe '.identify' do
      it "raises an exception when trying to identify" do
        expect { subject.identify }.to raise_error(subject::AmbiguousProcessError)
      end
    end

    describe '.safe_identify' do
      it "returns nil" do
        expect(subject.safe_identify).to be_nil
      end
    end
  end

  # Puma has no cli_config method unless `puma/cli` is required
  context "puma without cli_config" do
    let(:puma_type) { double('::Puma') }

    before do
      stub_const('::Puma', puma_type)
      allow(described_class).to receive(:puma?).and_return(true)
    end

    it_behaves_like "valid runtime", :puma, 1 + Gitlab::ActionCable::Config.worker_pool_size
  end

  context "puma with cli_config" do
    let(:puma_type) { double('::Puma') }
    let(:max_workers) { 2 }

    before do
      stub_const('::Puma', puma_type)
      allow(described_class).to receive(:puma?).and_return(true)
      allow(puma_type).to receive_message_chain(:cli_config, :options).and_return(max_threads: 2, workers: max_workers)
    end

    it_behaves_like "valid runtime", :puma, 3 + Gitlab::ActionCable::Config.worker_pool_size

    it 'identifies as an application runtime' do
      expect(described_class.application?).to be true
    end

    context "when ActionCable worker pool size is configured" do
      before do
        stub_env('ACTION_CABLE_WORKER_POOL_SIZE', 10)
      end

      it_behaves_like "valid runtime", :puma, 13
    end

    describe ".puma_in_clustered_mode?" do
      context 'when Puma is set up with workers > 0' do
        let(:max_workers) { 4 }

        specify { expect(described_class.puma_in_clustered_mode?).to be true }
      end

      context 'when Puma is set up with workers = 0' do
        let(:max_workers) { 0 }

        specify { expect(described_class.puma_in_clustered_mode?).to be false }
      end
    end
  end

  context "sidekiq" do
    let(:sidekiq_type) { double('::Sidekiq') }

    before do
      stub_const('::Sidekiq', sidekiq_type)
      allow(sidekiq_type).to receive(:server?).and_return(true)
      allow(sidekiq_type).to receive(:default_configuration).and_return({ concurrency: 2 })
    end

    it_behaves_like "valid runtime", :sidekiq, 2

    it 'identifies as an application runtime' do
      expect(described_class.application?).to be true
    end
  end

  context "console" do
    before do
      stub_const('::Rails::Console', double('::Rails::Console'))
    end

    it_behaves_like "valid runtime", :console, 1

    it 'does not identify as an application runtime' do
      expect(described_class.application?).to be false
    end
  end

  context "test suite" do
    before do
      stub_rails_env('test')
    end

    it_behaves_like "valid runtime", :test_suite, 1

    it 'does not identify as an application runtime' do
      expect(described_class.application?).to be false
    end
  end

  context "geo log cursor" do
    before do
      stub_const('::GeoLogCursorOptionParser', double('::GeoLogCursorOptionParser'))
    end

    it_behaves_like "valid runtime", :geo_log_cursor, 1
  end

  context "rails runner" do
    before do
      stub_const('::Rails::Command::RunnerCommand', double('::Rails::Command::RunnerCommand'))
    end

    it_behaves_like "valid runtime", :rails_runner, 1

    it 'does not identify as an application runtime' do
      expect(described_class.application?).to be false
    end
  end
end
