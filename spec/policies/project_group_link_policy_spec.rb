# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectGroupLinkPolicy, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group2) { create(:group, :private) }
  let_it_be(:project) { create(:project, :private) }

  let(:project_group_link) do
    create(:project_group_link, project: project, group: group2, group_access: Gitlab::Access::DEVELOPER)
  end

  subject(:policy) { described_class.new(user, project_group_link) }

  describe 'admin_project_group_link' do
    context 'when the user is a group owner' do
      before_all do
        group2.add_owner(user)
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

  describe 'read_shared_with_group' do
    context 'when the user is a project member' do
      before_all do
        project.add_guest(user)
      end

      it 'can read_shared_with_group' do
        expect(policy).to be_allowed(:read_shared_with_group)
      end
    end

    context 'when the user is not a project member' do
      context 'when user is not a group member' do
        context 'when the group is private' do
          it 'cannot read_shared_with_group' do
            expect(policy).to be_disallowed(:read_shared_with_group)
          end

          context 'when the project is public' do
            let_it_be(:project) { create(:project, :public) }

            it 'cannot read_shared_with_group' do
              expect(policy).to be_disallowed(:read_shared_with_group)
            end
          end
        end

        context 'when the group is public' do
          let_it_be(:group2) { create(:group, :public) }

          it 'can read_shared_with_group' do
            expect(policy).to be_allowed(:read_shared_with_group)
          end
        end
      end

      context 'when user is a group member' do
        before_all do
          group2.add_guest(user)
        end

        it 'can read_shared_with_group' do
          expect(policy).to be_allowed(:read_shared_with_group)
        end
      end
    end
  end
end
