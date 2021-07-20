# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinks::UpdateService, '#execute' do
  let_it_be(:user) { create :user }
  let_it_be(:group) { create :group }
  let_it_be(:project) { create :project }

  let!(:link) { create(:project_group_link, project: project, group: group) }

  let(:expiry_date) { 1.month.from_now.to_date }
  let(:group_link_params) do
    { group_access: Gitlab::Access::GUEST,
      expires_at: expiry_date }
  end

  subject { described_class.new(link).execute(group_link_params) }

  before do
    group.add_developer(user)
  end

  it 'updates existing link' do
    expect(link.group_access).to eq(Gitlab::Access::DEVELOPER)
    expect(link.expires_at).to be_nil

    subject

    link.reload

    expect(link.group_access).to eq(Gitlab::Access::GUEST)
    expect(link.expires_at).to eq(expiry_date)
  end

  context 'project authorizations update' do
    context 'when the feature flag `specialized_worker_for_project_share_update_auth_recalculation` is enabled' do
      before do
        stub_feature_flags(specialized_worker_for_project_share_update_auth_recalculation: true)
      end

      it 'calls AuthorizedProjectUpdate::ProjectRecalculateWorker to update project authorizations' do
        expect(AuthorizedProjectUpdate::ProjectRecalculateWorker)
          .to receive(:perform_async).with(link.project.id)

        subject
      end

      it 'calls AuthorizedProjectUpdate::UserRefreshFromReplicaWorker with a delay to update project authorizations' do
        expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
          receive(:bulk_perform_in)
            .with(1.hour,
                  [[user.id]],
                  batch_delay: 30.seconds, batch_size: 100)
        )

        subject
      end

      it 'updates project authorizations of users who had access to the project via the group share', :sidekiq_inline do
        group.add_maintainer(user)

        expect { subject }.to(
          change { Ability.allowed?(user, :create_release, project) }
            .from(true).to(false))
      end
    end

    context 'when the feature flag `specialized_worker_for_project_share_update_auth_recalculation` is disabled' do
      before do
        stub_feature_flags(specialized_worker_for_project_share_update_auth_recalculation: false)
      end

      it 'calls UserProjectAccessChangedService to update project authorizations' do
        expect_next_instance_of(UserProjectAccessChangedService, [user.id]) do |service|
          expect(service).to receive(:execute)
        end

        subject
      end

      it 'updates project authorizations of users who had access to the project via the group share' do
        group.add_maintainer(user)

        expect { subject }.to(
          change { Ability.allowed?(user, :create_release, project) }
            .from(true).to(false))
      end
    end
  end

  context 'with only param not requiring authorization refresh' do
    let(:group_link_params) { { expires_at: Date.tomorrow } }

    context 'when the feature flag `specialized_worker_for_project_share_update_auth_recalculation` is enabled' do
      before do
        stub_feature_flags(specialized_worker_for_project_share_update_auth_recalculation: true)
      end

      it 'does not perform any project authorizations update using `AuthorizedProjectUpdate::ProjectRecalculateWorker`' do
        expect(AuthorizedProjectUpdate::ProjectRecalculateWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'when the feature flag `specialized_worker_for_project_share_update_auth_recalculation` is disabled' do
      before do
        stub_feature_flags(specialized_worker_for_project_share_update_auth_recalculation: false)
      end

      it 'does not perform any project authorizations update using `UserProjectAccessChangedService`' do
        expect(UserProjectAccessChangedService).not_to receive(:new)

        subject
      end
    end
  end
end
