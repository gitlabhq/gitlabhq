# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:user_management tasks', :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/gitlab/user_management'
  end

  describe 'disable_project_and_group_creation' do
    let(:group) { create(:group) }

    subject(:run_rake) { run_rake_task('gitlab:user_management:disable_project_and_group_creation', group.id) }

    it 'returns output info' do
      expect { run_rake }.to output(/.*Done.*/).to_stdout
    end

    context 'with users' do
      let(:user_1) { create(:user, projects_limit: 10, can_create_group: true) }
      let(:user_2) { create(:user, projects_limit: 10, can_create_group: true) }
      let(:user_other) { create(:user, projects_limit: 10, can_create_group: true) }

      shared_examples 'updates proper users' do
        it 'updates members' do
          run_rake

          expect(user_1.reload.projects_limit).to eq(0)
          expect(user_1.can_create_group).to eq(false)
          expect(user_2.reload.projects_limit).to eq(0)
          expect(user_2.can_create_group).to eq(false)
        end

        it 'does not update other users' do
          run_rake

          expect(user_other.reload.projects_limit).to eq(10)
          expect(user_other.reload.can_create_group).to eq(true)
        end
      end

      context 'in the group' do
        let(:other_group) { create(:group) }

        before do
          group.add_developer(user_1)
          group.add_developer(user_2)
          other_group.add_developer(user_other)
        end

        it_behaves_like 'updates proper users'
      end

      context 'in the descendant groups' do
        let(:subgroup) { create(:group, parent: group) }
        let(:sub_subgroup) { create(:group, parent: subgroup) }
        let(:other_group) { create(:group) }

        before do
          subgroup.add_developer(user_1)
          sub_subgroup.add_developer(user_2)
          other_group.add_developer(user_other)
        end

        it_behaves_like 'updates proper users'
      end

      context 'in the children projects' do
        let(:project_1) { create(:project, namespace: group) }
        let(:project_2) { create(:project, namespace: group) }
        let(:other_project) { create(:project) }

        before do
          project_1.add_developer(user_1)
          project_2.add_developer(user_2)
          other_project.add_developer(user_other)
        end

        it_behaves_like 'updates proper users'
      end
    end
  end
end
