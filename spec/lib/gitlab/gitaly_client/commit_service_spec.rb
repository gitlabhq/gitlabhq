# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::CommitService, feature_category: :gitaly do
  let_it_be(:project) { create(:project, :repository) }

  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.disk_path + '.git' }
  let(:repository) { project.repository }
  let(:repository_message) { repository.gitaly_repository }
  let(:revision) { '913c66a37b4a45b9769037c55c2d238bd0942d2e' }
  let(:commit) { project.commit(revision) }
  let(:client) { described_class.new(repository) }

  describe '#diff_from_parent' do
    context 'when a commit has a parent' do
      it 'sends an RPC request with the parent ID as left commit' do
        request = Gitaly::CommitDiffRequest.new(
          repository: repository_message,
          left_commit_id: 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660',
          right_commit_id: commit.id,
          collapse_diffs: false,
          enforce_limits: true,
          # Tests limitation parameters explicitly
          max_files: 100,
          max_lines: 5000,
          max_bytes: 512000,
          safe_max_files: 100,
          safe_max_lines: 5000,
          safe_max_bytes: 512000,
          max_patch_bytes: 204800
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_diff).with(request, kind_of(Hash))

        client.diff_from_parent(commit)
      end
    end

    context 'when a commit does not have a parent' do
      it 'sends an RPC request with empty tree ref as left commit' do
        initial_commit = project.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863').raw
        request        = Gitaly::CommitDiffRequest.new(
          repository: repository_message,
          left_commit_id: Gitlab::Git::SHA1_EMPTY_TREE_ID,
          right_commit_id: initial_commit.id,
          collapse_diffs: false,
          enforce_limits: true,
          # Tests limitation parameters explicitly
          max_files: 100,
          max_lines: 5000,
          max_bytes: 512000,
          safe_max_files: 100,
          safe_max_lines: 5000,
          safe_max_bytes: 512000,
          max_patch_bytes: 204800
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_diff).with(request, kind_of(Hash))

        client.diff_from_parent(initial_commit)
      end
    end

    context 'when given a whitespace param' do
      context 'and the param is true' do
        it 'uses the ignore all white spaces const' do
          request = Gitaly::CommitDiffRequest.new

          expect(Gitaly::CommitDiffRequest).to receive(:new)
            .with(hash_including(whitespace_changes: Gitaly::CommitDiffRequest::WhitespaceChanges::WHITESPACE_CHANGES_IGNORE_ALL)).and_return(request)

          expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_diff).with(request, kind_of(Hash))

          client.diff_from_parent(commit, ignore_whitespace_change: true)
        end
      end

      context 'and the param is false' do
        it 'does not set a whitespace param' do
          request = Gitaly::CommitDiffRequest.new

          expect(Gitaly::CommitDiffRequest).to receive(:new)
            .with(hash_not_including(:whitespace_changes)).and_return(request)

          expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_diff).with(request, kind_of(Hash))

          client.diff_from_parent(commit, ignore_whitespace_change: false)
        end
      end
    end

    context 'when given no whitespace param' do
      it 'does not set a whitespace param' do
        request = Gitaly::CommitDiffRequest.new

        expect(Gitaly::CommitDiffRequest).to receive(:new)
          .with(hash_not_including(:whitespace_changes)).and_return(request)

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_diff).with(request, kind_of(Hash))

        client.diff_from_parent(commit)
      end
    end

    it 'returns a Gitlab::GitalyClient::DiffStitcher' do
      ret = client.diff_from_parent(commit)

      expect(ret).to be_kind_of(Gitlab::GitalyClient::DiffStitcher)
    end

    it 'encodes paths correctly' do
      expect { client.diff_from_parent(commit, paths: ['encoding/test.txt', 'encoding/テスト.txt', nil]) }.not_to raise_error
    end
  end

  describe '#commit_deltas' do
    context 'when a commit has a parent' do
      it 'sends an RPC request with the parent ID as left commit' do
        request = Gitaly::CommitDeltaRequest.new(
          repository: repository_message,
          left_commit_id: 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660',
          right_commit_id: commit.id
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_delta).with(request, kind_of(Hash)).and_return([])

        client.commit_deltas(commit)
      end
    end

    context 'when a commit does not have a parent' do
      it 'sends an RPC request with empty tree ref as left commit' do
        initial_commit = project.commit('1a0b36b3cdad1d2ee32457c102a8c0b7056fa863')
        request        = Gitaly::CommitDeltaRequest.new(
          repository: repository_message,
          left_commit_id: Gitlab::Git::SHA1_EMPTY_TREE_ID,
          right_commit_id: initial_commit.id
        )

        expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:commit_delta).with(request, kind_of(Hash)).and_return([])

        client.commit_deltas(initial_commit)
      end
    end
  end

  describe '#diff_stats' do
    let(:left_commit_id) { 'master' }
    let(:right_commit_id) { 'cfe32cf61b73a0d5e9f13e774abde7ff789b1660' }

    it 'sends an RPC request and returns the stats' do
      request = Gitaly::DiffStatsRequest.new(repository: repository_message,
        left_commit_id: left_commit_id,
        right_commit_id: right_commit_id)

      diff_stat_response = Gitaly::DiffStatsResponse.new(
        stats: [{ additions: 1, deletions: 2, path: 'test' }])

      expect_any_instance_of(Gitaly::DiffService::Stub).to receive(:diff_stats)
        .with(request, kind_of(Hash)).and_return([diff_stat_response])

      returned_value = described_class.new(repository).diff_stats(left_commit_id, right_commit_id)

      expect(returned_value).to eq(diff_stat_response.stats)
    end
  end

  describe '#find_changed_paths' do
    let(:mapped_merge_commit_diff_mode) { described_class::MERGE_COMMIT_DIFF_MODES[merge_commit_diff_mode] }
    let(:find_renames) { false }
    let(:commits) do
      %w[
        ade1c0b4b116209ed2a9958436b26f89085ec383
        594937c22df7a093888ff13af518f2b683f5f719
        760c58db5a6f3b64ad7e3ff6b3c4a009da7d9b33
        2b298117a741cdb06eb48df2c33f1390cf89f7e8
        c41e12c387b4e0e41bfc17208252d6a6430f2fcd
        1ada92f78a19f27cb442a0a205f1c451a3a15432
      ]
    end

    let(:requests) do
      commits.map do |commit|
        Gitaly::FindChangedPathsRequest::Request.new(
          commit_request: Gitaly::FindChangedPathsRequest::Request::CommitRequest.new(commit_revision: commit)
        )
      end
    end

    let(:request) do
      Gitaly::FindChangedPathsRequest.new(repository: repository_message, requests: requests, merge_commit_diff_mode: merge_commit_diff_mode)
    end

    let(:treeish_objects) { repository.commits_by(oids: commits) }

    subject { described_class.new(repository).find_changed_paths(treeish_objects, merge_commit_diff_mode: merge_commit_diff_mode).as_json }

    before do
      allow(Gitaly::FindChangedPathsRequest).to receive(:new).and_call_original
    end

    shared_examples 'includes paths different in any parent' do
      let(:changed_paths) do
        [
          {
            path: 'files/locked/foo.lfs', status: 'ADDED', old_mode: '0', new_mode: '100644', old_path: 'files/locked/foo.lfs',
            old_blob_id: "0000000000000000000000000000000000000000",
            new_blob_id: "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391"
          },
          {
            path: 'files/locked/foo.lfs', status: 'MODIFIED', old_mode: '100644', new_mode: '100644', old_path: 'files/locked/foo.lfs',
            old_blob_id: "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391",
            new_blob_id: "3eac02ca74e5b8e5df01dbdfdd7a9905c5e12007"
          },
          {
            path: 'files/locked/bar.lfs', status: 'ADDED', old_mode: '0', new_mode: '100644', old_path: 'files/locked/bar.lfs',
            old_blob_id: "0000000000000000000000000000000000000000",
            new_blob_id: "ea6c0a2142103f2d9157c1a9d50cc708032ec4a1"
          },
          {
            path: 'files/locked/foo.lfs', status: 'MODIFIED', old_mode: '100644', new_mode: '100644', old_path: 'files/locked/foo.lfs',
            old_blob_id: "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391",
            new_blob_id: "3eac02ca74e5b8e5df01dbdfdd7a9905c5e12007"
          },
          {
            path: 'files/locked/bar.lfs', status: 'ADDED', old_mode: '0', new_mode: '100644', old_path: 'files/locked/bar.lfs',
            old_blob_id: "0000000000000000000000000000000000000000",
            new_blob_id: "ea6c0a2142103f2d9157c1a9d50cc708032ec4a1"
          },
          {
            path: 'files/locked/bar.lfs', status: 'MODIFIED', old_mode: '100644', new_mode: '100644', old_path: 'files/locked/bar.lfs',
            old_blob_id: "ea6c0a2142103f2d9157c1a9d50cc708032ec4a1",
            new_blob_id: "9d8e9599c93013dee199bfdc13e8365c11652bba"
          },
          {
            path: 'files/locked/bar.lfs', status: 'MODIFIED', old_mode: '100644', new_mode: '100644', old_path: 'files/locked/bar.lfs',
            old_blob_id: "ea6c0a2142103f2d9157c1a9d50cc708032ec4a1",
            new_blob_id: "9d8e9599c93013dee199bfdc13e8365c11652bba"
          },
          {
            path: 'files/locked/baz.lfs', status: 'ADDED', old_mode: '0', new_mode: '100644', old_path: 'files/locked/baz.lfs',
            old_blob_id: "0000000000000000000000000000000000000000",
            new_blob_id: "dd1a523861a19addf2cce888119a07560be334b9"
          },
          {
            path: 'files/locked/baz.lfs', status: 'ADDED', old_mode: '0', new_mode: '100644', old_path: 'files/locked/baz.lfs',
            old_blob_id: "0000000000000000000000000000000000000000",
            new_blob_id: "dd1a523861a19addf2cce888119a07560be334b9"
          }
        ].as_json
      end

      it 'returns all paths, including ones from merge commits' do
        is_expected.to eq(changed_paths)
      end
    end

    shared_examples 'includes paths different in all parents' do
      let(:changed_paths) do
        [
          {
            path: 'files/locked/foo.lfs', status: 'ADDED', old_mode: '0', new_mode: '100644', old_path: 'files/locked/foo.lfs',
            old_blob_id: "0000000000000000000000000000000000000000",
            new_blob_id: "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391"
          },
          {
            path: 'files/locked/foo.lfs', status: 'MODIFIED', old_mode: '100644', new_mode: '100644', old_path: 'files/locked/foo.lfs',
            old_blob_id: "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391",
            new_blob_id: "3eac02ca74e5b8e5df01dbdfdd7a9905c5e12007"
          },
          {
            path: 'files/locked/bar.lfs', status: 'ADDED', old_mode: '0', new_mode: '100644', old_path: 'files/locked/bar.lfs',
            old_blob_id: "0000000000000000000000000000000000000000",
            new_blob_id: "ea6c0a2142103f2d9157c1a9d50cc708032ec4a1"
          },
          {
            path: 'files/locked/bar.lfs', status: 'MODIFIED', old_mode: '100644', new_mode: '100644', old_path: 'files/locked/bar.lfs',
            old_blob_id: "ea6c0a2142103f2d9157c1a9d50cc708032ec4a1",
            new_blob_id: "9d8e9599c93013dee199bfdc13e8365c11652bba"
          },
          {
            path: 'files/locked/baz.lfs', status: 'ADDED', old_mode: '0', new_mode: '100644', old_path: 'files/locked/baz.lfs',
            old_blob_id: "0000000000000000000000000000000000000000",
            new_blob_id: "dd1a523861a19addf2cce888119a07560be334b9"
          },
          {
            path: 'files/locked/baz.lfs', status: 'ADDED', old_mode: '0', new_mode: '100644', old_path: 'files/locked/baz.lfs',
            old_blob_id: "0000000000000000000000000000000000000000",
            new_blob_id: "dd1a523861a19addf2cce888119a07560be334b9"
          }
        ].as_json
      end

      it 'returns only paths different in all parents' do
        is_expected.to eq(changed_paths)
      end
    end

    shared_examples 'uses requests format' do
      it 'passes the revs via the requests kwarg as CommitRequest objects' do
        subject
        expect(Gitaly::FindChangedPathsRequest)
          .to have_received(:new).with(
            repository: repository_message,
            requests: requests,
            merge_commit_diff_mode: mapped_merge_commit_diff_mode,
            find_renames: find_renames
          )
      end
    end

    context 'when merge_commit_diff_mode is nil' do
      let(:merge_commit_diff_mode) { nil }

      include_examples 'includes paths different in any parent'

      include_examples 'uses requests format'
    end

    context 'when merge_commit_diff_mode is :unspecified' do
      let(:merge_commit_diff_mode) { :unspecified }

      include_examples 'includes paths different in any parent'

      include_examples 'uses requests format'
    end

    context 'when merge_commit_diff_mode is :include_merges' do
      let(:merge_commit_diff_mode) { :include_merges }

      include_examples 'includes paths different in any parent'

      include_examples 'uses requests format'
    end

    context 'when merge_commit_diff_mode is invalid' do
      let(:merge_commit_diff_mode) { 'invalid' }

      include_examples 'includes paths different in any parent'

      include_examples 'uses requests format'
    end

    context 'when merge_commit_diff_mode is :all_parents' do
      let(:merge_commit_diff_mode) { :all_parents }

      include_examples 'includes paths different in all parents'

      include_examples 'uses requests format'
    end

    context 'when renamed file exists' do
      let(:branch) { 'gitaly-rename-test' }
      let(:treeish_objects) { [repository.commit(branch)] }

      subject(:find_changed_paths) do
        described_class
          .new(repository)
          .find_changed_paths(treeish_objects, find_renames: find_renames)
          .as_json
      end

      context 'when find_renames is true' do
        let(:find_renames) { true }

        it 'detects renamed file and includes old_path' do
          expected_changed_paths = [
            {
              "new_blob_id" => "53855584db773c3df5b5f61f72974cb298822fbb",
              "new_mode" => "100644",
              "old_blob_id" => "53855584db773c3df5b5f61f72974cb298822fbb",
              "old_mode" => "100644",
              "old_path" => "CHANGELOG",
              "path" => "CHANGELOG.md",
              "status" => "RENAMED"
            }
          ]

          expect(find_changed_paths).to eq expected_changed_paths
        end
      end

      context 'when find_renames is false' do
        let(:find_renames) { false }

        it 'does not detect renamed file' do
          expected_changed_paths = [
            {
              "new_blob_id" => "0000000000000000000000000000000000000000",
              "new_mode" => "0",
              "old_blob_id" => "53855584db773c3df5b5f61f72974cb298822fbb",
              "old_mode" => "100644",
              "old_path" => "CHANGELOG",
              "path" => "CHANGELOG",
              "status" => "DELETED"
            },
            {
              "new_blob_id" => "53855584db773c3df5b5f61f72974cb298822fbb",
              "new_mode" => "100644",
              "old_blob_id" => "0000000000000000000000000000000000000000",
              "old_mode" => "0",
              "old_path" => "CHANGELOG.md",
              "path" => "CHANGELOG.md",
              "status" => "ADDED"
            }
          ]

          expect(find_changed_paths).to eq expected_changed_paths
        end
      end
    end

    context 'when all requested objects are invalid' do
      it 'does not send RPC request' do
        expect_any_instance_of(Gitaly::DiffService::Stub).not_to receive(:find_changed_paths)

        returned_value = described_class.new(repository).find_changed_paths(%w[wrong values])

        expect(returned_value).to eq([])
      end
    end

    context 'when commit has an empty SHA' do
      let(:empty_commit) { build(:commit, project: project, sha: '0000000000000000000000000000000000000000') }

      it 'does not send RPC request' do
        expect_any_instance_of(Gitaly::DiffService::Stub).not_to receive(:find_changed_paths)

        returned_value = described_class.new(repository).find_changed_paths([empty_commit])

        expect(returned_value).to eq([])
      end
    end

    context 'when commit sha is not set' do
      let(:empty_commit) { build(:commit, project: project, sha: nil) }

      it 'does not send RPC request' do
        expect_any_instance_of(Gitaly::DiffService::Stub).not_to receive(:find_changed_paths)

        returned_value = described_class.new(repository).find_changed_paths([empty_commit])

        expect(returned_value).to eq([])
      end
    end
  end

  describe '#tree_entries' do
    subject { client.tree_entries(repository, revision, path, recursive, skip_flat_paths, pagination_params) }

    let(:path) { '/' }
    let(:recursive) { false }
    let(:pagination_params) { nil }
    let(:skip_flat_paths) { false }

    it 'sends a get_tree_entries message with default limit' do
      expected_pagination_params = Gitaly::PaginationParameter.new(limit: Gitlab::GitalyClient::CommitService::TREE_ENTRIES_DEFAULT_LIMIT)
      expect_any_instance_of(Gitaly::CommitService::Stub)
        .to receive(:get_tree_entries)
        .with(gitaly_request_with_params({ pagination_params: expected_pagination_params }), kind_of(Hash))
        .and_return([])

      is_expected.to eq([[], nil])
    end

    context 'when recursive is "true"' do
      let(:recursive) { true }

      it 'sends a get_tree_entries message without the limit' do
        expect_any_instance_of(Gitaly::CommitService::Stub)
          .to receive(:get_tree_entries)
                .with(gitaly_request_with_params({ pagination_params: nil }), kind_of(Hash))
                .and_return([])

        is_expected.to eq([[], nil])
      end
    end

    context 'with UTF-8 params strings' do
      let(:revision) { "branch\u011F" }
      let(:path) { "foo/\u011F.txt" }

      it 'handles string encodings correctly' do
        expect_any_instance_of(Gitaly::CommitService::Stub)
          .to receive(:get_tree_entries)
          .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
          .and_return([])

        is_expected.to eq([[], nil])
      end
    end

    context 'with pagination parameters' do
      let(:pagination_params) { { limit: 3, page_token: nil } }

      it 'responds with a pagination cursor' do
        pagination_cursor = Gitaly::PaginationCursor.new(next_cursor: 'aabbccdd')
        response = Gitaly::GetTreeEntriesResponse.new(
          entries: [],
          pagination_cursor: pagination_cursor
        )

        expected_pagination_params = Gitaly::PaginationParameter.new(limit: 3)
        expect_any_instance_of(Gitaly::CommitService::Stub)
          .to receive(:get_tree_entries)
          .with(gitaly_request_with_params({ pagination_params: expected_pagination_params }), kind_of(Hash))
          .and_return([response])

        is_expected.to eq([[], pagination_cursor])
      end
    end

    context 'with structured errors' do
      context 'with ResolveTree error' do
        before do
          expect_any_instance_of(Gitaly::CommitService::Stub)
            .to receive(:get_tree_entries)
                  .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
                  .and_raise(raised_error)
        end

        let(:raised_error) do
          new_detailed_error(
            GRPC::Core::StatusCodes::INVALID_ARGUMENT,
            "invalid revision or path",
            Gitaly::GetTreeEntriesError.new(
              resolve_tree: Gitaly::ResolveRevisionError.new(
                revision: "incorrect revision"
              )))
        end

        it 'raises an IndexError' do
          expect { subject }.to raise_error do |error|
            expect(error).to be_a(Gitlab::Git::Index::IndexError)
            expect(error.message).to eq("invalid revision or path")
          end
        end
      end

      context 'with Path error' do
        let(:status_code) { nil }
        let(:expected_error) { nil }

        let(:structured_error) do
          new_detailed_error(
            status_code,
            "invalid revision or path",
            expected_error)
        end

        shared_examples '#get_tree_entries path failure' do
          it 'raises an IndexError' do
            expect_any_instance_of(Gitaly::CommitService::Stub)
              .to receive(:get_tree_entries).with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
                  .and_raise(structured_error)

            expect { subject }.to raise_error do |error|
              expect(error).to be_a(Gitlab::Git::Index::IndexError)
              expect(error.message).to eq(expected_message)
            end
          end
        end

        context 'with missing file' do
          let(:status_code) { GRPC::Core::StatusCodes::INVALID_ARGUMENT }
          let(:expected_message) { "You must provide a file path" }
          let(:expected_error) do
            Gitaly::GetTreeEntriesError.new(
              path: Gitaly::PathError.new(
                path: "random path",
                error_type: :ERROR_TYPE_EMPTY_PATH
              ))
          end

          it_behaves_like '#get_tree_entries path failure'
        end

        context 'with path including traversal' do
          let(:status_code) { GRPC::Core::StatusCodes::INVALID_ARGUMENT }
          let(:expected_message) { "Path cannot include traversal syntax" }
          let(:expected_error) do
            Gitaly::GetTreeEntriesError.new(
              path: Gitaly::PathError.new(
                path: "foo/../bar",
                error_type: :ERROR_TYPE_RELATIVE_PATH_ESCAPES_REPOSITORY
              ))
          end

          it_behaves_like '#get_tree_entries path failure'
        end

        context 'with absolute path' do
          let(:status_code) { GRPC::Core::StatusCodes::INVALID_ARGUMENT }
          let(:expected_message) { "Only relative path is accepted" }
          let(:expected_error) do
            Gitaly::GetTreeEntriesError.new(
              path: Gitaly::PathError.new(
                path: "/bar/foo",
                error_type: :ERROR_TYPE_ABSOLUTE_PATH
              ))
          end

          it_behaves_like '#get_tree_entries path failure'
        end

        context 'with long path' do
          let(:status_code) { GRPC::Core::StatusCodes::INVALID_ARGUMENT }
          let(:expected_message) { "Path is too long" }
          let(:expected_error) do
            Gitaly::GetTreeEntriesError.new(
              path: Gitaly::PathError.new(
                path: "long/path/",
                error_type: :ERROR_TYPE_LONG_PATH
              ))
          end

          it_behaves_like '#get_tree_entries path failure'
        end

        context 'with unkown path error' do
          let(:status_code) { GRPC::Core::StatusCodes::INVALID_ARGUMENT }
          let(:expected_message) { "Unknown path error" }
          let(:expected_error) do
            Gitaly::GetTreeEntriesError.new(
              path: Gitaly::PathError.new(
                path: "unkown error",
                error_type: :ERROR_TYPE_UNSPECIFIED
              ))
          end

          it_behaves_like '#get_tree_entries path failure'
        end
      end
    end
  end

  describe '#commit_count' do
    before do
      expect_any_instance_of(Gitaly::CommitService::Stub)
        .to receive(:count_commits)
        .with(gitaly_request_with_path(storage_name, relative_path),
          kind_of(Hash))
        .and_return([])
    end

    it 'sends a commit_count message' do
      client.commit_count(revision)
    end

    context 'with UTF-8 params strings' do
      let(:revision) { "branch\u011F" }
      let(:path) { "foo/\u011F.txt" }

      it 'handles string encodings correctly' do
        client.commit_count(revision, path: path)
      end
    end
  end

  describe '#find_commit' do
    let(:revision) { Gitlab::Git::SHA1_EMPTY_TREE_ID }

    it 'sends an RPC request' do
      request = Gitaly::FindCommitRequest.new(
        repository: repository_message, revision: revision
      )

      expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commit)
        .with(request, kind_of(Hash)).and_return(double(commit: nil))

      described_class.new(repository).find_commit(revision)
    end

    describe 'caching', :request_store do
      let(:commit_dbl) { double(id: 'f01b' * 10) }

      context 'when passed revision is a branch name' do
        it 'calls Gitaly' do
          expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commit).twice.and_return(double(commit: commit_dbl))

          commit = nil
          2.times { commit = described_class.new(repository).find_commit('master') }

          expect(commit).to eq(commit_dbl)
        end
      end

      context 'when passed revision is a commit ID' do
        it 'returns a cached commit' do
          expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commit).once.and_return(double(commit: commit_dbl))

          commit = nil
          2.times { commit = described_class.new(repository).find_commit('f01b' * 10) }

          expect(commit).to eq(commit_dbl)
        end
      end

      context 'when caching of the ref name is enabled' do
        it 'caches negative entries' do
          expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commit).once.and_return(double(commit: nil))

          commit = nil
          2.times do
            ::Gitlab::GitalyClient.allow_ref_name_caching do
              commit = described_class.new(repository).find_commit('master')
            end
          end

          expect(commit).to eq(nil)
        end

        it 'returns a cached commit' do
          expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commit).once.and_return(double(commit: commit_dbl))

          commit = nil
          2.times do
            ::Gitlab::GitalyClient.allow_ref_name_caching do
              commit = described_class.new(repository).find_commit('master')
            end
          end

          expect(commit).to eq(commit_dbl)
        end
      end
    end
  end

  describe '#list_commits' do
    let(:revisions) { 'master' }
    let(:reverse) { false }
    let(:order) { :date }
    let(:author) { nil }
    let(:ignore_case) { nil }
    let(:commit_message_patterns) { nil }
    let(:before) { nil }
    let(:after) { nil }
    let(:pagination_params) { nil }
    let(:skip) { '100' }

    shared_examples 'a ListCommits request' do
      before do
        ::Gitlab::GitalyClient.clear_stubs!
      end

      it 'sends a list_commits message' do
        expect_next_instance_of(Gitaly::CommitService::Stub) do |service|
          expected_request = gitaly_request_with_params(
            Array.wrap(revisions),
            reverse: reverse,
            author: author,
            ignore_case: ignore_case,
            commit_message_patterns: commit_message_patterns,
            before: before,
            after: after,
            pagination_params: pagination_params,
            order: order,
            skip: 100
          )

          expect(service).to receive(:list_commits).with(expected_request, kind_of(Hash)).and_return([])
        end

        client.list_commits(revisions, { reverse: reverse, author: author, ignore_case: ignore_case, commit_message_patterns: commit_message_patterns, before: before, after: after, pagination_params: pagination_params })
      end
    end

    it_behaves_like 'a ListCommits request'

    context 'with multiple revisions' do
      let(:revisions) { %w[master --not --all] }

      it_behaves_like 'a ListCommits request'
    end

    context 'with reverse: true' do
      let(:reverse) { true }

      it_behaves_like 'a ListCommits request'
    end

    context 'with commit message, author, before and after' do
      let(:author) { "Dmitriy" }
      let(:before) { 1474828200 }
      let(:after) { 1474828200 }
      let(:commit_message_patterns) { "Initial commit" }
      let(:ignore_case) { true }
      let(:pagination_params) { { limit: 1, page_token: 'foo' } }

      it_behaves_like 'a ListCommits request'
    end
  end

  describe '#list_new_commits' do
    let(:revisions) { [revision] }
    let(:gitaly_commits) { create_list(:gitaly_commit, 3) }
    let(:expected_commits) { gitaly_commits.map { |c| Gitlab::Git::Commit.new(repository, c) } }

    subject do
      client.list_new_commits(revisions)
    end

    shared_examples 'a #list_all_commits message' do
      let(:objects_exist_repo) do
        # The object directory of the repository must not be set so that we
        # don't use the quarantine directory.
        repository.gitaly_repository.dup.tap do |repo|
          repo.git_object_directory = ''
        end
      end

      let(:expected_object_exist_requests) do
        [gitaly_request_with_params(repository: objects_exist_repo, revisions: gitaly_commits.map(&:id))]
      end

      it 'sends a list_all_commits message' do
        expected_repository = repository.gitaly_repository.dup
        expected_repository.git_alternate_object_directories = Google::Protobuf::RepeatedField.new(:string)

        expect_next_instance_of(Gitaly::CommitService::Stub) do |service|
          expect(service).to receive(:list_all_commits)
            .with(gitaly_request_with_params(repository: expected_repository), kind_of(Hash))
            .and_return([Gitaly::ListAllCommitsResponse.new(commits: gitaly_commits)])

          objects_exist_response = Gitaly::CheckObjectsExistResponse.new(revisions: revision_existence.map do
            |rev, exists| Gitaly::CheckObjectsExistResponse::RevisionExistence.new(name: rev, exists: exists)
          end)

          expect(service).to receive(:check_objects_exist)
            .with(expected_object_exist_requests, kind_of(Hash))
            .and_return([objects_exist_response])
        end

        expect(subject).to eq(expected_commits)
      end
    end

    shared_examples 'a #list_commits message' do
      it 'sends a list_commits message' do
        expect_next_instance_of(Gitaly::CommitService::Stub) do |service|
          expect(service).to receive(:list_commits)
            .with(gitaly_request_with_params(revisions: revisions + %w[--not --all]), kind_of(Hash))
            .and_return([Gitaly::ListCommitsResponse.new(commits: gitaly_commits)])
        end

        expect(subject).to eq(expected_commits)
      end
    end

    before do
      ::Gitlab::GitalyClient.clear_stubs!

      allow(Gitlab::Git::HookEnv)
        .to receive(:all)
        .with(repository.gl_repository)
        .and_return(git_env)
    end

    context 'with hook environment' do
      let(:git_env) do
        {
          'GIT_OBJECT_DIRECTORY_RELATIVE' => '.git/objects',
          'GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE' => ['/dir/one', '/dir/two']
        }
      end

      context 'reject commits which exist in target repository' do
        let(:revision_existence) { gitaly_commits.to_h { |c| [c.id, true] } }
        let(:expected_commits) { [] }

        it_behaves_like 'a #list_all_commits message'
      end

      context 'keep commits which do not exist in target repository' do
        let(:revision_existence) { gitaly_commits.to_h { |c| [c.id, false] } }

        it_behaves_like 'a #list_all_commits message'
      end

      context 'mixed existing and nonexisting commits' do
        let(:revision_existence) do
          {
            gitaly_commits[0].id => true,
            gitaly_commits[1].id => false,
            gitaly_commits[2].id => true
          }
        end

        let(:expected_commits) { [Gitlab::Git::Commit.new(repository, gitaly_commits[1])] }

        it_behaves_like 'a #list_all_commits message'
      end

      context 'with more than 100 commits' do
        let(:gitaly_commits) { build_list(:gitaly_commit, 101) }
        let(:revision_existence) { gitaly_commits.to_h { |c| [c.id, false] } }

        it_behaves_like 'a #list_all_commits message' do
          let(:expected_object_exist_requests) do
            [
              gitaly_request_with_params(repository: objects_exist_repo, revisions: gitaly_commits[0...100].map(&:id)),
              gitaly_request_with_params(revisions: gitaly_commits[100..].map(&:id))
            ]
          end
        end
      end
    end

    context 'without hook environment' do
      let(:git_env) do
        {
          'GIT_OBJECT_DIRECTORY_RELATIVE' => '',
          'GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE' => []
        }
      end

      it_behaves_like 'a #list_commits message'
    end
  end

  describe '#commit_stats' do
    let(:request) do
      Gitaly::CommitStatsRequest.new(
        repository: repository_message, revision: revision
      )
    end

    let(:response) do
      Gitaly::CommitStatsResponse.new(
        oid: revision,
        additions: 11,
        deletions: 15
      )
    end

    subject { described_class.new(repository).commit_stats(revision) }

    it 'sends an RPC request' do
      expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:commit_stats)
        .with(request, kind_of(Hash)).and_return(response)

      expect(subject.additions).to eq(11)
      expect(subject.deletions).to eq(15)
    end
  end

  describe '#find_commits' do
    it 'sends an RPC request with NONE when default' do
      request = Gitaly::FindCommitsRequest.new(
        repository: repository_message,
        disable_walk: true,
        order: 'NONE',
        global_options: Gitaly::GlobalOptions.new(literal_pathspecs: false)
      )

      expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commits)
        .with(request, kind_of(Hash)).and_return([])

      client.find_commits(order: 'default')
    end

    it 'sends an RPC request' do
      request = Gitaly::FindCommitsRequest.new(
        repository: repository_message,
        disable_walk: true,
        order: 'TOPO',
        global_options: Gitaly::GlobalOptions.new(literal_pathspecs: false)
      )

      expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commits)
        .with(request, kind_of(Hash)).and_return([])

      client.find_commits(order: 'topo')
    end

    it 'sends an RPC request with an author' do
      request = Gitaly::FindCommitsRequest.new(
        repository: repository_message,
        disable_walk: true,
        order: 'NONE',
        author: "Billy Baggins <bilbo@shire.com>",
        global_options: Gitaly::GlobalOptions.new(literal_pathspecs: false)
      )

      expect_any_instance_of(Gitaly::CommitService::Stub).to receive(:find_commits)
        .with(request, kind_of(Hash)).and_return([])

      client.find_commits(order: 'default', author: "Billy Baggins <bilbo@shire.com>")
    end
  end

  describe '#object_existence_map' do
    shared_examples 'a CheckObjectsExistRequest' do
      before do
        ::Gitlab::GitalyClient.clear_stubs!
      end

      it 'returns expected results' do
        expect_next_instance_of(Gitaly::CommitService::Stub) do |service|
          expect(service).to receive(:check_objects_exist).and_call_original
        end

        expect(client.object_existence_map(revisions.keys)).to eq(revisions)
      end
    end

    context 'with empty request' do
      let(:revisions) { {} }

      it 'doesnt call for Gitaly' do
        expect(Gitaly::CommitService::Stub).not_to receive(:new)

        expect(client.object_existence_map(revisions.keys)).to eq(revisions)
      end
    end

    context 'when revision exists' do
      let(:revisions) { { 'refs/heads/master' => true } }

      it_behaves_like 'a CheckObjectsExistRequest'
    end

    context 'when revision does not exist' do
      let(:revisions) { { 'refs/does/not/exist' => false } }

      it_behaves_like 'a CheckObjectsExistRequest'
    end

    context 'when request contains mixed revisions' do
      let(:revisions) do
        {
          "refs/heads/master" => true,
          "refs/does/not/exist" => false
        }
      end

      it_behaves_like 'a CheckObjectsExistRequest'
    end

    context 'when requesting many revisions' do
      let(:revisions) do
        Array(1..1234).to_h { |i| ["refs/heads/#{i}", false] }
      end

      it_behaves_like 'a CheckObjectsExistRequest'
    end
  end

  describe '#commits_by_message' do
    shared_examples 'a CommitsByMessageRequest' do
      let(:commits) { create_list(:gitaly_commit, 2) }

      before do
        request = Gitaly::CommitsByMessageRequest.new(
          repository: repository_message,
          query: query,
          revision: (options[:revision] || '').dup.force_encoding(Encoding::ASCII_8BIT),
          path: (options[:path] || '').dup.force_encoding(Encoding::ASCII_8BIT),
          limit: (options[:limit] || 1000).to_i,
          offset: (options[:offset] || 0).to_i,
          global_options: Gitaly::GlobalOptions.new(literal_pathspecs: true)
        )

        allow_any_instance_of(Gitaly::CommitService::Stub)
          .to receive(:commits_by_message)
          .with(request, kind_of(Hash))
          .and_return([Gitaly::CommitsByMessageResponse.new(commits: commits)])
      end

      it 'sends an RPC request with the correct payload' do
        expect(client.commits_by_message(query, **options)).to match_array(wrap_commits(commits))
      end
    end

    let(:query) { 'Add a feature' }
    let(:options) { {} }

    context 'when only the query is provided' do
      include_examples 'a CommitsByMessageRequest'
    end

    context 'when all arguments are provided' do
      let(:options) { { revision: 'feature-branch', path: 'foo.txt', limit: 10, offset: 20 } }

      include_examples 'a CommitsByMessageRequest'
    end

    context 'when limit and offset are not integers' do
      let(:options) { { limit: '10', offset: '60' } }

      include_examples 'a CommitsByMessageRequest'
    end

    context 'when revision and path contain non-ASCII characters' do
      let(:options) { { revision: "branch\u011F", path: "foo/\u011F.txt" } }

      include_examples 'a CommitsByMessageRequest'
    end

    def wrap_commits(commits)
      commits.map { |commit| Gitlab::Git::Commit.new(repository, commit) }
    end
  end

  describe '#list_commits_by_ref_name' do
    let(:project) { create(:project, :repository, create_branch: 'ü/unicode/multi-byte') }

    it 'lists latest commits grouped by a ref name' do
      response = client.list_commits_by_ref_name(%w[master feature v1.0.0 nonexistent ü/unicode/multi-byte])

      expect(response.keys.count).to eq 4
      expect(response.fetch('master').id).to eq 'b83d6e391c22777fca1ed3012fce84f633d7fed0'
      expect(response.fetch('feature').id).to eq '0b4bc9a49b562e85de7cc9e834518ea6828729b9'
      expect(response.fetch('v1.0.0').id).to eq '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'
      expect(response.fetch('ü/unicode/multi-byte')).to be_present
      expect(response).not_to have_key 'nonexistent'
    end
  end

  describe '#raw_blame' do
    let_it_be(:project) { create(:project, :test_repo) }

    let(:revision) { 'blame-on-renamed' }
    let(:path) { 'files/plain_text/renamed' }
    let(:range) { nil }

    let(:blame_headers) do
      [
        '405a45736a75e439bb059e638afaa9a3c2eeda79 1 1 2',
        '405a45736a75e439bb059e638afaa9a3c2eeda79 2 2',
        'bed1d1610ebab382830ee888288bf939c43873bb 3 3 1',
        '3685515c40444faf92774e72835e1f9c0e809672 4 4 1',
        '32c33da59f8a1a9f90bdeda570337888b00b244d 5 5 1'
      ]
    end

    subject(:blame) { client.raw_blame(revision, path, range: range).split("\n") }

    context 'without a range' do
      let(:range) { nil }

      it 'blames a whole file' do
        is_expected.to include(*blame_headers)
      end
    end

    context 'with ignore_revisions_blob' do
      let(:ignore_revisions_blob) { "refs/heads/#{branch_name}:#{file_name}" }
      let(:branch_name) { generate :branch }

      subject(:blame) do
        client.raw_blame(revision, path, range: range, ignore_revisions_blob: ignore_revisions_blob).split("\n")
      end

      shared_examples 'raises error with message' do |error_class, message|
        it "raises #{error_class} with correct message" do
          expect { blame }.to raise_error(error_class) do |error|
            expect(error.details).to eq(message)
          end
        end
      end

      context 'when ignore file exists' do
        before do
          project.repository.create_file(
            project.owner,
            file_name,
            file_content,
            message: "add file",
            branch_name: branch_name
          )
        end

        context "with valid ignore file content" do
          let(:file_name) { '.git-ignore-revs-file' }
          let(:file_content) { '3685515c40444faf92774e72835e1f9c0e809672' }

          it 'excludes the specified revision from blame' do
            expect(blame).to include(*blame_headers[0..2], blame_headers[4])
            expect(blame).not_to include(file_content)
          end
        end

        context 'with invalid ignore file content' do
          let(:file_name) { '.git-ignore-revs-invalid' }
          let(:file_content) { 'invalid_content' }

          include_examples 'raises error with message',
            GRPC::NotFound,
            'invalid object name'
        end
      end

      context 'with invalid ignore revision' do
        let(:ignore_revisions_blob) { "refs/heads/invalid" }

        include_examples 'raises error with message',
          GRPC::NotFound,
          'cannot resolve ignore-revs blob'
      end

      context 'when ignore_revision_blob is a directory' do
        let(:ignore_revisions_blob) { "refs/heads/#{revision}:files" }

        include_examples 'raises error with message',
          GRPC::InvalidArgument,
          'ignore revision is not a blob'
      end
    end

    context 'with a range' do
      let(:range) { '3,4' }

      it 'blames part of a file' do
        is_expected.to include(blame_headers[2], blame_headers[3])
        is_expected.not_to include(blame_headers[0], blame_headers[1], blame_headers[4])
      end
    end

    context 'when out of range' do
      let(:range) { '9999,99999' }

      it { expect { blame }.to raise_error(ArgumentError, 'range is outside of the file length') }
    end

    context 'when a file path is not found' do
      let(:path) { 'unknown/path' }

      it { expect { blame }.to raise_error(ArgumentError, 'path not found in revision') }
    end

    context 'when an unknown exception is raised' do
      let(:gitaly_exception) { GRPC::BadStatus.new(GRPC::Core::StatusCodes::NOT_FOUND) }

      before do
        expect_any_instance_of(Gitaly::CommitService::Stub)
          .to receive(:raw_blame)
          .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
          .and_raise(gitaly_exception)
      end

      it { expect { blame }.to raise_error(gitaly_exception) }
    end
  end

  describe '#get_commit_signatures' do
    let(:project) { create(:project, :test_repo) }

    it 'returns commit signatures for specified commit ids', :aggregate_failures do
      without_signature = "e63f41fe459e62e1228fcef60d7189127aeba95a" # has no signature

      signed_by_user = [
        "a17a9f66543673edf0a3d1c6b93bdda3fe600f32", # has signature
        "7b5160f9bb23a3d58a0accdbe89da13b96b1ece9"  # SSH signature
      ]

      large_signed_text = "8cf8e80a5a0546e391823c250f2b26b9cf15ce88" # has signature and commit message > 4MB

      signatures = client.get_commit_signatures(
        [without_signature, large_signed_text, *signed_by_user]
      )

      expect(signatures.keys).to match_array([large_signed_text, *signed_by_user])

      [large_signed_text, *signed_by_user].each do |commit_id|
        expect(signatures[commit_id][:signature]).to be_present
        expect(signatures[commit_id][:signer]).to eq(:SIGNER_USER)
        expect(signatures[commit_id][:author_email]).to be_present
      end

      signed_by_user.each do |commit_id|
        commit = project.commit(commit_id)
        expect(signatures[commit_id][:signed_text]).to include(commit.message)
        expect(signatures[commit_id][:signed_text]).to include(commit.description)
        expect(signatures[commit_id][:author_email]).to eq(commit.author_email)
      end

      expect(signatures[large_signed_text][:signed_text].size).to eq(4971878)
    end
  end

  describe '#get_patch_id' do
    it 'returns patch_id of given revisions' do
      expect(client.get_patch_id('HEAD~', 'HEAD')).to eq('67cc1b19744f71ee68e5aa6aa0dbadf03a6ba912')
    end

    context 'when one of the param is invalid' do
      it 'raises an GRPC::InvalidArgument error' do
        expect { client.get_patch_id('HEAD', nil) }.to raise_error(GRPC::InvalidArgument)
      end
    end

    context 'when two revisions are the same' do
      it 'raises an GRPC::FailedPrecondition error' do
        expect { client.get_patch_id('HEAD', 'HEAD') }.to raise_error(GRPC::FailedPrecondition)
      end
    end
  end
end
