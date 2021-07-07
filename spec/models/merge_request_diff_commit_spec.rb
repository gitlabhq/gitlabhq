# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestDiffCommit do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }

  it_behaves_like 'a BulkInsertSafe model', MergeRequestDiffCommit do
    let(:valid_items_for_bulk_insertion) do
      build_list(:merge_request_diff_commit, 10) do |mr_diff_commit|
        mr_diff_commit.merge_request_diff = create(:merge_request_diff)
      end
    end

    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe 'associations' do
    it { is_expected.to belong_to(:commit_author) }
    it { is_expected.to belong_to(:committer) }
  end

  describe '#to_hash' do
    subject { merge_request.commits.first }

    it 'returns the same results as Commit#to_hash, except for parent_ids' do
      commit_from_repo = project.repository.commit(subject.sha)
      commit_from_repo_hash = commit_from_repo.to_hash.merge(parent_ids: [])

      expect(subject.to_hash).to eq(commit_from_repo_hash)
    end
  end

  describe '.create_bulk' do
    let(:merge_request_diff_id) { merge_request.merge_request_diff.id }
    let(:commits) do
      [
        project.commit('5937ac0a7beb003549fc5fd26fc247adbce4a52e'),
        project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d')
      ]
    end

    let(:rows) do
      [
        {
          "message": "Add submodule from gitlab.com\n\nSigned-off-by: Dmitriy Zaporozhets \u003cdmitriy.zaporozhets@gmail.com\u003e\n",
          "authored_date": "2014-02-27T10:01:38.000+01:00".to_time,
          "author_name": "Dmitriy Zaporozhets",
          "author_email": "dmitriy.zaporozhets@gmail.com",
          "committed_date": "2014-02-27T10:01:38.000+01:00".to_time,
          "committer_name": "Dmitriy Zaporozhets",
          "committer_email": "dmitriy.zaporozhets@gmail.com",
          "commit_author_id": an_instance_of(Integer),
          "committer_id": an_instance_of(Integer),
          "merge_request_diff_id": merge_request_diff_id,
          "relative_order": 0,
          "sha": Gitlab::Database::ShaAttribute.serialize("5937ac0a7beb003549fc5fd26fc247adbce4a52e"),
          "trailers": {}.to_json
        },
        {
          "message": "Change some files\n\nSigned-off-by: Dmitriy Zaporozhets \u003cdmitriy.zaporozhets@gmail.com\u003e\n",
          "authored_date": "2014-02-27T09:57:31.000+01:00".to_time,
          "author_name": "Dmitriy Zaporozhets",
          "author_email": "dmitriy.zaporozhets@gmail.com",
          "committed_date": "2014-02-27T09:57:31.000+01:00".to_time,
          "committer_name": "Dmitriy Zaporozhets",
          "committer_email": "dmitriy.zaporozhets@gmail.com",
          "commit_author_id": an_instance_of(Integer),
          "committer_id": an_instance_of(Integer),
          "merge_request_diff_id": merge_request_diff_id,
          "relative_order": 1,
          "sha": Gitlab::Database::ShaAttribute.serialize("570e7b2abdd848b95f2f578043fc23bd6f6fd24d"),
          "trailers": {}.to_json
        }
      ]
    end

    subject { described_class.create_bulk(merge_request_diff_id, commits) }

    it 'inserts the commits into the database en masse' do
      expect(Gitlab::Database).to receive(:bulk_insert)
        .with(described_class.table_name, rows)

      subject
    end

    it 'creates diff commit users' do
      diff = create(:merge_request_diff, merge_request: merge_request)

      described_class.create_bulk(diff.id, [commits.first])

      commit_row = MergeRequestDiffCommit
        .find_by(merge_request_diff_id: diff.id, relative_order: 0)

      commit_user_row =
        MergeRequest::DiffCommitUser.find_by(name: 'Dmitriy Zaporozhets')

      expect(commit_row.commit_author).to eq(commit_user_row)
      expect(commit_row.committer).to eq(commit_user_row)
    end

    context 'with dates larger than the DB limit' do
      let(:commits) do
        # This commit's date is "Sun Aug 17 07:12:55 292278994 +0000"
        [project.commit('ba3343bc4fa403a8dfbfcab7fc1a8c29ee34bd69')]
      end

      let(:timestamp) { Time.zone.at((1 << 31) - 1) }
      let(:rows) do
        [{
          "message": "Weird commit date\n",
          "authored_date": timestamp,
          "author_name": "Alejandro Rodríguez",
          "author_email": "alejorro70@gmail.com",
          "committed_date": timestamp,
          "committer_name": "Alejandro Rodríguez",
          "committer_email": "alejorro70@gmail.com",
          "commit_author_id": an_instance_of(Integer),
          "committer_id": an_instance_of(Integer),
          "merge_request_diff_id": merge_request_diff_id,
          "relative_order": 0,
          "sha": Gitlab::Database::ShaAttribute.serialize("ba3343bc4fa403a8dfbfcab7fc1a8c29ee34bd69"),
          "trailers": {}.to_json
        }]
      end

      it 'uses a sanitized date' do
        expect(Gitlab::Database).to receive(:bulk_insert)
          .with(described_class.table_name, rows)

        subject
      end
    end
  end

  describe '.prepare_commits_for_bulk_insert' do
    it 'returns the commit hashes and unique user tuples' do
      commit = double(:commit, to_hash: {
        parent_ids: %w[foo bar],
        author_name: 'a' * 1000,
        author_email: 'a' * 1000,
        committer_name: 'Alice',
        committer_email: 'alice@example.com'
      })

      hashes, tuples = described_class.prepare_commits_for_bulk_insert([commit])

      expect(hashes).to eq([{
        author_name: 'a' * 512,
        author_email: 'a' * 512,
        committer_name: 'Alice',
        committer_email: 'alice@example.com'
      }])

      expect(tuples)
        .to include(['a' * 512, 'a' * 512], %w[Alice alice@example.com])
    end
  end
end
