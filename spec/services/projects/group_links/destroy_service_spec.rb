# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinks::DestroyService, '#execute', feature_category: :groups_and_projects do
  let_it_be(:user) { create :user }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_user) { create(:user, guest_of: group) }

  let(:group_access) { Gitlab::Access::DEVELOPER }
  let!(:group_link) { create(:project_group_link, project: project, group: group, group_access: group_access) }

  subject { described_class.new(project, user) }

  shared_examples_for 'removes group from project' do
    it 'removes group from project' do
      expect { subject.execute(group_link) }.to change { project.reload.project_group_links.count }.from(1).to(0)
    end
  end

  context 'if group_link is blank' do
    let!(:group_link) { nil }

    it 'returns 404 not found' do
      expect do
        result = subject.execute(group_link)

        expect(result[:status]).to eq(:error)
        expect(result[:reason]).to eq(:not_found)
      end.not_to change { project.reload.project_group_links.count }
    end
  end

  context 'if the user does not have access to destroy the link' do
    it 'returns 404 not found' do
      expect do
        result = subject.execute(group_link)

        expect(result[:status]).to eq(:error)
        expect(result[:reason]).to eq(:not_found)
      end.not_to change { project.reload.project_group_links.count }
    end
  end

  context 'when the user has proper permissions to remove a group-link from a project' do
    context 'when the user is a MAINTAINER in the project' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'removes group from project'

      context 'project authorizations refresh' do
        it 'calls AuthorizedProjectUpdate::ProjectRecalculateWorker to update project authorizations' do
          expect(AuthorizedProjectUpdate::ProjectRecalculateWorker)
            .to receive(:perform_async).with(group_link.project.id)

          subject.execute(group_link)
        end

        it 'calls AuthorizedProjectUpdate::UserRefreshFromReplicaWorker with a delay to update project authorizations' do
          stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)

          expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
            receive(:bulk_perform_in).with(
              1.hour,
              [[group_user.id]],
              batch_delay: 30.seconds, batch_size: 100
            )
          )

          subject.execute(group_link)
        end

        it 'updates project authorizations of users who had access to the project via the group share', :sidekiq_inline do
          expect { subject.execute(group_link) }.to(
            change { Ability.allowed?(group_user, :read_project, project) }
              .from(true).to(false))
        end
      end

      describe 'todos cleanup' do
        context 'when project is private' do
          it 'triggers todos cleanup' do
            expect(TodosDestroyer::ProjectPrivateWorker).to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, project.id)
            expect(project.private?).to be true

            subject.execute(group_link)
          end
        end

        context 'when project is public or internal' do
          shared_examples_for 'removes confidential todos' do
            it 'does not trigger todos cleanup' do
              expect(TodosDestroyer::ProjectPrivateWorker).not_to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, project.id)
              expect(TodosDestroyer::ConfidentialIssueWorker).to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, nil, project.id)
              expect(project.private?).to be false

              subject.execute(group_link)
            end
          end

          context 'when project is public' do
            let(:project) { create(:project, :public) }

            it_behaves_like 'removes confidential todos'
          end

          context 'when project is internal' do
            let(:project) { create(:project, :public) }

            it_behaves_like 'removes confidential todos'
          end
        end
      end

      context 'on trying to destroy a link with OWNER access' do
        let(:group_access) { Gitlab::Access::OWNER }

        it 'does not remove the group from project' do
          expect do
            result = subject.execute(group_link)

            expect(result[:status]).to eq(:error)
            expect(result[:reason]).to eq(:forbidden)
          end.not_to change { project.reload.project_group_links.count }
        end

        context 'if the user is an OWNER of the group' do
          before do
            group.add_owner(user)
          end

          it_behaves_like 'removes group from project'
        end
      end
    end

    context 'when the user is an OWNER in the project' do
      before do
        project.add_owner(user)
      end

      it_behaves_like 'removes group from project'

      context 'on trying to destroy a link with OWNER access' do
        let(:group_access) { Gitlab::Access::OWNER }

        it_behaves_like 'removes group from project'
      end
    end
  end

  context 'when skipping authorization' do
    context 'without providing a user' do
      it 'destroys the link' do
        expect do
          described_class.new(project, nil).execute(group_link, skip_authorization: true)
        end.to change { project.reload.project_group_links.count }.by(-1)
      end
    end
  end
end
