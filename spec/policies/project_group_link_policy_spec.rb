# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectGroupLinkPolicy, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group2) { create(:group, :private) }
  let_it_be(:project) { create(:project, :private) }

  subject(:policy) { described_class.new(user, project_group_link) }

  describe 'destroy_project_group_link' do
    let_it_be(:project_group_link) do
      create(:project_group_link, project: project, group: group2, group_access: Gitlab::Access::DEVELOPER)
    end

    context 'when the user is a group owner' do
      before_all do
        group2.add_owner(user)
      end

      it 'can destroy group_project_link' do
        expect(policy).to be_allowed(:destroy_project_group_link)
      end

      context 'when group link has owner access' do
        it 'can destroy group_project_link' do
          project_group_link.update!(group_access: Gitlab::Access::OWNER)

          expect(policy).to be_allowed(:destroy_project_group_link)
        end
      end
    end

    context 'when user is a project maintainer' do
      before do
        project_group_link.project.add_maintainer(user)
      end

      context 'when group link has owner access' do
        it 'cannot destroy group_project_link' do
          project_group_link.update!(group_access: Gitlab::Access::OWNER)

          expect(policy).to be_disallowed(:destroy_project_group_link)
        end
      end

      context 'when group link has maintainer access' do
        it 'can destroy group_project_link' do
          project_group_link.update!(group_access: Gitlab::Access::MAINTAINER)

          expect(policy).to be_allowed(:destroy_project_group_link)
        end
      end
    end

    context 'when user is not a project maintainer' do
      it 'cannot destroy group_project_link' do
        project_group_link.project.add_developer(user)

        expect(policy).to be_disallowed(:destroy_project_group_link)
      end
    end
  end

  describe 'manage_destroy' do
    let_it_be(:project_group_link) do
      create(:project_group_link, project: project, group: group2, group_access: Gitlab::Access::DEVELOPER)
    end

    context 'when the user is a group owner' do
      before_all do
        group2.add_owner(user)
      end

      context 'when user is not project maintainer' do
        it 'can manage_destroy' do
          expect(policy).to be_allowed(:manage_destroy)
        end
      end

      context 'when user is a project maintainer' do
        before do
          project_group_link.project.add_maintainer(user)
        end

        it 'can admin manage_destroy' do
          expect(policy).to be_allowed(:manage_destroy)
        end
      end
    end

    context 'when user is not a group owner' do
      context 'when user is a project maintainer' do
        before do
          project_group_link.project.add_maintainer(user)
        end

        context 'when group link has owner access' do
          it 'can manage_destroy' do
            project_group_link.update!(group_access: Gitlab::Access::OWNER)

            expect(policy).to be_allowed(:manage_destroy)
          end
        end

        context 'when group link has maintainer access' do
          it 'can manage_destroy' do
            project_group_link.update!(group_access: Gitlab::Access::MAINTAINER)

            expect(policy).to be_allowed(:manage_destroy)
          end
        end
      end

      context 'when user is not a project maintainer' do
        it 'cannot manage_destroy' do
          project_group_link.project.add_developer(user)

          expect(policy).to be_disallowed(:manage_destroy)
        end
      end
    end
  end

  describe 'read_shared_with_group' do
    let_it_be(:project_group_link) do
      create(:project_group_link, project: project, group: group2, group_access: Gitlab::Access::MAINTAINER)
    end

    context 'when the user is a project member' do
      context 'when the user is not a project admin' do
        before_all do
          project.add_guest(user)
        end

        it 'cannot read_shared_with_group' do
          expect(policy).to be_disallowed(:read_shared_with_group)
        end
      end

      context 'when the user is a project admin' do
        before_all do
          project.add_maintainer(user)
        end

        it 'can read_shared_with_group' do
          expect(policy).to be_allowed(:read_shared_with_group)
        end
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
          it 'can read_shared_with_group' do
            group2.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)

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

  describe 'manage_owners' do
    let_it_be(:project_group_link) do
      create(:project_group_link, project: project, group: group2, group_access: Gitlab::Access::MAINTAINER)
    end

    context 'when the user is a project owner' do
      before_all do
        project.add_owner(user)
      end

      it 'can manage_owners' do
        expect(policy).to be_allowed(:manage_owners)
      end
    end

    context 'when the user is a project maintainer' do
      before_all do
        project.add_maintainer(user)
      end

      it 'cannot manage_owners' do
        expect(policy).to be_disallowed(:manage_owners)
      end
    end
  end

  describe 'manage_group_link_with_owner_access' do
    context 'when group link has owner access' do
      let_it_be(:project_group_link) do
        create(:project_group_link, project: project, group: group2, group_access: Gitlab::Access::OWNER)
      end

      context 'when the user is a project owner' do
        before_all do
          project.add_owner(user)
        end

        it 'can manage_group_link_with_owner_access' do
          expect(policy).to be_allowed(:manage_group_link_with_owner_access)
        end
      end

      context 'when the user is a project maintainer' do
        before_all do
          project.add_maintainer(user)
        end

        it 'cannot manage_group_link_with_owner_access' do
          expect(policy).to be_disallowed(:manage_group_link_with_owner_access)
        end
      end
    end

    context 'when group link has maintainer access' do
      let_it_be(:project_group_link) do
        create(:project_group_link, project: project, group: group2, group_access: Gitlab::Access::MAINTAINER)
      end

      it 'can manage_group_link_with_owner_access' do
        expect(policy).to be_allowed(:manage_group_link_with_owner_access)
      end
    end
  end
end
