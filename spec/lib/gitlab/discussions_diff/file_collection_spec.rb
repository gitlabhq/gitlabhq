# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DiscussionsDiff::FileCollection, :clean_gitlab_redis_shared_state, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let!(:diff_note_a) { create(:diff_note_on_merge_request, project: merge_request.project, noteable: merge_request) }
  let!(:diff_note_b) { create(:diff_note_on_merge_request, project: merge_request.project, noteable: merge_request) }
  let(:note_diff_file_a) { diff_note_a.note_diff_file }
  let(:note_diff_file_b) { diff_note_b.note_diff_file }

  subject { described_class.new([note_diff_file_a, note_diff_file_b]) }

  describe '#load_highlight' do
    it 'only takes into account for the specific diff note ids' do
      file_a_caching_content = diff_note_a.diff_file.highlighted_diff_lines.map(&:to_hash)

      expect(Gitlab::DiscussionsDiff::HighlightCache)
        .to receive(:write_multiple)
        .with({ note_diff_file_a.id => file_a_caching_content })
        .and_call_original

      subject.load_highlight(diff_note_ids: [note_diff_file_a.diff_note_id])
    end

    it 'writes uncached diffs highlight' do
      file_a_caching_content = diff_note_a.diff_file.highlighted_diff_lines.map(&:to_hash)
      file_b_caching_content = diff_note_b.diff_file.highlighted_diff_lines.map(&:to_hash)

      expect(Gitlab::DiscussionsDiff::HighlightCache)
        .to receive(:write_multiple)
        .with({ note_diff_file_a.id => file_a_caching_content,
                note_diff_file_b.id => file_b_caching_content })
        .and_call_original

      subject.load_highlight
    end

    it 'does not write cache for already cached file' do
      file_a_caching_content = diff_note_a.diff_file.highlighted_diff_lines.map(&:to_hash)
      Gitlab::DiscussionsDiff::HighlightCache
        .write_multiple({ note_diff_file_a.id => file_a_caching_content })

      file_b_caching_content = diff_note_b.diff_file.highlighted_diff_lines.map(&:to_hash)

      expect(Gitlab::DiscussionsDiff::HighlightCache)
        .to receive(:write_multiple)
        .with({ note_diff_file_b.id => file_b_caching_content })
        .and_call_original

      subject.load_highlight
    end

    it 'does not write cache for empty mapping' do
      allow(subject).to receive(:highlighted_lines_by_ids).and_return([])

      expect(Gitlab::DiscussionsDiff::HighlightCache).not_to receive(:write_multiple)

      subject.load_highlight
    end

    it 'does not write cache for resolved notes' do
      diff_note_a.update_column(:resolved_at, Time.now)

      file_b_caching_content = diff_note_b.diff_file.highlighted_diff_lines.map(&:to_hash)

      expect(Gitlab::DiscussionsDiff::HighlightCache)
        .to receive(:write_multiple)
        .with({ note_diff_file_b.id => file_b_caching_content })
        .and_call_original

      subject.load_highlight
    end

    it 'loaded diff files have highlighted lines loaded' do
      subject.load_highlight

      diff_file_a = subject.find_by_id(note_diff_file_a.id)
      diff_file_b = subject.find_by_id(note_diff_file_b.id)

      expect(diff_file_a).to be_highlight_loaded
      expect(diff_file_b).to be_highlight_loaded
    end

    it 'not loaded diff files does not have highlighted lines loaded' do
      diff_note_a.update_column(:resolved_at, Time.now)

      subject.load_highlight

      diff_file_a = subject.find_by_id(note_diff_file_a.id)
      diff_file_b = subject.find_by_id(note_diff_file_b.id)

      expect(diff_file_a).not_to be_highlight_loaded
      expect(diff_file_b).to be_highlight_loaded
    end

    context 'when one of the note diff files cannot build a raw diff file' do
      # This mirrors the production case where a corrupt YAML position causes
      # NoteDiffFile#raw_diff_file to return nil. Such entries must be filtered
      # out so they cannot crash the discussions endpoint downstream.
      before do
        allow(note_diff_file_a).to receive(:raw_diff_file).and_return(nil)
      end

      it 'skips the nil entry without raising', :aggregate_failures do
        expect { subject.load_highlight }.not_to raise_error
        expect(subject.find_by_id(note_diff_file_a.id)).to be_nil
        expect(subject.find_by_id(note_diff_file_b.id)).not_to be_nil
      end
    end
  end
end
