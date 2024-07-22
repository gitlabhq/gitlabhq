# frozen_string_literal: true

RSpec.shared_examples 'Notes::Discussion' do
  describe '#start_of_discussion?' do
    it 'returns true when note is the start of a discussion' do
      expect(discussion_note).to be_start_of_discussion
    end

    it 'returns false when note is a reply' do
      expect(discussion_reply).not_to be_start_of_discussion
    end
  end

  describe '.find_discussion' do
    let_it_be(:noteable) { discussion_note.noteable }

    it 'returns a discussion with multiple notes' do
      discussion = noteable.notes.find_discussion(discussion_note.discussion_id)

      expect(discussion).not_to be_nil
      expect(discussion.notes).to match_array([discussion_note, discussion_reply])
      expect(discussion.first_note.discussion_id).to eq(discussion_note.discussion_id)
    end
  end

  describe '#discussion_id' do
    context 'when it is newly created' do
      it 'has a discussion id' do
        expect(discussion_note.discussion_id).not_to be_nil
        expect(discussion_note.discussion_id).to match(/\A\h{40}\z/)
      end
    end

    context "when it didn't store a discussion id before" do
      before do
        discussion_note.update_column(:discussion_id, nil)
      end

      it 'has a discussion id' do
        # The discussion_id is set in `after_initialize`, so `reload` won't work
        reloaded_note = described_class.find(discussion_note.id)

        expect(reloaded_note.discussion_id).not_to be_nil
        expect(reloaded_note.discussion_id).to match(/\A\h{40}\z/)
      end
    end
  end

  describe '#to_discussion' do
    it 'returns a discussion with just this note' do
      discussion = discussion_note.to_discussion

      expect(discussion.id).to eq(discussion_note.discussion_id)
      expect(discussion.notes).to eq([discussion_note])
    end
  end

  describe '#discussion' do
    context 'when the note is part of a discussion' do
      subject { discussion_reply }

      it 'returns the discussion this note is in' do
        discussion = subject.discussion

        expect(discussion.id).to eq(subject.discussion_id)
        expect(discussion.notes).to eq([discussion_note, subject])
      end
    end

    context 'when the note is not part of a discussion' do
      subject { create(factory) } # rubocop:disable Rails/SaveBang -- create used as factory method

      it 'returns a discussion with just this note' do
        discussion = subject.discussion

        expect(discussion.id).to eq(subject.discussion_id)
        expect(discussion.notes).to eq([subject])
      end
    end
  end

  describe '#part_of_discussion?' do
    context 'for a regular note' do
      it 'returns false' do
        expect(note1.part_of_discussion?).to be_falsey
      end
    end

    context 'for a discussion note' do
      it 'returns true' do
        expect(discussion_note.part_of_discussion?).to be_truthy
      end
    end
  end

  describe '#in_reply_to?' do
    context 'for a note' do
      context 'when part of a discussion' do
        it 'checks if the note is in reply to the other discussion' do
          expect(discussion_note).to receive(:in_reply_to?).with(discussion_reply).and_call_original
          expect(discussion_note).to receive(:in_reply_to?).with(discussion_reply.noteable).and_call_original
          expect(discussion_note).to receive(:in_reply_to?).with(discussion_reply.to_discussion).and_call_original

          discussion_note.in_reply_to?(discussion_reply)
        end
      end

      context 'when not part of a discussion' do
        let(:reply) { create(factory, in_reply_to: note1) }

        it 'checks if the note is in reply to the other noteable' do
          expect(note1).to receive(:in_reply_to?).with(reply).and_call_original
          expect(note1).to receive(:in_reply_to?).with(reply.noteable).and_call_original

          note1.in_reply_to?(reply)
        end
      end
    end

    context 'for a discussion' do
      context 'when part of the same discussion' do
        it 'returns true' do
          expect(discussion_note.in_reply_to?(discussion_reply.to_discussion)).to be_truthy
        end
      end

      context 'when not part of the same discussion' do
        # rubocop: disable Rails/SaveBang -- creation using factory
        let(:reply) { create(discussion_factory) }
        # rubocop: enable Rails/SaveBang

        it 'returns false' do
          expect(discussion_note.in_reply_to?(reply.to_discussion)).to be_falsey
        end
      end
    end

    context 'for a noteable' do
      context 'when a comment on the same noteable' do
        it 'returns true' do
          expect(note1.in_reply_to?(reply.noteable)).to be_truthy
        end
      end

      context 'when not a comment on the same noteable' do
        it 'returns false' do
          expect(note1.in_reply_to?(note2.noteable)).to be_falsey
        end
      end
    end

    context 'for a different entity' do
      let(:user) { create(:user) }

      it 'returns false' do
        expect(note1.in_reply_to?(user)).to be_falsey
      end
    end
  end
end
