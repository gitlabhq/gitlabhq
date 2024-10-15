# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::AbuseReport::UpdateService, feature_category: :insider_threat do
  let_it_be(:note) { create(:abuse_report_note, note: 'text') }
  let_it_be(:admin) { create(:admin) }

  let(:new_text) { 'Awesome comment' }
  let(:params) { { note: new_text } }
  let(:current_user) { admin }

  shared_examples 'no update of the note' do
    it 'returns an error response' do
      expect(update_note).not_to be_success
    end

    it 'does not update the note', :aggregate_failures do
      update_note

      expect(note.reload.note).to eq('text')
      expect(note.updated_by).not_to eq(admin)
      expect(note.last_edited_at).to be_nil
    end
  end

  describe '#execute', :enable_admin_mode do
    subject(:update_note) { described_class.new(current_user, params).execute(note) }

    context 'when user does not have permissions to update the note' do
      let(:current_user) { create(:user) }

      it 'raises an error' do
        expect { update_note }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'when user has permissions to update the note' do
      context 'with valid params' do
        it 'updates the note correctly', :aggregate_failures do
          update_note

          expect(note.reload.note).to eq(new_text)
          expect(note.updated_by).to eq(admin)
          expect(note.last_edited_at).to be > note.created_at
        end
      end

      context 'with missing params' do
        let(:params) { {} }

        it_behaves_like 'no update of the note'
      end

      context 'when new text is same as the old one' do
        let(:new_text) { 'text' }

        it_behaves_like 'no update of the note'
      end

      context 'when the note is invalid' do
        let(:new_text) { '' }

        it_behaves_like 'no update of the note'
      end
    end
  end
end
