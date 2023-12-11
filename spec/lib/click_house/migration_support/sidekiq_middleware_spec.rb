# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::MigrationSupport::SidekiqMiddleware, feature_category: :database do
  let(:worker_with_click_house_worker) do
    Class.new do
      def self.name
        'TestWorker'
      end
      include ApplicationWorker
      include ClickHouseWorker
    end
  end

  let(:worker_without_click_house_worker) do
    Class.new do
      def self.name
        'TestWorkerWithoutClickHouseWorker'
      end
      include ApplicationWorker
    end
  end

  subject(:middleware) { described_class.new }

  before do
    stub_const('TestWorker', worker_with_click_house_worker)
    stub_const('TestWorkerWithoutClickHouseWorker', worker_without_click_house_worker)
  end

  describe '#call' do
    let(:worker) { worker_class.new }
    let(:job) { { 'jid' => 123, 'class' => worker_class.name } }
    let(:queue) { 'test_queue' }

    context 'when worker does not include ClickHouseWorker' do
      let(:worker_class) { worker_without_click_house_worker }

      it 'yields control without registering running worker' do
        expect(ClickHouse::MigrationSupport::ExclusiveLock).not_to receive(:register_running_worker)
        expect { |b| middleware.call(worker, job, queue, &b) }.to yield_with_no_args
      end
    end

    context 'when worker includes ClickHouseWorker' do
      let(:worker_class) { worker_with_click_house_worker }

      it 'registers running worker and yields control' do
        expect(ClickHouse::MigrationSupport::ExclusiveLock)
          .to receive(:register_running_worker)
          .with(worker_class, 'test_queue:123')
          .and_wrap_original do |method, worker_class, worker_id|
          expect { |b| method.call(worker_class, worker_id, &b) }.to yield_with_no_args
        end

        middleware.call(worker, job, queue)
      end
    end
  end
end
