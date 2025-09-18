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
end
