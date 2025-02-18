# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckLfsFileLocksService, feature_category: :code_review_workflow do
  subject(:check_lfs_file_locks) { described_class.new(merge_request: merge_request, params: params) }

  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request) { build(:merge_request, source_project: project) }
  let(:params) { { skip_locked_lfs_files_check: skip_check } }
  let(:skip_check) { false }
  let(:lfs_enabled) { true }

  before do
    allow(project).to receive(:lfs_enabled?).and_return(lfs_enabled)
  end

  it_behaves_like 'mergeability check service', :locked_lfs_files, <<~DESC.chomp
    Checks whether the merge request contains locked LFS files that are locked by users other than the merge request author
  DESC

  describe '#execute' do
    subject(:execute) { check_lfs_file_locks.execute }

    context 'when lfs is enabled' do
      let(:only_allow_merge_if_pipeline_succeeds) { true }
      let(:changed_paths) do
        [
          instance_double('Gitlab::Git::ChangedPath', path: 'README.md'),
          instance_double('Gitlab::Git::ChangedPath', path: 'conflict.rb'),
          instance_double('Gitlab::Git::ChangedPath', path: 'README.md')
        ]
      end

      before do
        allow(merge_request).to receive(:changed_paths).and_return(changed_paths)
        allow(project.lfs_file_locks).to receive(:exists?).and_call_original
        allow(project.lfs_file_locks).to receive(:for_paths).and_call_original
      end

      context 'when there are no lfs files locks for this project' do
        it 'returns a check result with status success' do
          expect(execute.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
        end

        it 'returns early before querying for matching file locks' do
          execute
          expect(project.lfs_file_locks).to have_received(:exists?)
          expect(project.lfs_file_locks).not_to have_received(:for_paths)
        end
      end

      context 'when there are lfs files locked by the merge request author' do
        before do
          create(:lfs_file_lock, project: project, path: changed_paths.first.path, user: merge_request.author)
        end

        it 'returns a check result with status success' do
          expect(execute.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS
        end

        it 'deduplicates the changed paths' do
          execute
          expect(project.lfs_file_locks).to have_received(:exists?)
          expect(project.lfs_file_locks).to have_received(:for_paths).with(changed_paths.map(&:path).uniq)
        end
      end

      context 'when there are lfs files locked by another user' do
        before do
          allow(merge_request).to receive(:author_id).and_return(0)
          create(:lfs_file_lock, project: project, path: changed_paths.second.path)
        end

        it 'returns a check result with status failure' do
          expect(execute.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS
        end

        it 'deduplicates the changed paths' do
          execute
          expect(project.lfs_file_locks).to have_received(:exists?)
          expect(project.lfs_file_locks).to have_received(:for_paths).with(changed_paths.map(&:path).uniq)
        end
      end
    end

    context 'when lfs is not enabled' do
      let(:lfs_enabled) { false }

      it 'returns a check result with inactive status' do
        expect(execute.status).to eq Gitlab::MergeRequests::Mergeability::CheckResult::INACTIVE_STATUS
      end
    end
  end

  describe '#skip?' do
    subject(:skip) { check_lfs_file_locks.skip? }

    context 'when skip check is true' do
      let(:skip_check) { true }

      it { expect(skip).to eq(true) }
    end

    context 'when skip check is false' do
      let(:skip_check) { false }

      it { expect(skip).to eq(false) }
    end
  end

  describe '#cacheable?' do
    subject(:cacheable) { check_lfs_file_locks.cacheable? }

    it { expect(cacheable).to eq(true) }
  end

  describe '#cache_key' do
    subject(:cache_key) { check_lfs_file_locks.cache_key }

    context 'when the feature flag is enabled' do
      let(:id) { 'id' }
      let(:sha) { 'sha' }
      let(:epoch) { 'epoch' }
      let(:expected_cache_key) { format(described_class::CACHE_KEY, id: id, sha: sha, epoch: epoch) }

      before do
        allow(merge_request).to receive(:id).and_return(id)
        allow(merge_request).to receive(:diff_head_sha).and_return(sha)
        allow(project).to receive(:lfs_file_locks_changed_epoch).and_return(epoch)
      end

      it { expect(cache_key).to eq(expected_cache_key) }
    end

    context 'when lfs is disabled' do
      let(:lfs_enabled) { false }

      it { expect(cache_key).to eq('inactive_lfs_file_locks_mergeability_check') }
    end
  end
end
