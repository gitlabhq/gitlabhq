# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupLinks::UpdateService, '#execute', feature_category: :groups_and_projects do
  let(:user) { create(:user) }

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:shared_group) { create(:group, :private) }
  let_it_be(:project) { create(:project, group: shared_group) }

  let(:group_member_user) { create(:user) }
  let!(:link) { create(:group_group_link, shared_group: shared_group, shared_with_group: group) }

  let(:expiry_date) { 1.month.from_now.to_date }
  let(:group_link_params) do
    { group_access: Gitlab::Access::GUEST,
      expires_at: expiry_date }
  end

  subject { described_class.new(link, user).execute(group_link_params) }

  before do
    group.add_developer(group_member_user)
  end

  it 'updates existing link' do
    expect(link.group_access).to eq(Gitlab::Access::DEVELOPER)
    expect(link.expires_at).to be_nil

    subject

    link.reload

    expect(link.group_access).to eq(Gitlab::Access::GUEST)
    expect(link.expires_at).to eq(expiry_date)
  end

  it 'updates project permissions', :sidekiq_inline do
    expect { subject }.to change { group_member_user.can?(:create_release, project) }.from(true).to(false)
  end

  it 'schedules worker with with medium priority' do
    expect(AuthorizedProjectUpdate::EnqueueGroupMembersRefreshAuthorizedProjectsWorker).to receive(:perform_async)
      .with(group.id, { 'priority' => 'medium', 'direct_members_only' => true })
      .and_call_original

    subject
  end

  context 'when feature-flag `project_authorizations_update_in_background_for_group_shares` is disabled' do
    before do
      stub_feature_flags(project_authorizations_update_in_background_for_group_shares: false)
    end

    it 'executes refresh_members_authorized_projects' do
      expect(group)
        .to receive(:refresh_members_authorized_projects)
        .with(direct_members_only: true, priority: UserProjectAccessChangedService::MEDIUM_PRIORITY)
        .once

      subject
    end
  end

  context 'when feature-flag `change_priority_for_user_access_refresh_for_group_links` is disabled' do
    before do
      stub_feature_flags(change_priority_for_user_access_refresh_for_group_links: false)
    end

    it 'schedules worker with high priority' do
      expect(AuthorizedProjectUpdate::EnqueueGroupMembersRefreshAuthorizedProjectsWorker).to receive(:perform_async)
        .with(group.id, { 'priority' => 'high', 'direct_members_only' => true })
        .and_call_original

      subject
    end
  end

  context 'with only param not requiring authorization refresh' do
    let(:group_link_params) { { expires_at: Date.tomorrow } }

    it 'does not execute UserProjectAccessChangedService', :sidekiq_inline do
      expect(UserProjectAccessChangedService).not_to receive(:new)

      subject
    end
  end
end
