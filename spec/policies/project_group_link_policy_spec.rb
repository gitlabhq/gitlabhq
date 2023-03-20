# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectGroupLinkPolicy, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:group2) { create(:group, :private) }
  let_it_be(:project) { create(:project, :private, group: group) }

  let(:project_group_link) do
    create(:project_group_link, project: project, group: group2, group_access: Gitlab::Access::DEVELOPER)
  end

  subject(:policy) { described_class.new(user, project_group_link) }

  context 'when the user is a group owner' do
    before do
      project_group_link.group.add_owner(user)
    end

    context 'when user is not project maintainer' do
      it 'can admin group_project_link' do
        expect(policy).to be_allowed(:admin_project_group_link)
      end
    end

    context 'when user is a project maintainer' do
      before do
        project_group_link.project.add_maintainer(user)
      end

      it 'can admin group_project_link' do
        expect(policy).to be_allowed(:admin_project_group_link)
      end
    end
  end

  context 'when user is not a group owner' do
    context 'when user is a project maintainer' do
      it 'can admin group_project_link' do
        project_group_link.project.add_maintainer(user)

        expect(policy).to be_allowed(:admin_project_group_link)
      end
    end

    context 'when user is not a project maintainer' do
      it 'cannot admin group_project_link' do
        project_group_link.project.add_developer(user)

        expect(policy).to be_disallowed(:admin_project_group_link)
      end
    end
  end
end
