# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Discussion do
  subject { described_class.new([first_note, second_note, third_note]) }

  let(:first_note) { create(:diff_note_on_merge_request) }
  let(:merge_request) { first_note.noteable }
  let(:second_note) { create(:diff_note_on_merge_request, in_reply_to: first_note) }
  let(:third_note) { create(:diff_note_on_merge_request) }

  describe '.lazy_find' do
    let!(:note1) { create(:discussion_note_on_merge_request).to_discussion }
    let!(:note2) { create(:discussion_note_on_merge_request, in_reply_to: note1).to_discussion }

    subject { [note1, note2].map { |note| described_class.lazy_find(note.discussion_id) } }

    it 'batches requests' do
      expect do
        [described_class.lazy_find(note1.id),
         described_class.lazy_find(note2.id)].map(&:__sync)
      end.not_to exceed_query_limit(1)
    end
  end

  describe '.build' do
    it 'returns a discussion of the right type' do
      discussion = described_class.build([first_note, second_note], merge_request)
      expect(discussion).to be_a(DiffDiscussion)
      expect(discussion.notes.count).to be(2)
      expect(discussion.first_note).to be(first_note)
      expect(discussion.noteable).to be(merge_request)
    end
  end

  describe '.build_collection' do
    it 'returns an array of discussions of the right type' do
      discussions = described_class.build_collection([first_note, second_note, third_note], merge_request)
      expect(discussions).to eq([
        DiffDiscussion.new([first_note, second_note], merge_request),
        DiffDiscussion.new([third_note], merge_request)
      ])
    end
  end

  describe 'authorization' do
    it 'delegates to the first note' do
      policy = DeclarativePolicy.policy_for(instance_double(User, id: 1), subject)

      expect(policy).to be_a(NotePolicy)
    end
  end
end
