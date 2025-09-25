# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectGroupLinkPolicy, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:public_group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :private) }

  subject(:policy) { described_class.new(user, project_group_link) }

  describe 'delegates to project policy' do
    let_it_be(:project_group_link) { create(:project_group_link, project: project, group: private_group) }

    context 'when user is project owner' do
      before_all do
        project.add_owner(user)
      end

      it 'allows update_group_link' do
        expect(policy).to be_allowed(:update_group_link)
      end

      it 'allows delete_group_link' do
        expect(policy).to be_allowed(:delete_group_link)
      end

      it 'allows create_group_link' do
        expect(policy).to be_allowed(:create_group_link)
      end
    end

    context 'when user is project maintainer' do
      before_all do
        project.add_maintainer(user)
      end

      it 'does not allow update_group_link' do
        expect(policy).to be_disallowed(:update_group_link)
      end

      it 'does not allow delete_group_link' do
        expect(policy).to be_disallowed(:delete_group_link)
      end

      it 'does not allow create_group_link' do
        expect(policy).to be_disallowed(:create_group_link)
      end
    end

    context 'when user has no project access' do
      it 'does not allow any group link permissions' do
        expect(policy).to be_disallowed(:update_group_link)
        expect(policy).to be_disallowed(:delete_group_link)
        expect(policy).to be_disallowed(:create_group_link)
      end
    end
  end
end
