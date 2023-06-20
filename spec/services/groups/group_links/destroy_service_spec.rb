# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupLinks::DestroyService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:shared_group) { create(:group, :private) }
  let_it_be(:project) { create(:project, group: shared_group) }
  let_it_be(:owner) { create(:user) }

  subject { described_class.new(shared_group, owner) }

  context 'when authorizing by user' do
    before do
      group.add_developer(owner)
      shared_group.add_owner(owner)
    end

    context 'single link' do
      let!(:link) { create(:group_group_link, shared_group: shared_group, shared_with_group: group) }

      it 'destroys the link' do
        expect { subject.execute(link) }.to change { shared_group.shared_with_group_links.count }.from(1).to(0)
      end

      context 'with skip_group_share_unlink_auth_refresh feature flag disabled' do
        before do
          stub_feature_flags(skip_group_share_unlink_auth_refresh: false)
        end

        it 'revokes project authorization', :sidekiq_inline do
          group.add_developer(user)

          expect { subject.execute(link) }.to(
            change { Ability.allowed?(user, :read_project, project) }.from(true).to(false))
        end
      end

      context 'with skip_group_share_unlink_auth_refresh feature flag enabled' do
        before do
          stub_feature_flags(skip_group_share_unlink_auth_refresh: true)
        end

        it 'maintains project authorization', :sidekiq_inline do
          group.add_developer(user)

          expect(Ability.allowed?(user, :read_project, project)).to be_truthy
        end
      end
    end

    context 'multiple links' do
      let_it_be(:another_group) { create(:group, :private) }
      let_it_be(:another_shared_group) { create(:group, :private) }

      let!(:links) do
        [
          create(:group_group_link, shared_group: shared_group, shared_with_group: group),
          create(:group_group_link, shared_group: shared_group, shared_with_group: another_group),
          create(:group_group_link, shared_group: another_shared_group, shared_with_group: group),
          create(:group_group_link, shared_group: another_shared_group, shared_with_group: another_group)
        ]
      end

      context 'with skip_group_share_unlink_auth_refresh feature flag disabled' do
        before do
          stub_feature_flags(skip_group_share_unlink_auth_refresh: false)
        end

        it 'updates project authorization once per group' do
          expect(GroupGroupLink).to receive(:delete).and_call_original
          expect(group).to receive(:refresh_members_authorized_projects).with(direct_members_only: true).once
          expect(another_group).to receive(:refresh_members_authorized_projects).with(direct_members_only: true).once

          subject.execute(links)
        end
      end

      context 'with skip_group_share_unlink_auth_refresh feature flag enabled' do
        before do
          stub_feature_flags(skip_group_share_unlink_auth_refresh: true)
        end

        it 'does not update project authorization once per group' do
          expect(GroupGroupLink).to receive(:delete).and_call_original
          expect(group).not_to receive(:refresh_members_authorized_projects)
          expect(another_group).not_to receive(:refresh_members_authorized_projects)

          subject.execute(links)
        end
      end
    end
  end

  context 'when skipping authorization' do
    let!(:link) { create(:group_group_link, shared_group: shared_group, shared_with_group: group) }

    context 'with provided group and owner' do
      it 'destroys the link' do
        expect do
          subject.execute(link, skip_authorization: true)
        end.to change { shared_group.shared_with_group_links.count }.from(1).to(0)
      end
    end

    context 'without providing group or owner' do
      subject { described_class.new(nil, nil) }

      it 'destroys the link' do
        expect do
          subject.execute(link, skip_authorization: true)
        end.to change { shared_group.shared_with_group_links.count }.from(1).to(0)
      end
    end
  end
end
