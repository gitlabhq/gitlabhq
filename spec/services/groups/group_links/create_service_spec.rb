# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::GroupLinks::CreateService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:shared_with_group_parent) { create(:group, :private) }
  let_it_be(:shared_with_group) { create(:group, :private, parent: shared_with_group_parent) }
  let_it_be(:shared_with_group_child) { create(:group, :private, parent: shared_with_group) }

  let_it_be(:group_parent) { create(:group, :private) }

  let(:group) { create(:group, :private, parent: group_parent) }

  let(:opts) do
    {
      shared_group_access: Gitlab::Access::DEVELOPER,
      expires_at: nil
    }
  end

  subject { described_class.new(group, shared_with_group, user, opts) }

  shared_examples_for 'not shareable' do
    it 'does not share and returns an error' do
      expect do
        result = subject.execute

        expect(result[:status]).to eq(:error)
        expect(result[:http_status]).to eq(404)
      end.not_to change { group.shared_with_group_links.count }
    end
  end

  shared_examples_for 'shareable' do
    it 'adds group to another group' do
      expect do
        result = subject.execute

        expect(result[:status]).to eq(:success)
      end.to change { group.shared_with_group_links.count }.from(0).to(1)
    end
  end

  context 'when user has proper membership to share a group' do
    let_it_be(:group_user) { create(:user) }

    let(:user) { group_user }

    before do
      shared_with_group.add_guest(group_user)
      group.add_owner(group_user)
    end

    it_behaves_like 'shareable'

    context 'when sharing outside the hierarchy is disabled' do
      let_it_be_with_refind(:group_parent) do
        create(:group, namespace_settings: create(:namespace_settings, prevent_sharing_groups_outside_hierarchy: true))
      end

      it_behaves_like 'not shareable'

      context 'when group is inside hierarchy' do
        let(:shared_with_group) { create(:group, :private, parent: group_parent) }

        it_behaves_like 'shareable'
      end
    end

    context 'project authorizations based on group hierarchies' do
      let_it_be(:child_group_user) { create(:user) }
      let_it_be(:parent_group_user) { create(:user) }

      before do
        shared_with_group_parent.add_owner(parent_group_user)
        shared_with_group.add_owner(group_user)
        shared_with_group_child.add_owner(child_group_user)
      end

      context 'project authorizations refresh' do
        it 'is executed only for the direct members of the group' do
          expect(UserProjectAccessChangedService).to receive(:new).with(contain_exactly(group_user.id))
                                                                  .and_call_original

          subject.execute
        end
      end

      context 'project authorizations' do
        let(:group_child) { create(:group, :private, parent: group) }
        let(:project_parent) { create(:project, group: group_parent) }
        let(:project) { create(:project, group: group) }
        let(:project_child) { create(:project, group: group_child) }

        context 'group user' do
          let(:user) { group_user }

          it 'create proper authorizations' do
            subject.execute

            expect(Ability.allowed?(user, :read_project, project_parent)).to be_falsey
            expect(Ability.allowed?(user, :read_project, project)).to be_truthy
            expect(Ability.allowed?(user, :read_project, project_child)).to be_truthy
          end
        end

        context 'parent group user' do
          let(:user) { parent_group_user }

          it 'create proper authorizations' do
            subject.execute

            expect(Ability.allowed?(user, :read_project, project_parent)).to be_falsey
            expect(Ability.allowed?(user, :read_project, project)).to be_falsey
            expect(Ability.allowed?(user, :read_project, project_child)).to be_falsey
          end
        end

        context 'child group user' do
          let(:user) { child_group_user }

          it 'create proper authorizations' do
            subject.execute

            expect(Ability.allowed?(user, :read_project, project_parent)).to be_falsey
            expect(Ability.allowed?(user, :read_project, project)).to be_falsey
            expect(Ability.allowed?(user, :read_project, project_child)).to be_falsey
          end
        end
      end
    end
  end

  context 'user does not have access to group' do
    let(:user) { create(:user) }

    before do
      group.add_owner(user)
    end

    it_behaves_like 'not shareable'
  end

  context 'user does not have admin access to shared group' do
    let(:user) { create(:user) }

    before do
      shared_with_group.add_guest(user)
      group.add_developer(user)
    end

    it_behaves_like 'not shareable'
  end

  context 'when group is blank' do
    let(:group_user) { create(:user) }
    let(:user) { group_user }
    let(:group) { nil }

    it 'does not share and returns an error' do
      expect do
        result = subject.execute

        expect(result[:status]).to eq(:error)
        expect(result[:http_status]).to eq(404)
      end.not_to change { shared_with_group.shared_group_links.count }
    end
  end

  context 'when shared_with_group is blank' do
    let(:group_user) { create(:user) }
    let(:user) { group_user }
    let(:shared_with_group) { nil }

    it_behaves_like 'not shareable'
  end
end
