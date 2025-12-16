# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::NoteMetadata, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe 'associations' do
    it { is_expected.to belong_to(:note) }
  end

  it_behaves_like 'model with associated note' do
    let_it_be(:note) { create(:note, project: project) }
    let_it_be(:record_attrs) { { email_participant: 'email@example.com', note_id: note.id } }
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

    context 'with before_validation :ensure_namespace_id' do
      context 'when there is no namespace_id on the note' do
        subject(:note_metadata) { described_class.new({ email_participant: 'email@example.com', note: note }) }

        shared_examples 'sets the namespace_id from the noteable' do
          before do
            note.update_column(:namespace_id, nil)
          end

          it 'sets namespace_id from noteable' do
            expect(note_metadata).to receive(:ensure_namespace_id).and_call_original

            note_metadata.save!
            expect(note.namespace_id).to be_nil
            expect(note_metadata.reload.namespace_id).not_to be_nil
            expect(note_metadata.namespace_id).to eq(expected_namespace_id)
          end
        end

        shared_examples 'does not set namespace_id' do
          it 'does not set namespace_id' do
            expect(note_metadata).to receive(:ensure_namespace_id).and_call_original

            expect(note_metadata.namespace_id).to be_nil
            expect(note_metadata).to be_invalid
          end
        end

        context 'when noteable belongs to a group' do
          context 'when note has a noteable' do
            let_it_be(:noteable) { create(:issue, :group_level, namespace: group) }
            let_it_be(:note) { create(:note, noteable: noteable) }

            let(:expected_namespace_id) { group.id }

            it_behaves_like 'sets the namespace_id from the noteable'
          end

          context 'when note does not have a noteable' do
            let_it_be(:note) { build(:note, noteable: nil, namespace_id: nil, noteable_type: 'Issue') }

            it_behaves_like 'does not set namespace_id'
          end
        end

        context 'when noteable belongs to a project' do
          let_it_be(:noteable) { create(:merge_request, source_project: project) }

          context 'when note has a project' do
            let_it_be(:note) { create(:note, noteable: noteable, project: project) }

            let(:expected_namespace_id) { project.project_namespace_id }

            it_behaves_like 'sets the namespace_id from the noteable'
          end

          context 'when note does not have a project' do
            let_it_be(:note) { build(:note, noteable: noteable, project: nil, namespace_id: nil) }

            it_behaves_like 'does not set namespace_id'
          end
        end

        context "when noteable doesn't have a namespace" do
          let_it_be(:noteable) { create(:personal_snippet) }
          let_it_be(:note) { build(:note, noteable: noteable, namespace_id: nil) }

          it_behaves_like 'does not set namespace_id'
        end
      end
    end
  end

  describe 'ensure sharding key is set' do
    let_it_be(:note) { create(:note, project: project) }

    it 'inherits the sharding key from the note' do
      note_metadata = create(:note_metadata, note: note)

      expect(note_metadata.reload.namespace_id).to eq(note.namespace_id)
    end

    context 'when note namespace_id is not set' do
      before do
        note.update_column(:namespace_id, nil)
      end

      it 'sets namespace_id to the project namespace_id' do
        note_metadata = create(:note_metadata, note: note)

        expect(note_metadata.reload.namespace_id).to eq(project.project_namespace_id)
      end
    end
  end
end
