# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UnarchiveService, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, namespace: group, archived: true) }

  subject(:service) { described_class.new(project: project, current_user: user) }

  describe '#execute' do
    context 'when user is not authorized to unarchive project' do
      before_all do
        project.add_maintainer(user)
      end

      it 'returns not authorized error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq("You don't have permissions to unarchive this project.")
      end
    end

    context 'when user is authorized to unarchive project' do
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
          expect(result.message).to eq('Cannot unarchive project since one of the ancestors is archived.')
        end
      end

      context 'when project ancestors are not archived' do
        context 'when unarchiving project fails' do
          before do
            allow(project).to receive(:update).with(archived: false).and_return(false)
            allow(project).to receive_message_chain(:errors, :full_messages, :to_sentence)
                                .and_return('Validation failed')
          end

          it 'returns error with validation messages' do
            result = service.execute

            expect(result).to be_error
            expect(result.message).to eq('Validation failed')
          end
        end

        context 'when unarchiving project fails without specific error messages' do
          before do
            allow(project).to receive(:update).with(archived: false).and_return(false)
            allow(project).to receive_message_chain(:errors, :full_messages, :to_sentence).and_return('')
          end

          it 'returns generic unarchiving failed error' do
            result = service.execute

            expect(result).to be_error
            expect(result.message).to eq('Failed to unarchive project.')
          end
        end

        context 'when unarchiving project succeeds' do
          let(:system_hook_service) { instance_double(SystemHooksService) }

          it 'returns success' do
            result = service.execute

            expect(result).to be_success
          end

          it 'updates the project archived status to false' do
            expect { service.execute }.to change { project.reload.archived }.from(true).to(false)
          end

          it 'executes system hooks' do
            allow(service).to receive(:system_hook_service).and_return(system_hook_service)

            expect(system_hook_service).to receive(:execute_hooks_for).with(project, :update)

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

          it 'publishes ProjectAttributesChangedEvent' do
            allow(service).to receive(:publish_project_archived_event)

            expect { service.execute }.to publish_event(Projects::ProjectAttributesChangedEvent)
              .with(
                project_id: project.id,
                namespace_id: project.namespace_id,
                root_namespace_id: project.root_namespace.id,
                attributes: %w[updated_at archived]
              )
          end
        end
      end
    end
  end
end
