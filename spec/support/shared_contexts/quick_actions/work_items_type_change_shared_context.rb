# frozen_string_literal: true

RSpec.shared_context 'with work item change type context' do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let(:new_type) { 'Task' }
  let(:with_access) { true }

  before do
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(current_user, :"create_#{new_type.downcase}", work_item)
      .and_return(with_access)
  end

  shared_examples 'quick command error' do |error_reason, action = 'convert'|
    let(:error) { format("Failed to %{action} this work item: %{reason}.", action: action, reason: error_reason) }

    it 'returns error' do
      _, updates, message = service.execute(command, work_item)

      expect(message).to eq(error)
      expect(updates).to eq({})
    end
  end
end
