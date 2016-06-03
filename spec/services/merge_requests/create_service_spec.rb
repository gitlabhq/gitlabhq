require 'spec_helper'

describe MergeRequests::CreateService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:assignee) { create(:user) }

  describe :execute do
    context 'valid params' do
      let(:opts) do
        {
          title: 'Awesome merge_request',
          description: 'please fix',
          source_branch: 'feature',
          target_branch: 'master'
        }
      end

      let(:service) { MergeRequests::CreateService.new(project, user, opts) }

      before do
        project.team << [user, :master]
        project.team << [assignee, :developer]
        allow(service).to receive(:execute_hooks)

        @merge_request = service.execute
      end

      it { expect(@merge_request).to be_valid }
      it { expect(@merge_request.title).to eq('Awesome merge_request') }
      it { expect(@merge_request.assignee).to be_nil }

      it 'should execute hooks with default action' do
        expect(service).to have_received(:execute_hooks).with(@merge_request)
      end

      it 'does not creates todos' do
        attributes = {
          project: project,
          target_id: @merge_request.id,
          target_type: @merge_request.class.name
        }

        expect(Todo.where(attributes).count).to be_zero
      end

      context 'when merge request is assigned to someone' do
        let(:opts) do
          {
            title: 'Awesome merge_request',
            description: 'please fix',
            source_branch: 'feature',
            target_branch: 'master',
            assignee: assignee
          }
        end

        it { expect(@merge_request.assignee).to eq assignee }

        it 'creates a todo for new assignee' do
          attributes = {
            project: project,
            author: user,
            user: assignee,
            target_id: @merge_request.id,
            target_type: @merge_request.class.name,
            action: Todo::ASSIGNED,
            state: :pending
          }

          expect(Todo.where(attributes).count).to eq 1
        end
      end
    end
  end
end
