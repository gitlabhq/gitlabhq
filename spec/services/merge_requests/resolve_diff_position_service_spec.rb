# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::ResolveDiffPositionService, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, target_project: project) }

  let(:diff_file) { merge_request.merge_request_diff.merge_request_diff_files.first }
  let(:file_path) { diff_file.new_path }
  let(:new_line) { 1 }
  let(:old_line) { nil }

  let(:head_sha) { merge_request.diff_refs.head_sha }

  let(:params) do
    {
      merge_request: merge_request,
      file_path: file_path,
      new_line: new_line,
      old_line: old_line,
      head_sha: head_sha
    }
  end

  subject(:result) { described_class.new(project, user, params).execute }

  describe '#execute' do
    it 'returns a successful response with resolved position' do
      expect(result).to be_success

      position = result.payload[:position]
      diff_refs = merge_request.diff_refs

      expect(position[:base_sha]).to eq(diff_refs.base_sha)
      expect(position[:start_sha]).to eq(diff_refs.start_sha)
      expect(position[:head_sha]).to eq(diff_refs.head_sha)
      expect(position[:new_path]).to eq(diff_file.new_path)
      expect(position[:old_path]).to eq(diff_file.old_path)
      expect(position[:position_type]).to eq('text')
      expect(position[:new_line]).to eq(1)
      expect(position[:old_line]).to be_nil
    end

    context 'when old_line is provided instead of new_line' do
      let(:new_line) { nil }
      let(:old_line) { 5 }

      it 'includes old_line in the position' do
        expect(result).to be_success
        expect(result.payload[:position][:old_line]).to eq(5)
        expect(result.payload[:position][:new_line]).to be_nil
      end
    end

    context 'when both old_line and new_line are provided' do
      let(:new_line) { 1 }
      let(:old_line) { 1 }

      it 'includes both lines in the position' do
        expect(result).to be_success
        expect(result.payload[:position][:old_line]).to eq(1)
        expect(result.payload[:position][:new_line]).to eq(1)
      end
    end

    context 'when file_path does not exist in the diff' do
      let(:file_path) { 'nonexistent/file.rb' }

      it 'returns an error' do
        expect(result).to be_error
        expect(result.message).to include('File not found in merge request diff')
      end
    end

    context 'when merge request has no diff refs' do
      let(:head_sha) { 'any_sha' }

      before do
        allow(merge_request).to receive(:diff_refs).and_return(nil)
      end

      it 'returns an error' do
        expect(result).to be_error
        expect(result.message).to include('Could not determine diff refs')
      end
    end

    context 'when file was renamed' do
      let(:file_path) { 'files/js/commit.coffee' }

      it 'resolves both old and new paths' do
        expect(result).to be_success

        position = result.payload[:position]
        expect(position[:new_path]).to eq('files/js/commit.coffee')
        expect(position[:old_path]).to eq('files/js/commit.js.coffee')
      end
    end

    context 'when looking up a renamed file by its old path' do
      let(:file_path) { 'files/js/commit.js.coffee' }

      it 'resolves the file from the old path' do
        expect(result).to be_success

        position = result.payload[:position]
        expect(position[:old_path]).to eq('files/js/commit.js.coffee')
        expect(position[:new_path]).to eq('files/js/commit.coffee')
      end
    end

    context 'when file was modified' do
      let(:file_path) { 'files/ruby/regex.rb' }

      it 'resolves the position with matching old and new paths' do
        expect(result).to be_success

        position = result.payload[:position]
        expect(position[:old_path]).to eq('files/ruby/regex.rb')
        expect(position[:new_path]).to eq('files/ruby/regex.rb')
      end
    end

    context 'when merge request has no merge_request_diff' do
      let(:file_path) { 'some/file.rb' }

      before do
        diff_refs = merge_request.diff_refs
        allow(merge_request).to receive_messages(diff_refs: diff_refs, merge_request_diff: nil)
      end

      it 'returns an error' do
        expect(result).to be_error
        expect(result.message).to include('File not found in merge request diff')
      end
    end

    context 'when head_sha does not match the current diff' do
      let(:head_sha) { 'stale_sha_from_outdated_diff' }

      it 'returns an error' do
        expect(result).to be_error
        expect(result.message).to include('does not match the current merge request diff')
      end
    end
  end
end
