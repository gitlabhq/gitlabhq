# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Runtime do
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
    let(:options) do
      {
        max_threads: 2
      }
    end

    before do
      stub_const('::Puma', puma_type)
      allow(puma_type).to receive_message_chain(:cli_config, :options).and_return(options)
    end

    it "identifies itself" do
      expect(subject.identify).to eq(:puma)
      expect(subject.puma?).to be(true)
    end

    it "does not identify as others" do
      expect(subject.unicorn?).to be(false)
      expect(subject.sidekiq?).to be(false)
      expect(subject.console?).to be(false)
      expect(subject.rake?).to be(false)
      expect(subject.test_suite?).to be(false)
    end

    it "reports its maximum concurrency" do
      expect(subject.max_threads).to eq(2)
    end
  end

  context "unicorn" do
    let(:unicorn_type) { Module.new }
    let(:unicorn_server_type) { Class.new }

    before do
      stub_const('::Unicorn', unicorn_type)
      stub_const('::Unicorn::HttpServer', unicorn_server_type)
    end

    it "identifies itself" do
      expect(subject.identify).to eq(:unicorn)
      expect(subject.unicorn?).to be(true)
    end

    it "does not identify as others" do
      expect(subject.puma?).to be(false)
      expect(subject.sidekiq?).to be(false)
      expect(subject.console?).to be(false)
      expect(subject.rake?).to be(false)
      expect(subject.test_suite?).to be(false)
    end

    it "reports its maximum concurrency" do
      expect(subject.max_threads).to eq(1)
    end
  end

  context "sidekiq" do
    let(:sidekiq_type) { double('::Sidekiq') }
    let(:options) do
      {
        concurrency: 2
      }
    end

    before do
      stub_const('::Sidekiq', sidekiq_type)
      allow(sidekiq_type).to receive(:server?).and_return(true)
      allow(sidekiq_type).to receive(:options).and_return(options)
    end

    it "identifies itself" do
      expect(subject.identify).to eq(:sidekiq)
      expect(subject.sidekiq?).to be(true)
    end

    it "does not identify as others" do
      expect(subject.unicorn?).to be(false)
      expect(subject.puma?).to be(false)
      expect(subject.console?).to be(false)
      expect(subject.rake?).to be(false)
      expect(subject.test_suite?).to be(false)
    end

    it "reports its maximum concurrency" do
      expect(subject.max_threads).to eq(2)
    end
  end

  context "console" do
    let(:console_type) { double('::Rails::Console') }

    before do
      stub_const('::Rails::Console', console_type)
    end

    it "identifies itself" do
      expect(subject.identify).to eq(:console)
      expect(subject.console?).to be(true)
    end

    it "does not identify as others" do
      expect(subject.unicorn?).to be(false)
      expect(subject.sidekiq?).to be(false)
      expect(subject.puma?).to be(false)
      expect(subject.rake?).to be(false)
      expect(subject.test_suite?).to be(false)
    end

    it "reports its maximum concurrency" do
      expect(subject.max_threads).to eq(1)
    end
  end

  context "test suite" do
    before do
      stub_rails_env('test')
    end

    it "identifies itself" do
      expect(subject.identify).to eq(:test_suite)
      expect(subject.test_suite?).to be(true)
    end

    it "does not identify as others" do
      expect(subject.unicorn?).to be(false)
      expect(subject.sidekiq?).to be(false)
      expect(subject.rake?).to be(false)
      expect(subject.puma?).to be(false)
    end

    it "reports its maximum concurrency" do
      expect(subject.max_threads).to eq(1)
    end
  end
end
