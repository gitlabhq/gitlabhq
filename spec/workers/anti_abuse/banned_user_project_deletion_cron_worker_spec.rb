# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::BannedUserProjectDeletionCronWorker, feature_category: :instance_resiliency do
  let_it_be_with_reload(:user) { create(:user, :banned) }
  let_it_be_with_reload(:user_without_projects) { create(:user, :banned) }
  let_it_be(:project) { create(:project, creator: user, owners: user) }
  let_it_be(:project2) { create(:project, creator: user, maintainers: user) }
  let_it_be(:project3) { create(:project, owners: user) }
  let(:worker) { described_class.new }

  def perform(time_travel: true)
    return worker.perform unless time_travel

    travel_to described_class::BANNED_USER_CREATED_AT_THRESHOLD.days.from_now do
      worker.perform
    end
  end

  describe '#perform' do
    it_behaves_like 'an idempotent worker'

    it 'schedules deletion for projects of banned users who are project owners and creators' do
      expect(AntiAbuse::BannedUserProjectDeletionWorker).to receive(:perform_in).once.with(0, project.id)

      perform
    end

    it 'marks banned users as having their projects deleted', :aggregate_failures do
      perform

      expect(user.banned_user.projects_deleted).to be true
      expect(user_without_projects.banned_user.projects_deleted).to be true
    end

    it 'respects the PROJECT_DELETION_LIMIT', :aggregate_failures do
      stub_const("#{described_class}::PROJECT_DELETION_LIMIT", 1)
      create(:project, creator: user, owners: user)

      expect(AntiAbuse::BannedUserProjectDeletionWorker).to receive(:perform_in).once

      perform

      # Loop was broken before we could determine if all projects were deleted
      expect(user.banned_user.projects_deleted).to be false
      expect(user_without_projects.banned_user.projects_deleted).to be false
    end

    it 'times out if past the deadline', :aggregate_failures do
      worker.instance_variable_set(:@start_time, ::Gitlab::Metrics::System.monotonic_time - 5.minutes)
      expect(AntiAbuse::BannedUserProjectDeletionWorker).not_to receive(:perform_in)

      perform
    end

    it 'logs project deletion events' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          class: described_class.name,
          message: "Banned user project scheduled for deletion",
          project_id: project.id,
          full_path: project.full_path,
          banned_user_id: user.id
        )
      )

      perform
    end

    it 'does not delete projects for users who have been banned before the deletion threshold' do
      expect(AntiAbuse::BannedUserProjectDeletionWorker).not_to receive(:perform_in)

      perform(time_travel: false)
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(delete_banned_user_projects: false)
      end

      it 'does not schedule any deletions' do
        expect(AntiAbuse::BannedUserProjectDeletionWorker).not_to receive(:perform_in)

        perform
      end
    end
  end
end
