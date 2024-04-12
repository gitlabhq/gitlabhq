# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::AutoStopService, :clean_gitlab_redis_shared_state, :sidekiq_inline,
  feature_category: :continuous_delivery do
  include CreateEnvironmentsHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, developer_of: project) }

  let(:service) { described_class.new }

  describe '#execute' do
    subject { service.execute }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }

    let(:environments) { Environment.all }

    before_all do
      project.add_developer(user)
      project.repository.add_branch(user, 'review/feature-1', 'master')
      project.repository.add_branch(user, 'review/feature-2', 'master')
    end

    before do
      create_review_app(user, project, 'review/feature-1')
      create_review_app(user, project, 'review/feature-2')
    end

    it 'stops environments and play stop jobs' do
      expect { subject }
        .to change { Environment.all.map(&:state).uniq }
        .from(['available']).to(['stopping'])

      expect(Ci::Build.where(name: 'stop_review_app').map(&:status).uniq).to eq(['pending'])
    end

    it 'schedules stop processes in bulk' do
      args = [[Environment.find_by_name('review/feature-1').id], [Environment.find_by_name('review/feature-2').id]]

      expect(Environments::AutoStopWorker)
        .to receive(:bulk_perform_async).with(args).once.and_call_original

      subject
    end

    context 'when the other sidekiq worker has already been running' do
      before do
        stub_exclusive_lease_taken(described_class::EXCLUSIVE_LOCK_KEY)
      end

      it 'does not execute stop_in_batch' do
        expect_next_instance_of(described_class) do |service|
          expect(service).not_to receive(:stop_in_batch)
        end

        expect { subject }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
      end
    end

    context 'when loop reached timeout' do
      before do
        stub_const("#{described_class}::LOOP_TIMEOUT", 0.seconds)
        stub_const("#{described_class}::LOOP_LIMIT", 100_000)
        allow_next_instance_of(described_class) do |service|
          allow(service).to receive(:stop_in_batch) { true }
        end
      end

      it 'returns false and does not continue the process' do
        is_expected.to eq(false)
      end
    end

    context 'when loop reached loop limit' do
      before do
        stub_const("#{described_class}::LOOP_LIMIT", 1)
        stub_const("#{described_class}::BATCH_SIZE", 1)
      end

      it 'stops only one available environment' do
        expect { subject }.to change { Environment.available.count }.by(-1)
      end
    end
  end
end
