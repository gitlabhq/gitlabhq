# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::BannedUserProjectDeletionWorker, feature_category: :instance_resiliency do
  let(:worker) { described_class.new }
  let(:admin_bot) { Users::Internal.admin_bot }
  let_it_be_with_reload(:user) { create(:user, :banned) }
  let_it_be_with_reload(:project) { create(:project, creator: user, owners: user) }
  let(:project_id) { project.id }

  # The factory adds two owners so we need to make sure they are all banned
  before_all do
    project.owners.each { |o| o.ban! if o.active? }
  end

  describe '#perform' do
    subject(:perform) { worker.perform(project_id) }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { project_id }
    end

    shared_examples 'does not destroy the project' do
      specify do
        expect(Projects::DestroyService).not_to receive(:new)

        perform
      end
    end

    shared_examples 'logs the event' do |reason|
      specify do
        expect(Gitlab::AppLogger).to receive(:info).with(
          class: described_class.name,
          message: 'aborted banned user project auto-deletion',
          reason: reason,
          project_id: project.id,
          full_path: project.full_path,
          banned_user_id: project.creator_id
        )

        perform
      end
    end

    context 'when the project is not active', time_travel_to: (described_class::ACTIVITY_THRESHOLD + 1).days.from_now do
      it 'calls Projects::DestroyService' do
        expect_next_instance_of(Projects::DestroyService, project, admin_bot) do |service|
          expect(service).to receive(:async_execute)
        end

        worker.perform(project_id)
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(delete_banned_user_projects: false)
        end

        it_behaves_like 'does not destroy the project'
      end

      context 'when the project does not exist' do
        let(:project_id) { non_existing_record_id }

        it_behaves_like 'does not destroy the project'
      end

      context 'when the project is pending deletion' do
        before do
          project.update!(pending_delete: true)
        end

        it_behaves_like 'does not destroy the project'
      end

      context 'when the project creator is not banned' do
        before do
          user.unban!
        end

        it_behaves_like 'does not destroy the project'
        it_behaves_like 'logs the event', 'user status change'
      end

      context 'when the project creator is not an owner' do
        before_all do
          project.add_maintainer(user)
        end

        it_behaves_like 'does not destroy the project'
        it_behaves_like 'logs the event', 'user status change'
      end

      context 'when the project has another owner that is active' do
        before_all do
          project.add_owner(create(:user))
        end

        it_behaves_like 'does not destroy the project'
        it_behaves_like 'logs the event', 'project is co-owned by other active users'
      end
    end

    context 'when the project is active' do
      it_behaves_like 'does not destroy the project'
      it_behaves_like 'logs the event', 'active project'
    end
  end
end
