# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::MigrateHumanRecordsToGhostUserInBatchesWorker, feature_category: :user_profile do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }

  describe '#perform', :clean_gitlab_redis_shared_state do
    it 'executes service with lease' do
      lease_key = described_class.name.underscore

      expect_to_obtain_exclusive_lease(lease_key, 'uuid')
      expect_next_instance_of(Users::MigrateUserTypeRecordsToGhostUserInBatchesService, user_type: :human) do |service|
        expect(service).to receive(:execute).and_return(true)
      end

      worker.perform
    end

    context 'when split_ghost_user_migration_queue_into_human_and_non_human FF is disabled' do
      before do
        stub_feature_flags(split_ghost_user_migration_queue_into_human_and_non_human: false)
      end

      it 'is no-op' do
        expect(Users::MigrateUserTypeRecordsToGhostUserInBatchesService).not_to receive(:new)

        worker.perform
      end
    end
  end

  it_behaves_like 'an idempotent worker' do
    let_it_be(:user, freeze: false) { create(:user) }
    let_it_be(:project, freeze: false) { create(:project, namespace: create(:group)) }
    let_it_be(:ghost_user, freeze: false) { Users::Internal.in_organization(project.organization).ghost }

    let_it_be(:issue, freeze: false) do
      create(:issue, project: project, author: user, last_edited_by: user, last_edited_at: Time.current)
    end

    before do
      create(:ghost_user_migration, user: user, initiator_user: user)
    end

    it 'migrates issue to ghost user' do
      worker.perform

      expect(issue.reload.author).to eq(ghost_user)
      expect(issue.last_edited_by).to eq(ghost_user)
    end
  end
end
