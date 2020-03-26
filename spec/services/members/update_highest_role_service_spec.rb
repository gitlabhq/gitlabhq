# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe Members::UpdateHighestRoleService, :clean_gitlab_redis_shared_state do
  include ExclusiveLeaseHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:lease_key) { "update_highest_role:#{user.id}" }
  let(:service) { described_class.new(user.id) }

  describe '#perform' do
    subject { service.execute }

    context 'when lease is obtained' do
      it 'takes the lease but does not release it', :aggregate_failures do
        expect_to_obtain_exclusive_lease(lease_key, 'uuid', timeout: described_class::LEASE_TIMEOUT)

        subject

        expect(service.exclusive_lease.exists?).to be_truthy
      end

      it 'schedules a job' do
        Sidekiq::Testing.fake! do
          expect { subject }.to change(UpdateHighestRoleWorker.jobs, :size).by(1)
        end
      end
    end

    context 'when lease cannot be obtained' do
      it 'only schedules one job' do
        Sidekiq::Testing.fake! do
          stub_exclusive_lease_taken(lease_key, timeout: described_class::LEASE_TIMEOUT)

          expect { subject }.not_to change(UpdateHighestRoleWorker.jobs, :size)
        end
      end
    end
  end
end
