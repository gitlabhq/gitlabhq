# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::QueryLimiting::SidekiqMiddleware, feature_category: :database do
  describe '#call' do
    let(:worker_class) do
      Class.new do
        def self.name
          'TestWorker'
        end

        include ApplicationWorker
      end
    end

    let(:worker) { worker_class.new }
    let(:job) { {} }
    let(:queue) { :test }

    it 'runs the middleware with query limiting in place' do
      expect_next_instance_of(Gitlab::QueryLimiting::Transaction) do |instance|
        expect(instance).to receive(:action=).with('TestWorker')
        expect(instance).to receive(:act_upon_results)
      end

      middleware = described_class.new

      middleware.call(worker, job, queue) { nil }
    end

    it 'yields block' do
      middleware = described_class.new

      expect { |b| middleware.call(worker, job, queue, &b) }.to yield_control.once
    end

    it 'returns value of block' do
      middleware = described_class.new

      return_value = middleware.call(worker, job, queue) do
        { value: 11 }
      end

      expect(return_value).to eq({ value: 11 })
    end
  end
end
