# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::WorkerContext::Server do
  let(:worker_class) do
    Class.new do
      def self.name
        "TestWorker"
      end

      # To keep track of the context that was active for certain arguments
      cattr_accessor(:contexts) { {} }

      include ApplicationWorker

      feature_category :foo
      worker_context user: nil

      def perform(identifier, *args)
        self.class.contexts.merge!(identifier => Gitlab::ApplicationContext.current)
      end
    end
  end

  let(:other_worker) do
    Class.new do
      def self.name
        "OtherWorker"
      end

      include Sidekiq::Worker

      def perform
      end
    end
  end

  before do
    stub_const("TestWorker", worker_class)
    stub_const("OtherWorker", other_worker)
  end

  around do |example|
    with_sidekiq_server_middleware do |chain|
      chain.add described_class
      Sidekiq::Testing.inline! { example.run }
    end
  end

  describe "#call" do
    it 'applies a class context' do
      Gitlab::ApplicationContext.with_context(user: build_stubbed(:user)) do
        TestWorker.perform_async("identifier", 1)
      end

      expect(TestWorker.contexts['identifier'].keys).not_to include('meta.user')
    end

    it 'takes the feature category from the worker' do
      TestWorker.perform_async('identifier', 1)

      expect(TestWorker.contexts['identifier']).to include('meta.feature_category' => 'foo')
    end

    it "doesn't fail for unknown workers" do
      expect { OtherWorker.perform_async }.not_to raise_error
    end
  end
end
