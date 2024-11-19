# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiscussionOnDiff do
  subject { create(:diff_note_on_merge_request, line_number: 18).to_discussion }

  describe "#truncated_diff_lines" do
    let(:truncated_lines) { subject.truncated_diff_lines }

    context "when diff is greater than allowed number of truncated diff lines " do
      it "returns fewer lines" do
        expect(subject.diff_lines.count).to be > DiffDiscussion::NUMBER_OF_TRUNCATED_DIFF_LINES

        expect(truncated_lines.count).to be <= DiffDiscussion::NUMBER_OF_TRUNCATED_DIFF_LINES
      end

      context 'with truncated diff lines diff limit set' do
        let(:truncated_lines) do
          subject.truncated_diff_lines(
            diff_limit: diff_limit
          )
        end

        context 'when diff limit is higher than default' do
          let(:diff_limit) { DiffDiscussion::NUMBER_OF_TRUNCATED_DIFF_LINES + 1 }

          it 'returns fewer lines than the default' do
            expect(subject.diff_lines.count).to be >= diff_limit

            expect(truncated_lines.count).to be <= DiffDiscussion::NUMBER_OF_TRUNCATED_DIFF_LINES
          end
        end

        context 'when diff_limit is lower than default' do
          let(:diff_limit) { 3 }

          it 'returns fewer lines than the default' do
            expect(subject.diff_lines.count).to be > DiffDiscussion::NUMBER_OF_TRUNCATED_DIFF_LINES

            expect(truncated_lines.count).to be <= diff_limit
          end
        end
      end
    end

    context "when some diff lines are meta" do
      it "returns no meta lines"  do
        expect(subject.diff_lines).to include(be_meta)
        expect(truncated_lines).not_to include(be_meta)
      end
    end

    context "when the diff line does not exist on a legacy diff note" do
      subject { create(:legacy_diff_note_on_merge_request).to_discussion }

      it "returns an empty array" do
        expect(truncated_lines).to eq([])
      end
    end

    context "when the diff line does not exist on a corrupt diff note" do
      subject { create(:diff_note_on_merge_request, line_number: 18).to_discussion }

      before do
        allow(subject).to receive(:diff_line) { nil }
      end

      it "returns an empty array" do
        expect(truncated_lines).to eq([])
      end
    end

    context 'when the discussion is on an image' do
      subject { create(:image_diff_note_on_merge_request).to_discussion }

      it 'returns an empty array' do
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
