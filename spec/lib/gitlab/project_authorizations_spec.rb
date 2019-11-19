# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ProjectAuthorizations do
  def map_access_levels(rows)
    rows.each_with_object({}) do |row, hash|
      hash[row.project_id] = row.access_level
    end
  end

  subject(:authorizations) do
    described_class.new(user).calculate
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

      expect(mapping[owned_project.id]).to eq(Gitlab::Access::MAINTAINER)
      expect(mapping[other_project.id]).to eq(Gitlab::Access::REPORTER)
      expect(mapping[group_project.id]).to eq(Gitlab::Access::DEVELOPER)
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

    context 'when feature flag share_group_with_group is enabled' do
      before do
        stub_feature_flags(share_group_with_group: true)
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
    end

    context 'when feature flag share_group_with_group is disabled' do
      before do
        stub_feature_flags(share_group_with_group: false)
      end

      context 'group user' do
        let(:user) { group_user }

        it 'creates proper authorizations' do
          mapping = map_access_levels(authorizations)

          expect(mapping[project_parent.id]).to be_nil
          expect(mapping[project.id]).to be_nil
          expect(mapping[project_child.id]).to be_nil
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
    end
  end
end
