# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AdjournedProjectDeletionWorker, feature_category: :groups_and_projects do
  describe "#perform" do
    subject(:worker) { described_class.new }

    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group, marked_for_deletion_at: 8.days.ago, deleting_user: user) }

    context 'when the project is not found' do
      it 'does not call the adjourned deletion service' do
        expect(Projects::AdjournedDeletionService).not_to receive(:new)
        worker.perform(non_existing_record_id)
      end
    end

    context 'when deleting user has access to remove the project', :sidekiq_inline do
      shared_examples 'destroys the project' do
        specify do
          worker.perform(project.id)

          expect(Project.exists?(project.id)).to be_falsey
        end
      end

      context 'when user is a direct owner' do
        before_all do
          project.add_owner(user)
        end

        it_behaves_like 'destroys the project'
      end

      context 'when user is an inherited owner' do
        before_all do
          group.add_owner(user)
        end

        it_behaves_like 'destroys the project'
      end

      context 'when user is an owner through project sharing' do
        before_all do
          invited_group = create(:group, owners: user)
          create(:project_group_link, :owner, project: project, group: invited_group)
        end

        it_behaves_like 'destroys the project'
      end

      context 'when user is an owner through parent group sharing' do
        before_all do
          invited_group = create(:group)
          create(:group_group_link, :owner, shared_group: group, shared_with_group: invited_group)
          invited_group.add_owner(user)
        end

        it_behaves_like 'destroys the project'
      end

      context 'when an admin deletes the project', :enable_admin_mode do
        let_it_be(:user) { create(:admin) }

        before do
          project.update!(deleting_user: user)
        end

        it_behaves_like 'destroys the project'
      end
    end

    context 'when deleting user does not have access to remove the project', :sidekiq_inline do
      shared_examples 'restores the project' do
        specify do
          worker.perform(project.id)

          expect(project.reload.marked_for_deletion_at.present?).to be(false)
        end
      end

      it_behaves_like 'restores the project'

      context 'when deleting user was deleted' do
        before do
          project.update!(deleting_user: nil)
        end

        it_behaves_like 'restores the project'
      end
    end
  end
end
