require 'spec_helper'

describe Notes::BuildService, services: true do
  let(:note) { create(:discussion_note_on_issue) }
  let(:project) { note.project }
  let(:author) { note.author }

  describe '#execute' do
    context 'when in_reply_to_discussion_id is specified' do
      context 'when a note with that original discussion ID exists' do
        it 'sets the note up to be in reply to that note' do
          new_note = described_class.new(project, author, note: 'Test', in_reply_to_discussion_id: note.discussion_id).execute
          expect(new_note).to be_valid
          expect(new_note.in_reply_to?(note)).to be_truthy
        end
      end

      context 'when a note with that discussion ID exists' do
        it 'sets the note up to be in reply to that note' do
          new_note = described_class.new(project, author, note: 'Test', in_reply_to_discussion_id: note.discussion_id).execute
          expect(new_note).to be_valid
          expect(new_note.in_reply_to?(note)).to be_truthy
        end
      end

      context 'when no note with that discussion ID exists' do
        it 'sets an error' do
          new_note = described_class.new(project, author, note: 'Test', in_reply_to_discussion_id: 'foo').execute
          expect(new_note.errors[:base]).to include('Discussion to reply to cannot be found')
        end
      end
    end

    it 'builds a note without saving it' do
      new_note = described_class.new(project, author, noteable_type: note.noteable_type, noteable_id: note.noteable_id, note: 'Test').execute
      expect(new_note).to be_valid
      expect(new_note).not_to be_persisted
    end
  end
end
