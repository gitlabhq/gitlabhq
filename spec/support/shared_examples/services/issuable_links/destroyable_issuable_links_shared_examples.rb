# frozen_string_literal: true

RSpec.shared_examples 'a destroyable issuable link' do
  context 'when successfully removes an issuable link' do
    it 'removes related issue' do
      expect { subject }.to change { issuable_link.class.count }.by(-1)
    end

    it 'creates notes' do
      # Two-way notes creation
      expect(SystemNoteService).to receive(:unrelate_issuable)
                                     .with(issuable_link.source, issuable_link.target, user)
      expect(SystemNoteService).to receive(:unrelate_issuable)
                                     .with(issuable_link.target, issuable_link.source, user)

      subject
    end

    it 'returns success message' do
      is_expected.to eq(message: 'Relation was removed', status: :success)
    end
  end

  context 'when failing to remove an issuable link' do
    let_it_be(:non_member) { create(:user) }
    let(:user) { non_member }

    it 'does not remove relation' do
      expect { subject }.not_to change { issuable_link.class.count }.from(1)
    end

    it 'does not create notes' do
      expect(SystemNoteService).not_to receive(:unrelate_issuable)
    end

    it 'returns error message' do
      is_expected.to eq(message: "No #{issuable_link.class.model_name.human.titleize} found", status: :error, http_status: 404)
    end
  end
end
