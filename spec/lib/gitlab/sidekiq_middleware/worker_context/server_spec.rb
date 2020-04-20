# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqMiddleware::WorkerContext::Server do
  let(:worker_class) do
    Class.new do
      def self.name
        "TestWorker"
      end

      # To keep track of the context that was active for certain arguments
      cattr_accessor(:contexts) { {} }

      include ApplicationWorker

      worker_context user: nil

      def perform(identifier, *args)
        self.class.contexts.merge!(identifier => Labkit::Context.current.to_h)
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

    it "doesn't fail for unknown workers" do
      expect { OtherWorker.perform_async }.not_to raise_error
    end
  end
end
