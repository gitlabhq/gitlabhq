require 'spec_helper'

describe DiscussionOnDiff do
  subject { create(:diff_note_on_merge_request).to_discussion }

  describe "#truncated_diff_lines" do
    let(:truncated_lines) { subject.truncated_diff_lines }

    context "when diff is greater than allowed number of truncated diff lines " do
      it "returns fewer lines"  do
        expect(subject.diff_lines.count).to be > DiffDiscussion::NUMBER_OF_TRUNCATED_DIFF_LINES

        expect(truncated_lines.count).to be <= DiffDiscussion::NUMBER_OF_TRUNCATED_DIFF_LINES
      end
    end

    context "when some diff lines are meta" do
      it "returns no meta lines"  do
        expect(subject.diff_lines).to include(be_meta)
        expect(truncated_lines).not_to include(be_meta)
      end
    end

    context "when the diff line does not exist on a legacy diff note" do
      it "returns an empty array" do
        legacy_note = LegacyDiffNote.new

        allow(subject).to receive(:first_note).and_return(legacy_note)

        expect(truncated_lines).to eq([])
      end
    end
  end

  describe '#line_code_in_diffs' do
    context 'when the discussion is active in the diff' do
      let(:diff_refs) { subject.position.diff_refs }

      it 'returns the current line code' do
        expect(subject.line_code_in_diffs(diff_refs)).to eq(subject.line_code)
      end
    end

    context 'when the discussion was created in the diff' do
      let(:diff_refs) { subject.original_position.diff_refs }

      it 'returns the original line code' do
        expect(subject.line_code_in_diffs(diff_refs)).to eq(subject.original_line_code)
      end
    end

    context 'when the discussion is unrelated to the diff' do
      let(:diff_refs) { subject.project.commit(RepoHelpers.sample_commit.id).diff_refs }

      it 'returns nil' do
        expect(subject.line_code_in_diffs(diff_refs)).to be_nil
      end
    end
  end
end
