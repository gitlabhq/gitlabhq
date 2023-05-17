# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinks::CreateService, '#execute', feature_category: :subgroups do
  let_it_be(:user) { create :user }
  let_it_be(:group) { create :group }
  let_it_be(:project) { create(:project, namespace: create(:namespace, :with_namespace_settings)) }

  let(:opts) do
    {
      link_group_access: Gitlab::Access::DEVELOPER,
      expires_at: nil
    }
  end

  subject { described_class.new(project, group, user, opts) }

  shared_examples_for 'not shareable' do
    it 'does not share and returns an error' do
      expect do
        result = subject.execute

        expect(result[:status]).to eq(:error)
        expect(result[:http_status]).to eq(404)
      end.not_to change { project.project_group_links.count }
    end
  end

  shared_examples_for 'shareable' do
    it 'adds group to project' do
      expect do
        result = subject.execute

        expect(result[:status]).to eq(:success)
      end.to change { project.project_group_links.count }.from(0).to(1)
    end
  end

  context 'when user has proper membership to share a group' do
    before do
      group.add_guest(user)
    end

    it_behaves_like 'shareable'

    it 'updates authorization', :sidekiq_inline do
      expect { subject.execute }.to(
        change { Ability.allowed?(user, :read_project, project) }
          .from(false).to(true))
    end

    context 'with specialized project_authorization workers' do
      let_it_be(:other_user) { create(:user) }

      before do
        group.add_developer(other_user)
      end

      it 'schedules authorization update for users with access to group' do
        stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)

        expect(AuthorizedProjectsWorker).not_to(
          receive(:bulk_perform_async)
        )
        expect(AuthorizedProjectUpdate::ProjectRecalculateWorker).to(
          receive(:perform_async)
            .with(project.id)
            .and_call_original
        )
        expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
          receive(:bulk_perform_in).with(
            1.hour,
            array_including([user.id], [other_user.id]),
            batch_delay: 30.seconds, batch_size: 100
          ).and_call_original
        )

        subject.execute
      end
    end

    context 'when sharing outside the hierarchy is disabled' do
      let_it_be(:shared_group_parent) do
        create(:group, namespace_settings: create(:namespace_settings, prevent_sharing_groups_outside_hierarchy: true))
      end

      let_it_be(:project, reload: true) { create(:project, group: shared_group_parent) }

      it_behaves_like 'not shareable'

      context 'when group is inside hierarchy' do
        let(:group) { create(:group, :private, parent: shared_group_parent) }

        it_behaves_like 'shareable'
      end
    end
  end

  context 'when user does not have permissions for the group' do
    it_behaves_like 'not shareable'
  end

  context 'when group is blank' do
    let(:group) { nil }

    it_behaves_like 'not shareable'
  end
end
