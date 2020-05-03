# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Runtime do
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
    stub_rails_env('production')
  end

  context "when unknown" do
    it "raises an exception when trying to identify" do
      expect { subject.identify }.to raise_error(subject::UnknownProcessError)
    end
  end

  context "on multiple matches" do
    before do
      stub_const('::Puma', double)
      stub_const('::Rails::Console', double)
    end

    it "raises an exception when trying to identify" do
      expect { subject.identify }.to raise_error(subject::AmbiguousProcessError)
    end
  end

  context "puma" do
    let(:puma_type) { double('::Puma') }

    before do
      stub_const('::Puma', puma_type)
      allow(puma_type).to receive_message_chain(:cli_config, :options).and_return(max_threads: 2)
    end

    it_behaves_like "valid runtime", :puma, 3
  end

  context "unicorn" do
    before do
      stub_const('::Unicorn', Module.new)
      stub_const('::Unicorn::HttpServer', Class.new)
    end

    it_behaves_like "valid runtime", :unicorn, 1
  end

  context "sidekiq" do
    let(:sidekiq_type) { double('::Sidekiq') }

    before do
      stub_const('::Sidekiq', sidekiq_type)
      allow(sidekiq_type).to receive(:server?).and_return(true)
      allow(sidekiq_type).to receive(:options).and_return(concurrency: 2)
    end

    it_behaves_like "valid runtime", :sidekiq, 4
  end

  context "console" do
    before do
      stub_const('::Rails::Console', double('::Rails::Console'))
    end

    it_behaves_like "valid runtime", :console, 1
  end

  context "test suite" do
    before do
      stub_rails_env('test')
    end

    it_behaves_like "valid runtime", :test_suite, 1
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
  end

  context "action_cable" do
    before do
      stub_const('ACTION_CABLE_SERVER', true)
      stub_const('::Puma', Module.new)

      allow(Gitlab::Application).to receive_message_chain(:config, :action_cable, :worker_pool_size).and_return(8)
    end

    it "reports its maximum concurrency based on ActionCable's worker pool size" do
      expect(subject.max_threads).to eq(9)
    end
  end
end
