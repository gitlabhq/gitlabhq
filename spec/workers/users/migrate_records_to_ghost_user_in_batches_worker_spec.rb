# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::MigrateRecordsToGhostUserInBatchesWorker, feature_category: :seat_cost_management do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }

  describe '#perform', :clean_gitlab_redis_shared_state do
    it 'executes service with lease' do
      lease_key = described_class.name.underscore

      expect_to_obtain_exclusive_lease(lease_key, 'uuid')
      expect_next_instance_of(Users::MigrateRecordsToGhostUserInBatchesService) do |service|
        expect(service).to receive(:execute).and_return(true)
      end

      worker.perform
    end
  end

  it_behaves_like 'an idempotent worker' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, namespace: create(:group)) }

    let_it_be(:issue) do
      create(:issue, project: project, author: user, last_edited_by: user, last_edited_at: Time.current)
    end

    subject { worker.perform }

    before do
      create(:ghost_user_migration, user: user, initiator_user: user)
    end

    it 'migrates issue to ghost user' do
      subject

      expect(issue.reload.author).to eq(Users::Internal.ghost)
      expect(issue.last_edited_by).to eq(Users::Internal.ghost)
    end
  end
end
