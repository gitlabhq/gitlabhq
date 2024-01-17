# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ProjectAuthorizations, feature_category: :system_access do
  def map_access_levels(rows)
    rows.each_with_object({}) do |row, hash|
      hash[row.project_id] = row.access_level
    end
  end

  let(:service) { described_class.new(user) }

  subject(:authorizations) do
    service.calculate
  end

  context 'user added to group and project' do
    let(:group) { create(:group) }
    let!(:other_project) { create(:project) }
    let!(:group_project) { create(:project, namespace: group) }
    let!(:owned_project) { create(:project) }
    let(:user) { owned_project.namespace.owner }

    before do
      other_project.add_reporter(user)
      group.add_developer(user)
    end

    it 'returns the correct number of authorizations' do
      expect(authorizations.length).to eq(3)
    end

    it 'includes the correct projects' do
      expect(authorizations.pluck(:project_id))
        .to include(owned_project.id, other_project.id, group_project.id)
    end

    it 'includes the correct access levels' do
      mapping = map_access_levels(authorizations)

      expect(mapping[owned_project.id]).to eq(Gitlab::Access::OWNER)
      expect(mapping[other_project.id]).to eq(Gitlab::Access::REPORTER)
      expect(mapping[group_project.id]).to eq(Gitlab::Access::DEVELOPER)
    end
  end

  context 'unapproved access request' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    subject(:mapping) { map_access_levels(authorizations) }

    context 'group membership' do
      let!(:group_project) { create(:project, namespace: group) }

      before do
        create(:group_member, :developer, :access_request, user: user, group: group)
      end

      it 'does not create authorization' do
        expect(mapping[group_project.id]).to be_nil
      end
    end

    context 'inherited group membership' do
      let!(:sub_group) { create(:group, parent: group) }
      let!(:sub_group_project) { create(:project, namespace: sub_group) }

      before do
        create(:group_member, :developer, :access_request, user: user, group: group)
      end

      it 'does not create authorization' do
        expect(mapping[sub_group_project.id]).to be_nil
      end
    end

    context 'project membership' do
      let!(:group_project) { create(:project, namespace: group) }

      before do
        create(:project_member, :developer, :access_request, user: user, project: group_project)
      end

      it 'does not create authorization' do
        expect(mapping[group_project.id]).to be_nil
      end
    end

    context 'shared group' do
      let!(:shared_group) { create(:group) }
      let!(:shared_group_project) { create(:project, namespace: shared_group) }

      before do
        create(:group_group_link, shared_group: shared_group, shared_with_group: group)
        create(:group_member, :developer, :access_request, user: user, group: group)
      end

      it 'does not create authorization' do
        expect(mapping[shared_group_project.id]).to be_nil
      end
    end

    context 'shared project' do
      let!(:another_group) { create(:group) }
      let!(:shared_project) { create(:project, namespace: another_group) }

      before do
        create(:project_group_link, group: group, project: shared_project)
        create(:group_member, :developer, :access_request, user: user, group: group)
      end

      it 'does not create authorization' do
        expect(mapping[shared_project.id]).to be_nil
      end
    end
  end

  context 'user with minimal access to group' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    subject(:mapping) { map_access_levels(authorizations) }

    context 'group membership' do
      let!(:group_project) { create(:project, namespace: group) }

      before do
        create(:group_member, :minimal_access, user: user, source: group)
      end

      it 'does not create authorization' do
        expect(mapping[group_project.id]).to be_nil
      end
    end

    context 'inherited group membership' do
      let!(:sub_group) { create(:group, parent: group) }
      let!(:sub_group_project) { create(:project, namespace: sub_group) }

      before do
        create(:group_member, :minimal_access, user: user, source: group)
      end

      it 'does not create authorization' do
        expect(mapping[sub_group_project.id]).to be_nil
      end
    end

    context 'shared group' do
      let!(:shared_group) { create(:group) }
      let!(:shared_group_project) { create(:project, namespace: shared_group) }

      before do
        create(:group_group_link, shared_group: shared_group, shared_with_group: group)
        create(:group_member, :minimal_access, user: user, source: group)
      end

      it 'does not create authorization' do
        expect(mapping[shared_group_project.id]).to be_nil
      end
    end

    context 'shared project' do
      let!(:another_group) { create(:group) }
      let!(:shared_project) { create(:project, namespace: another_group) }

      before do
        create(:project_group_link, group: group, project: shared_project)
        create(:group_member, :minimal_access, user: user, source: group)
      end

      it 'does not create authorization' do
        expect(mapping[shared_project.id]).to be_nil
      end
    end
  end

  context 'with nested groups' do
    let(:group) { create(:group) }
    let!(:nested_group) { create(:group, parent: group) }
    let!(:nested_project) { create(:project, namespace: nested_group) }
    let(:user) { create(:user) }

    before do
      group.add_developer(user)
    end

    it 'includes nested groups' do
      expect(authorizations.pluck(:project_id)).to include(nested_project.id)
    end

    it 'inherits access levels when the user is not a member of a nested group' do
      mapping = map_access_levels(authorizations)

      expect(mapping[nested_project.id]).to eq(Gitlab::Access::DEVELOPER)
    end

    it 'uses the greatest access level when a user is a member of a nested group' do
      nested_group.add_maintainer(user)

      mapping = map_access_levels(authorizations)

      expect(mapping[nested_project.id]).to eq(Gitlab::Access::MAINTAINER)
    end
  end

  context 'with shared projects' do
    let_it_be(:shared_with_group) { create(:group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, group: create(:group)) }

    let(:mapping) { map_access_levels(authorizations) }

    before do
      create(:project_group_link, :developer, project: project, group: shared_with_group)
      shared_with_group.add_maintainer(user)
    end

    it 'creates proper authorizations' do
      expect(mapping[project.id]).to eq(Gitlab::Access::DEVELOPER)
    end

    context 'even when the `lock_memberships_to_ldap` setting has been turned ON' do
      before do
        stub_application_setting(lock_memberships_to_ldap: true)
      end

      it 'creates proper authorizations' do
        expect(mapping[project.id]).to eq(Gitlab::Access::DEVELOPER)
      end
    end

    context 'when the group containing the project has forbidden group shares for any of its projects' do
      before do
        project.namespace.update!(share_with_group_lock: true)
      end

      it 'does not create authorizations' do
        expect(mapping[project.id]).to be_nil
      end
    end
  end

  context 'with shared groups' do
    let(:parent_group_user) { create(:user) }
    let(:group_user) { create(:user) }
    let(:child_group_user) { create(:user) }

    let_it_be(:group_parent) { create(:group, :private) }
    let_it_be(:group) { create(:group, :private, parent: group_parent) }
    let_it_be(:group_child) { create(:group, :private, parent: group) }

    let_it_be(:shared_group_parent) { create(:group, :private) }
    let_it_be(:shared_group) { create(:group, :private, parent: shared_group_parent) }
    let_it_be(:shared_group_child) { create(:group, :private, parent: shared_group) }

    let_it_be(:project_parent) { create(:project, group: shared_group_parent) }
    let_it_be(:project) { create(:project, group: shared_group) }
    let_it_be(:project_child) { create(:project, group: shared_group_child) }

    before do
      group_parent.add_owner(parent_group_user)
      group.add_owner(group_user)
      group_child.add_owner(child_group_user)

      create(:group_group_link, shared_group: shared_group, shared_with_group: group)
    end

    context 'group user' do
      let(:user) { group_user }

      it 'creates proper authorizations' do
        mapping = map_access_levels(authorizations)

        expect(mapping[project_parent.id]).to be_nil
        expect(mapping[project.id]).to eq(Gitlab::Access::DEVELOPER)
        expect(mapping[project_child.id]).to eq(Gitlab::Access::DEVELOPER)
      end
    end

    context 'with lower group access level than max access level for share' do
      let(:user) { create(:user) }

      it 'creates proper authorizations' do
        group.add_reporter(user)

        mapping = map_access_levels(authorizations)

        expect(mapping[project_parent.id]).to be_nil
        expect(mapping[project.id]).to eq(Gitlab::Access::REPORTER)
        expect(mapping[project_child.id]).to eq(Gitlab::Access::REPORTER)
      end
    end

    context 'parent group user' do
      let(:user) { parent_group_user }

      it 'creates proper authorizations' do
        mapping = map_access_levels(authorizations)

        expect(mapping[project_parent.id]).to be_nil
        expect(mapping[project.id]).to be_nil
        expect(mapping[project_child.id]).to be_nil
      end
    end

    context 'child group user' do
      let(:user) { child_group_user }

      it 'creates proper authorizations' do
        mapping = map_access_levels(authorizations)

        expect(mapping[project_parent.id]).to be_nil
        expect(mapping[project.id]).to be_nil
        expect(mapping[project_child.id]).to be_nil
      end
    end

    context 'user without accepted access request' do
      let!(:user) { create(:user) }

      it 'does not have access to group and its projects' do
        create(:group_member, :developer, :access_request, user: user, group: group)

        mapping = map_access_levels(authorizations)

        expect(mapping[project_parent.id]).to be_nil
        expect(mapping[project.id]).to be_nil
        expect(mapping[project_child.id]).to be_nil
      end
    end

    context 'unrelated project owner' do
      let(:common_id) { non_existing_record_id }
      let!(:group) { create(:group, id: common_id) }
      let!(:unrelated_project) { create(:project, id: common_id) }
      let(:user) { unrelated_project.first_owner }

      it 'does not have access to group and its projects' do
        mapping = map_access_levels(authorizations)

        expect(mapping[project_parent.id]).to be_nil
        expect(mapping[project.id]).to be_nil
        expect(mapping[project_child.id]).to be_nil
      end
    end
  end

  context 'with pending memberships' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    subject(:mapping) { map_access_levels(authorizations) }

    context 'group membership' do
      let!(:group_project) { create(:project, namespace: group) }

      before do
        create(:group_member, :developer, :awaiting, user: user, group: group)
      end

      it 'does not create authorization' do
        expect(mapping[group_project.id]).to be_nil
      end
    end

    context 'inherited group membership' do
      let!(:sub_group) { create(:group, parent: group) }
      let!(:sub_group_project) { create(:project, namespace: sub_group) }

      before do
        create(:group_member, :developer, :awaiting, user: user, group: group)
      end

      it 'does not create authorization' do
        expect(mapping[sub_group_project.id]).to be_nil
      end
    end

    context 'project membership' do
      let!(:group_project) { create(:project, namespace: group) }

      before do
        create(:project_member, :developer, :awaiting, user: user, project: group_project)
      end

      it 'does not create authorization' do
        expect(mapping[group_project.id]).to be_nil
      end
    end

    context 'shared group' do
      let!(:shared_group) { create(:group) }
      let!(:shared_group_project) { create(:project, namespace: shared_group) }

      before do
        create(:group_group_link, shared_group: shared_group, shared_with_group: group)
        create(:group_member, :developer, :awaiting, user: user, group: group)
      end

      it 'does not create authorization' do
        expect(mapping[shared_group_project.id]).to be_nil
      end
    end

    context 'shared project' do
      let!(:another_group) { create(:group) }
      let!(:shared_project) { create(:project, namespace: another_group) }

      before do
        create(:project_group_link, group: group, project: shared_project)
        create(:group_member, :developer, :awaiting, user: user, group: group)
      end

      it 'does not create authorization' do
        expect(mapping[shared_project.id]).to be_nil
      end
    end
  end
end
