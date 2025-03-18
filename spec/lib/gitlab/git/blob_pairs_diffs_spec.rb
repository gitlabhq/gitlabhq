# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::BlobPairsDiffs, feature_category: :source_code_management do
  let(:mock_container) { instance_double(Project) }
  let(:git_repository) { instance_double(Gitlab::Git::Repository) }
  let(:repository) { instance_double(Repository, container: mock_container, raw_repository: git_repository) }
  let(:blob_pairs_service) { described_class.new(repository) }

  let(:diff_blobs) do
    [
      instance_double(::Gitlab::GitalyClient::DiffBlob, patch: 'diff1', over_patch_bytes_limit: false),
      instance_double(::Gitlab::GitalyClient::DiffBlob, patch: 'diff2', over_patch_bytes_limit: false),
      instance_double(::Gitlab::GitalyClient::DiffBlob,
        patch: "- Subproject commit sub_old\n+ Subproject commit sub_new", over_patch_bytes_limit: false)
    ]
  end

  let(:diff_refs) do
    Gitlab::Diff::DiffRefs.new(
      base_sha: "913c66a37b4a45b9769037c55c2d238bd0942d2e",
      head_sha: "874797c3a73b60d2187ed6e2fcabd289ff75171e"
    )
  end

  let(:changed_paths) do
    [
      Gitlab::Git::ChangedPath.new(
        status: :ADDED, path: "added_file.rb", old_path: '', old_mode: "0", new_mode: "100644",
        old_blob_id: '0000000000000000000000000000000000000000', new_blob_id: '470ad2fcf1e33798f1afc5781d08e60c40f51e7a'
      ),
      Gitlab::Git::ChangedPath.new(
        status: :RENAMED, path: "renamed_file.rb", old_path: 'original_file.rb', old_mode: "100644", new_mode: "100644",
        old_blob_id: '93e123ac8a3e6a0b600953d7598af629dec7b735', new_blob_id: '50b27c6518be44c42c4d87966ae2481ce895624c'
      ),
      Gitlab::Git::ChangedPath.new(
        status: :MODIFIED, path: "submodule", old_path: 'submodule', old_mode: "160000", new_mode: "160000",
        old_blob_id: 'sub_old', new_blob_id: 'sub_new'
      )
    ]
  end

  before do
    allow(git_repository).to receive_messages(
      find_changed_paths: changed_paths,
      diff_blobs: diff_blobs
    )
  end

  describe '#diffs_by_changed_paths' do
    it 'fetches changed paths and processes them' do
      expect(git_repository).to receive(:find_changed_paths).with(
        array_including(an_instance_of(Gitlab::Git::DiffTree)),
        hash_including(find_renames: true)
      ).and_return(changed_paths)

      expect do
        blob_pairs_service.diffs_by_changed_paths(diff_refs) { |diff_files| diff_files }
      end.not_to raise_error
    end

    it 'creates correct diff files' do
      expect(git_repository).to receive(:diff_blobs).with(
        an_instance_of(Array),
        patch_bytes_limit: Gitlab::Git::Diff.patch_hard_limit_bytes
      ).and_return(diff_blobs)

      blob_pairs_service.diffs_by_changed_paths(diff_refs) do |diff_files|
        expect(diff_files.length).to eq(3)
        expect(diff_files[0].diff.diff).to eq('diff1')
        expect(diff_files[1].diff.diff).to eq('diff2')
        expect(diff_files[2].diff.diff).to include("- Subproject commit sub_old")
        expect(diff_files[2].diff.diff).to include("+ Subproject commit sub_new")
      end
    end

    context 'when an offset is given' do
      it 'returns only one diff file and batch' do
        diff_files = []
        blob_pairs_service.diffs_by_changed_paths(diff_refs, 2, 10) do |batch|
          diff_files << batch
        end

        expect(diff_files.length).to eq(1)
        expect(diff_files.first.length).to eq(1)
      end
    end

    context 'when submodule is deleted' do
      let(:changed_paths) do
        [
          Gitlab::Git::ChangedPath.new(
            status: :DELETED, path: "submodule", old_path: 'submodule', old_mode: "160000", new_mode: "0",
            old_blob_id: 'sub_old', new_blob_id: '0000000000000000000000000000000000000000'
          )
        ]
      end

      let(:diff_blobs) do
        [
          instance_double(::Gitlab::GitalyClient::DiffBlob, patch: "- Subproject commit sub_old",
            over_patch_bytes_limit: false)
        ]
      end

      before do
        allow(git_repository).to receive_messages(
          find_changed_paths: changed_paths,
          diff_blobs: diff_blobs
        )
      end

      it 'returns deleted submodule diffs' do
        diff_files = []

        blob_pairs_service.diffs_by_changed_paths(diff_refs) do |batch|
          diff_files << batch
        end

        submodule_diffs = diff_files.flatten.select { |f| f.new_path == 'submodule' }

        expect(submodule_diffs.count).to eq 1
        expect(submodule_diffs.first.diff.diff).to eq "- Subproject commit sub_old"
      end
    end
  end
end
