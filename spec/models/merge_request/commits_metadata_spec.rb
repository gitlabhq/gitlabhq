# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest::CommitsMetadata, feature_category: :code_review_workflow do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:commit_author) }
    it { is_expected.to belong_to(:committer) }
    it { is_expected.to have_many(:merge_request_diff_commits) }
  end

  describe '.find_or_create' do
    let_it_be(:project) { create(:project) }
    let_it_be(:commit_author) { create(:merge_request_diff_commit_user) }
    let_it_be(:committer) { create(:merge_request_diff_commit_user) }

    let(:metadata) do
      {
        'project_id' => project.id,
        'sha' => 'abc123',
        'commit_author' => commit_author,
        'committer' => committer,
        'message' => 'This is a message',
        'authored_date' => Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
        'committed_date' => Time.zone.parse("2014-02-27T09:57:31.000+01:00")
      }
    end

    it 'creates a new row' do
      commits_metadata = described_class.find_or_create(metadata)

      expect(commits_metadata.id).to be_present
      expect(commits_metadata.project_id).to eq(metadata['project_id'])
      expect(commits_metadata.sha).to eq(metadata['sha'])
      expect(commits_metadata.commit_author).to eq(metadata['commit_author'])
      expect(commits_metadata.committer).to eq(metadata['committer'])
      expect(commits_metadata.message).to eq(metadata['message'])
      expect(commits_metadata.authored_date).to eq(metadata['authored_date'])
      expect(commits_metadata.committed_date).to eq(metadata['committed_date'])
    end

    it 'returns an existing row' do
      existing_row = create(:merge_request_commits_metadata, project: project, sha: 'abc123')
      found_row = described_class.find_or_create(metadata)

      expect(existing_row).to eq(found_row)
    end

    it 'retries when ActiveRecord::RecordNotUnique was raised' do
      existing_row = create(:merge_request_commits_metadata, project: project, sha: 'abc123')
      call_count = 0

      # Mock to raise exception first time, then let it proceed normally
      allow(described_class).to receive(:find_or_create_by!).and_wrap_original do |method, *args, &block|
        call_count += 1

        raise ActiveRecord::RecordNotUnique, 'duplicate' if call_count == 1

        method.call(*args, &block)
      end

      found_row = described_class.find_or_create(metadata)

      expect(found_row).to eq(existing_row)
      expect(call_count).to eq(2)
    end
  end

  describe '.bulk_find' do
    it 'finds records matching project_id and SHAs' do
      project = create(:project)
      another_project = create(:project)

      matching_metadata_1 = create(
        :merge_request_commits_metadata,
        project_id: project.id,
        sha: 'abc123'
      )

      matching_metadata_2 = create(
        :merge_request_commits_metadata,
        project_id: project.id,
        sha: 'def456'
      )

      non_matching_metadata = create(
        :merge_request_commits_metadata,
        project_id: another_project.id,
        sha: 'def456'
      )

      results = described_class.bulk_find(project.id, %w[abc123 def456])

      expect(results).to match_array(
        [
          [matching_metadata_1.id, matching_metadata_1.sha],
          [matching_metadata_2.id, matching_metadata_2.sha]
        ]
      )
      expect(results).not_to include([non_matching_metadata.id, non_matching_metadata.sha])
    end
  end

  describe '.bulk_find_or_create' do
    let_it_be(:project) { create(:project) }

    let_it_be(:existing_commit_metadata) do
      create(
        :merge_request_commits_metadata,
        project_id: project.id,
        sha: 'abc123',
        commit_author_id: 1,
        committer_id: 2,
        authored_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
        committed_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00")
      )
    end

    it 'bulk creates missing rows and reuses existing rows' do
      commits_rows = [
        {
          commit_author_id: 1,
          committer_id: 2,
          raw_sha: 'abc123',
          authored_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          committed_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          message: 'First commit'
        },
        {
          commit_author_id: 1,
          committer_id: 2,
          raw_sha: 'def456',
          authored_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          committed_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          message: 'Second commit'
        }
      ]

      commits_metadata_mapping = described_class.bulk_find_or_create(project.id, commits_rows)
      new_commit_metadata = described_class.find_by(project_id: project.id, sha: 'def456')

      expect(commits_metadata_mapping['abc123']).to eq(existing_commit_metadata.id)
      expect(commits_metadata_mapping['def456']).to eq(new_commit_metadata.id)
    end

    it 'bulk creates missing rows and reuses existing rows even if first bulk_find returns empty' do
      allow(described_class).to receive(:bulk_find).and_call_original

      # First call: initial bulk_find
      expect(described_class)
        .to receive(:bulk_find)
        .with(project.id, %w[abc123 def456])
        .and_return([])

      commits_rows = [
        {
          commit_author_id: 1,
          committer_id: 2,
          raw_sha: 'abc123',
          authored_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          committed_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          message: 'First commit'
        },
        {
          commit_author_id: 1,
          committer_id: 2,
          raw_sha: 'def456',
          authored_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          committed_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          message: 'Second commit'
        }
      ]

      commits_metadata_mapping = described_class.bulk_find_or_create(project.id, commits_rows)
      new_commit_metadata = described_class.find_by(project_id: project.id, sha: 'def456')

      expect(commits_metadata_mapping['abc123']).to eq(existing_commit_metadata.id)
      expect(commits_metadata_mapping['def456']).to eq(new_commit_metadata.id)
    end

    it 'inserts new data when matching SHA is for a different project_id' do
      another_project = create(:project)

      commits_rows = [
        {
          commit_author_id: 1,
          committer_id: 2,
          raw_sha: 'abc123',
          authored_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          committed_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          message: 'First commit'
        }
      ]

      commits_metadata_mapping = described_class.bulk_find_or_create(another_project.id, commits_rows)
      new_commit_metadata = described_class.find_by(project_id: another_project.id, sha: 'abc123')

      expect(commits_metadata_mapping['abc123']).to eq(new_commit_metadata.id)
    end

    it 'does not insert any data when all commits metadata exist' do
      commits_rows = [
        {
          commit_author_id: 1,
          committer_id: 2,
          raw_sha: 'abc123',
          authored_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          committed_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          message: 'First commit'
        }
      ]

      # Mock to verify insert_all isn't called
      expect(described_class).not_to receive(:insert_all)

      commits_metadata_mapping = described_class.bulk_find_or_create(project.id, commits_rows)

      expect(commits_metadata_mapping['abc123']).to eq(existing_commit_metadata.id)
    end

    it 'handles concurrently inserted rows' do
      commits_rows = [
        {
          commit_author_id: 1,
          committer_id: 2,
          raw_sha: 'abc123',
          authored_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          committed_date: Time.zone.parse("2014-02-27T09:57:31.000+01:00"),
          message: 'First commit'
        }
      ]

      # First call: initial bulk_find
      expect(described_class)
        .to receive(:bulk_find)
        .with(project.id, ['abc123'])
        .and_return([])

      # Mock insert_all to return empty array (simulating concurrent insert happened)
      expect(described_class)
        .to receive(:insert_all)
        .and_return([])

      # Final call: checking for concurrent inserts with with_organization: true
      expect(described_class)
        .to receive(:bulk_find)
        .with(project.id, ['abc123'])
        .and_return([[existing_commit_metadata.id, 'abc123']])

      commits_metadata_mapping = described_class.bulk_find_or_create(project.id, commits_rows)

      expect(commits_metadata_mapping['abc123']).to eq(existing_commit_metadata.id)
    end
  end

  describe '.oldest_merge_request_id_per_commit' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }

    let_it_be(:commit_sha_1) { OpenSSL::Digest::SHA256.hexdigest('abc') }
    let_it_be(:commit_sha_2) { OpenSSL::Digest::SHA256.hexdigest('def') }
    let_it_be(:commit_sha_3) { OpenSSL::Digest::SHA256.hexdigest('ghi') }
    let_it_be(:commit_sha_4) { OpenSSL::Digest::SHA256.hexdigest('jkl') }

    let_it_be(:commits_metadata_1) { create(:merge_request_commits_metadata, project: project, sha: commit_sha_1) }
    let_it_be(:commits_metadata_2) { create(:merge_request_commits_metadata, project: project, sha: commit_sha_2) }
    let_it_be(:commits_metadata_3) { create(:merge_request_commits_metadata, project: project, sha: commit_sha_3) }
    let_it_be(:commits_metadata_4) { create(:merge_request_commits_metadata, project: project, sha: commit_sha_4) }

    subject(:result) { described_class.oldest_merge_request_id_per_commit(project.id, shas) }

    context 'when there are merged merge requests' do
      let_it_be(:mr_1) { create(:merge_request, :merged, target_project: project, id: 100) }
      let_it_be(:mr_2) { create(:merge_request, :merged, target_project: project, id: 200) }
      let_it_be(:mr_3) { create(:merge_request, :merged, target_project: project, id: 150) }
      let_it_be(:mr_4) { create(:merge_request, :merged, target_project: project, id: 300) }

      let_it_be(:mr_diff_1) { create(:merge_request_diff, merge_request: mr_1) }
      let_it_be(:mr_diff_2) { create(:merge_request_diff, merge_request: mr_2) }
      let_it_be(:mr_diff_3) { create(:merge_request_diff, merge_request: mr_3) }
      let_it_be(:mr_diff_4) { create(:merge_request_diff, merge_request: mr_4) }

      before_all do
        mr_1.update!(latest_merge_request_diff_id: mr_diff_1.id)
        mr_2.update!(latest_merge_request_diff_id: mr_diff_2.id)
        mr_3.update!(latest_merge_request_diff_id: mr_diff_3.id)
        mr_4.update!(latest_merge_request_diff_id: mr_diff_4.id)

        create(:merge_request_diff_commit,
          merge_request_diff: mr_diff_1,
          merge_request_commits_metadata: commits_metadata_1)
        create(:merge_request_diff_commit,
          merge_request_diff: mr_diff_2,
          merge_request_commits_metadata: commits_metadata_1)
        create(:merge_request_diff_commit, merge_request_diff: mr_diff_3, sha: commit_sha_2)
        # populate sha in both tables to test for duplication
        create(:merge_request_diff_commit,
          merge_request_diff: mr_diff_4,
          sha: commit_sha_4,
          merge_request_commits_metadata: commits_metadata_4)
      end

      context 'when querying for commits that exist in multiple merge requests' do
        let(:shas) { [commit_sha_1, commit_sha_2, commit_sha_4] }

        it 'returns the oldest merge request ID for each commit' do
          expect(result.pluck(:sha, :merge_request_id)).to contain_exactly(
            [commit_sha_1, 100], # oldest of 100, 200
            [commit_sha_2, 150],
            [commit_sha_4, 300]
          )
        end
      end

      context 'when querying for commits that do not exist' do
        let(:shas) { ['nonexistent'] }

        it 'returns empty results' do
          expect(result).to be_empty
        end
      end

      context 'when querying with empty SHA array' do
        let(:shas) { [] }

        it 'returns empty results' do
          expect(result).to be_empty
        end
      end
    end

    context 'when merge requests are not merged' do
      let_it_be(:mr_open) do
        create(:merge_request, :opened, source_project: project, target_project: project)
      end

      let(:shas) { [commit_sha_1, commit_sha_2] }

      let_it_be(:mr_closed) do
        create(:merge_request, :closed, source_project: project, target_project: project)
      end

      let_it_be(:mr_diff_open) { create(:merge_request_diff, merge_request: mr_open) }
      let_it_be(:mr_diff_closed) { create(:merge_request_diff, merge_request: mr_closed) }

      before do
        mr_open.update!(latest_merge_request_diff_id: mr_diff_open.id)
        mr_closed.update!(latest_merge_request_diff_id: mr_diff_closed.id)

        create(:merge_request_diff_commit,
          merge_request_diff: mr_diff_open,
          merge_request_commits_metadata: commits_metadata_1)
        create(:merge_request_diff_commit, merge_request_diff: mr_diff_closed, sha: commit_sha_2)
      end

      it 'does not return non-merged merge requests' do
        expect(result).to be_empty
      end
    end

    context 'when merge requests belong to different projects' do
      let_it_be(:other_commits_metadata) do
        create(:merge_request_commits_metadata, project: other_project, sha: commit_sha_1)
      end

      let(:shas) { [commit_sha_1] }

      let_it_be(:other_mr) do
        create(:merge_request, :merged, target_project: other_project, id: 50)
      end

      let_it_be(:other_mr_diff) { create(:merge_request_diff, merge_request: other_mr) }

      before_all do
        other_mr.update!(latest_merge_request_diff_id: other_mr_diff.id)
        create(:merge_request_diff_commit,
          merge_request_diff: other_mr_diff,
          merge_request_commits_metadata: other_commits_metadata)
      end

      it 'only returns results for the specified project' do
        expect(result).to be_empty
      end
    end
  end
end
