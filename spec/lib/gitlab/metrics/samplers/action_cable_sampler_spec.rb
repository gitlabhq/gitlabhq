# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::ActionCableSampler do
  let(:action_cable) { instance_double(ActionCable::Server::Base) }

  subject { described_class.new(action_cable: action_cable, logger: double) }

  it_behaves_like 'metrics sampler', 'ACTION_CABLE_SAMPLER'

  describe '#sample' do
    let(:pool) { instance_double(Concurrent::ThreadPoolExecutor) }

    before do
      allow(action_cable).to receive_message_chain(:worker_pool, :executor).and_return(pool)
      allow(action_cable).to receive(:connections).and_return([])
      allow(pool).to receive(:min_length).and_return(1)
      allow(pool).to receive(:max_length).and_return(2)
      allow(pool).to receive(:length).and_return(3)
      allow(pool).to receive(:largest_length).and_return(4)
      allow(pool).to receive(:completed_task_count).and_return(5)
      allow(pool).to receive(:queue_length).and_return(6)
    end

    it 'includes active connections' do
      expect(subject.metrics[:active_connections]).to receive(:set).with({}, 0)

      subject.sample
    end

    it 'includes minimum worker pool size' do
      expect(subject.metrics[:pool_min_size]).to receive(:set).with({}, 1)

      subject.sample
    end

    it 'includes maximum worker pool size' do
      expect(subject.metrics[:pool_max_size]).to receive(:set).with({}, 2)

      subject.sample
    end

    it 'includes current worker pool size' do
      expect(subject.metrics[:pool_current_size]).to receive(:set).with({}, 3)

      subject.sample
    end

    it 'includes largest worker pool size' do
      expect(subject.metrics[:pool_largest_size]).to receive(:set).with({}, 4)

      subject.sample
    end

    it 'includes worker pool completed task count' do
      expect(subject.metrics[:pool_completed_tasks]).to receive(:set).with({}, 5)

      subject.sample
    end

    it 'includes worker pool pending task count' do
      expect(subject.metrics[:pool_pending_tasks]).to receive(:set).with({}, 6)

      subject.sample
    end
  end
end
