# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ArchiveService, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, namespace: group) }

  subject(:service) { described_class.new(project: project, current_user: user) }

  describe '#execute' do
    context 'when user is not authorized to archive project' do
      before_all do
        project.add_maintainer(user)
      end

      it 'returns not authorized error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq("You don't have permissions to archive this project.")
      end
    end

    context 'when user is authorized to archive project' do
      before_all do
        project.add_owner(user)
      end

      context 'when project ancestors are already archived' do
        before do
          group.update!(archived: true)
        end

        it 'returns ancestor already archived error' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq('Cannot archive project since one of the ancestors is already archived.')
        end
      end

      context 'when project ancestors are not archived' do
        context 'when archiving project fails' do
          before do
            allow(project).to receive(:update).with(archived: true).and_return(false)
            allow(project).to receive_message_chain(:errors, :full_messages, :to_sentence)
                                .and_return('Validation failed')
          end

          it 'returns error with validation messages' do
            result = service.execute

            expect(result).to be_error
            expect(result.message).to eq('Validation failed')
          end
        end

        context 'when archiving project fails without specific error messages' do
          before do
            allow(project).to receive(:update).with(archived: true).and_return(false)
            allow(project).to receive_message_chain(:errors, :full_messages, :to_sentence).and_return('')
          end

          it 'returns generic archiving failed error' do
            result = service.execute

            expect(result).to be_error
            expect(result.message).to eq('Failed to archive project.')
          end
        end

        context 'when archiving project succeeds' do
          let(:unlink_fork_service) { instance_double(Projects::UnlinkForkService, execute: true) }
          let(:system_hook_service) { instance_double(SystemHooksService) }

          it 'returns success' do
            result = service.execute

            expect(result).to be_success
          end

          it 'updates the project archived status to true' do
            expect { service.execute }.to change { project.reload.archived }.from(false).to(true)
          end

          it 'executes system hooks' do
            allow(service).to receive(:system_hook_service).and_return(system_hook_service)

            expect(system_hook_service).to receive(:execute_hooks_for).with(project, :update)

            service.execute
          end

          it 'unlinks fork' do
            allow(Projects::UnlinkForkService).to receive(:new).and_return(unlink_fork_service)

            expect(unlink_fork_service).to receive(:execute)

            service.execute
          end

          it 'publishes a ProjectArchivedEvent' do
            expect { service.execute }.to publish_event(Projects::ProjectArchivedEvent)
              .with(
                project_id: project.id,
                namespace_id: project.namespace_id,
                root_namespace_id: project.root_namespace.id
              )
          end
        end
      end
    end
  end
end
