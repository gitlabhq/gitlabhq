require 'spec_helper'

describe DiffDiscussion, model: true do
  subject { described_class.new([first_note, second_note, third_note]) }

  let(:first_note) { create(:diff_note_on_merge_request) }
  let(:second_note) { create(:diff_note_on_merge_request, in_reply_to: first_note) }
  let(:third_note) { create(:diff_note_on_merge_request, in_reply_to: first_note) }

  describe '#reply_attributes' do
    it 'includes position and original_position' do
      attributes = subject.reply_attributes
      expect(attributes[:position]).to eq(first_note.position.to_json)
      expect(attributes[:original_position]).to eq(first_note.original_position.to_json)
    end
  end

  describe "#truncated_diff_lines" do
    let(:truncated_lines) { subject.truncated_diff_lines }

    context "when diff is greater than allowed number of truncated diff lines " do
      it "returns fewer lines"  do
        expect(subject.diff_lines.count).to be > described_class::NUMBER_OF_TRUNCATED_DIFF_LINES

        expect(truncated_lines.count).to be <= described_class::NUMBER_OF_TRUNCATED_DIFF_LINES
      end
    end

    context "when some diff lines are meta" do
      it "returns no meta lines"  do
        expect(subject.diff_lines).to include(be_meta)
        expect(truncated_lines).not_to include(be_meta)
      end
    end
  end
end
