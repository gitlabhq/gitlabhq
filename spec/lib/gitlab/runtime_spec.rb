# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Runtime do
  REAL_PATH = $0

  after(:all) do
    $0 = REAL_PATH
  end

  context "when unknown" do
    it "identifies as :unknown" do
      expect(subject.name).to eq(:unknown)
    end
  end

  context "on multiple matches" do
    before do
      $0 = '/data/cache/bundle-2.5/bin/puma'
      stub_const('::Puma', double)
      stub_const('::Rails::Console', double)
    end

    it "raises an exception when trying to identify" do
      expect { subject.name }.to raise_error(RuntimeError, "Ambiguous process match: [:puma, :console]")
    end
  end

  context "puma" do
    let(:puma_type) { double('::Puma') }

    before do
      $0 = '/data/cache/bundle-2.5/bin/puma'
      stub_const('::Puma', puma_type)
    end

    it "identifies itself" do
      expect(subject.name).to eq(:puma)
      expect(subject.puma?).to be(true)
    end

    it "does not identify as others" do
      expect(subject.unicorn?).to be(false)
      expect(subject.sidekiq?).to be(false)
      expect(subject.console?).to be(false)
    end
  end

  context "unicorn" do
    let(:unicorn_type) { Module.new }
    let(:unicorn_server_type) { Class.new }

    before do
      $0 = 'unicorn_rails master -E development -c /tmp/unicorn.rb -l 0.0.0.0:8080'
      stub_const('::Unicorn', unicorn_type)
      stub_const('::Unicorn::HttpServer', unicorn_server_type)
    end

    it "identifies itself" do
      expect(subject.name).to eq(:unicorn)
      expect(subject.unicorn?).to be(true)
    end

    it "does not identify as others" do
      expect(subject.puma?).to be(false)
      expect(subject.sidekiq?).to be(false)
      expect(subject.console?).to be(false)
    end
  end

  context "sidekiq" do
    let(:sidekiq_type) { double('::Sidekiq') }

    before do
      $0 = '/data/cache/bundle-2.5/bin/sidekiq'
      stub_const('::Sidekiq', sidekiq_type)
      allow(sidekiq_type).to receive(:server?).and_return(true)
    end

    it "identifies itself" do
      expect(subject.name).to eq(:sidekiq)
      expect(subject.sidekiq?).to be(true)
    end

    it "does not identify as others" do
      expect(subject.unicorn?).to be(false)
      expect(subject.puma?).to be(false)
      expect(subject.console?).to be(false)
    end
  end

  context "console" do
    let(:console_type) { double('::Rails::Console') }

    before do
      $0 = 'bin/rails'
      stub_const('::Rails::Console', console_type)
    end

    it "identifies itself" do
      expect(subject.name).to eq(:console)
      expect(subject.console?).to be(true)
    end

    it "does not identify as others" do
      expect(subject.unicorn?).to be(false)
      expect(subject.sidekiq?).to be(false)
      expect(subject.puma?).to be(false)
    end
  end
end
