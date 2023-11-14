# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinks::UpdateService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:user) { create :user }
  let_it_be(:group) { create :group }
  let_it_be(:project) { create :project }
  let_it_be(:group_user) { create(:user).tap { |user| group.add_developer(user) } }

  let(:group_access) { Gitlab::Access::DEVELOPER }

  let!(:link) { create(:project_group_link, project: project, group: group, group_access: group_access) }

  let(:expiry_date) { 1.month.from_now.to_date }
  let(:group_link_params) do
    { group_access: Gitlab::Access::GUEST,
      expires_at: expiry_date }
  end

  subject { described_class.new(link, user).execute(group_link_params) }

  shared_examples_for 'returns not_found' do
    it do
      result = subject

      expect(result[:status]).to eq(:error)
      expect(result[:reason]).to eq(:not_found)
    end
  end

  context 'when the user does not have proper permissions to update a project group link' do
    it_behaves_like 'returns not_found'
  end

  context 'when user has proper permissions to update a project group link' do
    context 'when the user is a MAINTAINER in the project' do
      before do
        project.add_maintainer(user)
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
        it 'calls AuthorizedProjectUpdate::ProjectRecalculateWorker to update project authorizations' do
          expect(AuthorizedProjectUpdate::ProjectRecalculateWorker)
            .to receive(:perform_async).with(link.project.id)

          subject
        end

        it 'calls AuthorizedProjectUpdate::UserRefreshFromReplicaWorker ' \
           'with a delay to update project authorizations' do
          stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)

          expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
            receive(:bulk_perform_in).with(
              1.hour,
              [[group_user.id]],
              batch_delay: 30.seconds, batch_size: 100
            )
          )

          subject
        end

        it 'updates project authorizations of users who had access to the project via the group share',
          :sidekiq_inline do
          expect { subject }.to(
            change { Ability.allowed?(group_user, :developer_access, project) }
              .from(true).to(false))
        end
      end

      context 'with only param not requiring authorization refresh' do
        let(:group_link_params) { { expires_at: Date.tomorrow } }

        it 'does not perform any project authorizations update using ' \
           '`AuthorizedProjectUpdate::ProjectRecalculateWorker`' do
          expect(AuthorizedProjectUpdate::ProjectRecalculateWorker).not_to receive(:perform_async)

          subject
        end
      end
    end
  end
end
