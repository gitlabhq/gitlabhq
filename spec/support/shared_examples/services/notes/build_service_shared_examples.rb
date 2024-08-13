# frozen_string_literal: true

RSpec.shared_examples_for 'building notes replying to another note' do
  let(:params) { { in_reply_to_discussion_id: note.discussion_id } }

  context 'when a note with that original discussion ID exists' do
    it 'sets the note up to be in reply to that note' do
      expect(new_note).to be_valid
      expect(new_note.in_reply_to?(note)).to be_truthy
      expect(new_note.resolved?).to be_falsey
    end
  end

  context 'when no note with that discussion ID exists' do
    let(:params) { { in_reply_to_discussion_id: non_existing_record_id } }

    it 'sets an error' do
      expect(new_note.errors[:base]).to include('Discussion to reply to cannot be found')
    end
  end

  context 'when user has no access to discussion' do
    let(:user) { other_user }

    it 'sets an error' do
      expect(new_note.errors[:base]).to include('Discussion to reply to cannot be found')
    end

    context 'when executing_user is specified' do
      context 'and executing_user has access to discussion' do
        let(:executing_user) { author }

        it 'sets the note up to be in reply to that note' do
          expect(new_note).to be_valid
          expect(new_note.in_reply_to?(note)).to be_truthy
        end
      end

      context 'and executing_user also has no access to discussion' do
        let(:executing_user) { other_user }

        it 'sets an error' do
          expect(new_note.errors[:base]).to include('Discussion to reply to cannot be found')
        end
      end
    end
  end

  context 'when replying to individual note' do
    let(:params) { { in_reply_to_discussion_id: individual_note.discussion_id } }

    it 'sets the note up to be in reply to that note' do
      expect(new_note).to be_valid
      expect(new_note).to be_a(discussion_class)
      expect(new_note.discussion_id).to eq(individual_note.discussion_id)
    end
  end
end
