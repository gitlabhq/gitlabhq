# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::NoteMetadata, feature_category: :team_planning do
  describe 'associations' do
    it { is_expected.to belong_to(:note) }
  end

  describe 'callbacks' do
    let_it_be(:note) { create(:note) }
    let_it_be(:email) { "#{'a' * 255}@example.com" }

    context 'with before_save :ensure_email_participant_length' do
      let(:note_metadata) { create(:note_metadata, note: note, email_participant: email) }

      context 'when email length is > 255' do
        let(:expected_email) { "#{'a' * 252}..." }

        it 'rewrites the email within max length' do
          expect(note_metadata.email_participant.length).to eq(255)
          expect(note.note_metadata.email_participant).to eq(expected_email)
        end
      end

      context 'when email is within permissible length' do
        let(:email) { 'email@example.com' }

        it 'saves the email as-is' do
          expect(note_metadata.email_participant).to eq(email)
        end
      end
    end
  end
end
