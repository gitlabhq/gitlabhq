require 'spec_helper'

describe Discussion do
  subject { described_class.new([first_note, second_note, third_note]) }

  let(:first_note) { create(:diff_note_on_merge_request) }
  let(:merge_request) { first_note.noteable }
  let(:second_note) { create(:diff_note_on_merge_request, in_reply_to: first_note) }
  let(:third_note) { create(:diff_note_on_merge_request) }

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
end
