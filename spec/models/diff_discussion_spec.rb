require 'spec_helper'

describe DiffDiscussion, model: true do
  subject { described_class.new([first_note, second_note, third_note]) }

  let(:first_note) { create(:diff_note_on_merge_request) }
  let(:merge_request) { first_note.noteable }
  let(:project) { first_note.project }
  let(:second_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project, in_reply_to: first_note) }
  let(:third_note) { create(:diff_note_on_merge_request, noteable: merge_request, project: project, in_reply_to: first_note) }

  describe '#reply_attributes' do
    it 'includes position and original_position' do
      attributes = subject.reply_attributes
      expect(attributes[:position]).to eq(first_note.position.to_json)
      expect(attributes[:original_position]).to eq(first_note.original_position.to_json)
    end
  end
end
