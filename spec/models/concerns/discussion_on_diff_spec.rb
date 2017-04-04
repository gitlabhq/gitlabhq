require 'spec_helper'

describe DiffDiscussion, DiscussionOnDiff, model: true do
  subject { create(:diff_note_on_merge_request).to_discussion }

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
