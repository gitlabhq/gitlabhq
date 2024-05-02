# frozen_string_literal: true

RSpec.shared_examples 'quick actions that change work item type' do
  include_context 'with work item change type context'

  describe 'type command' do
    let(:command) { "/type #{new_type}" }

    it 'populates :issue_type: and :work_item_type' do
      _, updates, message = service.execute(command, work_item)

      expect(message).to eq(_('Type changed successfully.'))
      expect(updates).to eq({ issue_type: 'task', work_item_type: WorkItems::Type.default_by_type(:task) })
    end

    context 'when new type is invalid' do
      let(:command) { '/type foo' }

      it_behaves_like 'quick command error', 'Provided type is not supported'
    end

    context 'when new type is the same as current type' do
      let(:command) { '/type issue' }

      it_behaves_like 'quick command error', 'Types are the same'
    end

    context 'when user has insufficient permissions to create new type' do
      let(:with_access) { false }

      it_behaves_like 'quick command error', 'You have insufficient permissions'
    end
  end

  describe 'promote_to command' do
    let(:new_type) { 'issue' }
    let(:command) { "/promote_to #{new_type}" }

    shared_examples 'action with validation errors' do
      context 'when user has insufficient permissions to create new type' do
        let(:with_access) { false }

        it_behaves_like 'quick command error', 'You have insufficient permissions', 'promote'
      end

      context 'when new type is not supported' do
        let(:new_type) { unsupported_type }

        it_behaves_like 'quick command error', 'Provided type is not supported', 'promote'
      end
    end

    context 'with issue' do
      let(:new_type) { 'incident' }
      let(:unsupported_type) { 'task' }

      it 'populates :issue_type: and :work_item_type' do
        _, updates, message = service.execute(command, work_item)

        expect(message).to eq(_('Promoted successfully.'))
        expect(updates).to eq({ issue_type: 'incident', work_item_type: WorkItems::Type.default_by_type(:incident) })
      end

      it_behaves_like 'action with validation errors'
    end

    context 'with task' do
      let_it_be_with_reload(:task) { create(:work_item, :task, project: project) }
      let(:work_item) { task }
      let(:new_type) { 'issue' }
      let(:unsupported_type) { 'incident' }

      it 'populates :issue_type: and :work_item_type' do
        _, updates, message = service.execute(command, work_item)

        expect(message).to eq(_('Promoted successfully.'))
        expect(updates).to eq({ issue_type: 'issue', work_item_type: WorkItems::Type.default_by_type(:issue) })
      end

      it_behaves_like 'action with validation errors'
    end
  end
end
