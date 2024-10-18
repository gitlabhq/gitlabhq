# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::MergeRequestSuggestion, feature_category: :vulnerability_management do
  describe '.note_attributes_hash' do
    let_it_be(:fixtures_folder) { Rails.root.join('spec/fixtures/lib/gitlab/diff/merge_request_suggestion') }
    let_it_be(:filepath) { 'cwe-23.rb' }

    let_it_be(:merge_request_diff) { create(:merge_request_diff) }
    let_it_be(:merge_request_diff_file) do
      create(:merge_request_diff_file,
        merge_request_diff: merge_request_diff,
        new_file: false,
        a_mode: 100644,
        b_mode: 100644,
        new_path: filepath,
        old_path: filepath,
        diff: File.read(File.join(fixtures_folder, 'merge_request.diff'))
      )
    end

    let_it_be(:merge_request) do
      create(:merge_request, merge_request_diffs: [merge_request_diff], latest_merge_request_diff: merge_request_diff)
    end

    let_it_be(:diff) { File.read(File.join(fixtures_folder, 'input.diff')) }
    let(:mr_suggestion) { described_class.new(diff, filepath, merge_request) }

    subject(:attributes_hash) { mr_suggestion.note_attributes_hash }

    before do
      merge_request.reload
    end

    context 'when a valid diff is supplied' do
      it 'returns a correctly formatted suggestion request payload' do
        position_payload = {
          position_type: 'text',
          old_path: filepath,
          new_path: filepath,
          base_sha: merge_request.latest_merge_request_diff.base_commit_sha,
          head_sha: merge_request.latest_merge_request_diff.head_commit_sha,
          start_sha: merge_request.latest_merge_request_diff.start_commit_sha,
          old_line: 10,
          new_line: 8,
          ignore_whitespace_change: false
        }

        expect(attributes_hash[:type]).to eq('DiffNote')
        expect(attributes_hash[:noteable_type]).to eq(MergeRequest)
        expect(attributes_hash[:noteable_id]).to eq(merge_request.id)
        expect(attributes_hash[:position]).to eq(position_payload)
        expect(attributes_hash[:note]).to eq(File.read(File.join(fixtures_folder, 'suggestion.md')))
      end
    end

    context 'when the filepath does not match the diff' do
      let_it_be(:filepath) { 'cwe-123.rb' }

      it 'raises an error' do
        expect { attributes_hash }.to raise_exception(described_class::TargetLineNotFound)
      end
    end

    context 'when suggestion_target_line is nil' do
      it 'raises an error' do
        expect(mr_suggestion).to receive(:suggestion_target_line).and_return(nil)
        expect { attributes_hash }.to raise_exception(described_class::TargetLineNotFound)
      end
    end
  end
end
