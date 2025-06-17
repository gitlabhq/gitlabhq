# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestDiffCommit, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }

  it_behaves_like 'a BulkInsertSafe model', described_class do
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

    context 'when disable_message_attribute_on_mr_diff_commits is false' do
      # Both these feature flags are can interact to suppress display of the message
      #   attribute. Without disabling both feature flags, we can not prove the
      #  isolated case of disable_message_attribute_on_mr_diff_commits.
      #
      before do
        stub_feature_flags(disable_message_attribute_on_mr_diff_commits: false)
        stub_feature_flags(optimized_commit_storage: false)
      end

      it 'returns the same results as Commit#to_hash, except for parent_ids' do
        commit_from_repo = project.repository.commit(subject.sha)
        commit_from_repo_hash = commit_from_repo.to_hash.merge(parent_ids: [])

        expect(subject.to_hash).to eq(commit_from_repo_hash)
      end
    end

    context 'when disable_message_attribute_on_mr_diff_commits is true' do
      before do
        # Strictly speaking, we don't need to set this flag to `true` but let's
        #   be explicit.
        #
        stub_feature_flags(disable_message_attribute_on_mr_diff_commits: true)
        stub_feature_flags(optimized_commit_storage: false)
      end

      it 'returns the same results as Commit#to_hash, except for parent_ids and message' do
        commit_from_repo = project.repository.commit(subject.sha)
        commit_from_repo_hash = commit_from_repo.to_hash.merge(parent_ids: [], message: "")

        expect(subject.to_hash).to eq(commit_from_repo_hash)
      end
    end
  end

  describe '.create_bulk' do
    subject { described_class.create_bulk(merge_request_diff_id, commits, project, skip_commit_data: skip_commit_data) }

    let(:merge_request_diff_id) { merge_request.merge_request_diff.id }
    let(:skip_commit_data) { false }
    let(:commits) do
      [
        project.commit('5937ac0a7beb003549fc5fd26fc247adbce4a52e'),
        project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d')
      ]
    end

    let(:rows) do
      [
        {
          message: "Add submodule from gitlab.com\n\nSigned-off-by: Dmitriy Zaporozhets \u003cdmitriy.zaporozhets@gmail.com\u003e\n",
          authored_date: "2014-02-27T10:01:38.000+01:00".to_time,
          committed_date: "2014-02-27T10:01:38.000+01:00".to_time,
          commit_author_id: an_instance_of(Integer),
          committer_id: an_instance_of(Integer),
          merge_request_diff_id: merge_request_diff_id,
          relative_order: 0,
          sha: Gitlab::Database::ShaAttribute.serialize("5937ac0a7beb003549fc5fd26fc247adbce4a52e"),
          trailers: {}.to_json
        },
        {
          message: "Change some files\n\nSigned-off-by: Dmitriy Zaporozhets \u003cdmitriy.zaporozhets@gmail.com\u003e\n",
          authored_date: "2014-02-27T09:57:31.000+01:00".to_time,
          committed_date: "2014-02-27T09:57:31.000+01:00".to_time,
          commit_author_id: an_instance_of(Integer),
          committer_id: an_instance_of(Integer),
          merge_request_diff_id: merge_request_diff_id,
          relative_order: 1,
          sha: Gitlab::Database::ShaAttribute.serialize("570e7b2abdd848b95f2f578043fc23bd6f6fd24d"),
          trailers: {}.to_json
        }
      ]
    end

    it 'inserts the commits into the database en masse' do
      expect(ApplicationRecord).to receive(:legacy_bulk_insert)
        .with(described_class.table_name, rows)

      subject
    end

    it 'creates diff commit users' do
      diff = create(:merge_request_diff, merge_request: merge_request)
      described_class.create_bulk(diff.id, [commits.first], project)

      commit_row = described_class
        .find_by(merge_request_diff_id: diff.id, relative_order: 0)

      commit_user_row =
        MergeRequest::DiffCommitUser.find_by(name: 'Dmitriy Zaporozhets')

      expect(commit_row.commit_author).to eq(commit_user_row)
      expect(commit_row.committer).to eq(commit_user_row)
    end

    context 'when "skip_commit_data: true"' do
      let(:skip_commit_data) { true }

      it 'inserts the commits into the database en masse' do
        rows_with_empty_messages = rows.map { |h| h.merge(message: '') }

        expect(ApplicationRecord).to receive(:legacy_bulk_insert)
          .with(described_class.table_name, rows_with_empty_messages)

        subject
      end
    end

    context 'with dates larger than the DB limit' do
      let(:commits) do
        # This commit's date is "Sun Aug 17 07:12:55 292278994 +0000"
        [project.commit('ba3343bc4fa403a8dfbfcab7fc1a8c29ee34bd69')]
      end

      let(:timestamp) { Time.zone.at((1 << 31) - 1) }
      let(:rows) do
        [{
          message: "Weird commit date\n",
          authored_date: timestamp,
          committed_date: timestamp,
          commit_author_id: an_instance_of(Integer),
          committer_id: an_instance_of(Integer),
          merge_request_diff_id: merge_request_diff_id,
          relative_order: 0,
          sha: Gitlab::Database::ShaAttribute.serialize("ba3343bc4fa403a8dfbfcab7fc1a8c29ee34bd69"),
          trailers: {}.to_json
        }]
      end

      it 'uses a sanitized date' do
        expect(ApplicationRecord).to receive(:legacy_bulk_insert)
          .with(described_class.table_name, rows)

        subject
      end
    end

    context 'with add_organization_to_diff_commit_users feature flag' do
      let(:test_project) { create(:project) }
      let(:test_diff) { create(:merge_request_diff) }
      let(:organization_id) { test_project.organization_id }
      let(:commits) do
        [double(:commit, to_hash: {
          id: 'test123',
          author_name: 'Feature Test Author',
          author_email: 'feature@test.com',
          committer_name: 'Feature Test Committer',
          committer_email: 'committer@test.com',
          authored_date: Time.current,
          committed_date: Time.current,
          message: 'Test commit'
        })]
      end

      context 'when enabled' do
        it 'uses organization_id in hash lookup' do
          users_hash = {
            ['Feature Test Author', 'feature@test.com', organization_id] =>
              instance_double(MergeRequest::DiffCommitUser, id: 1),
            ['Feature Test Committer', 'committer@test.com', organization_id] =>
              instance_double(MergeRequest::DiffCommitUser, id: 2)
          }

          allow(MergeRequest::DiffCommitUser).to receive(:bulk_find_or_create).and_return(users_hash)

          expect { described_class.create_bulk(test_diff.id, commits, test_project) }.not_to raise_error
        end
      end

      context 'when disabled' do
        it 'uses name and email only in hash lookup' do
          stub_feature_flags(add_organization_to_diff_commit_users: false)
          users_hash = {
            ['Feature Test Author', 'feature@test.com'] =>
              instance_double(MergeRequest::DiffCommitUser, id: 1),
            ['Feature Test Committer', 'committer@test.com'] =>
              instance_double(MergeRequest::DiffCommitUser, id: 2)
          }

          allow(MergeRequest::DiffCommitUser).to receive(:bulk_find_or_create).and_return(users_hash)

          expect { described_class.create_bulk(test_diff.id, commits, test_project) }.not_to raise_error
        end
      end
    end
  end

  describe '.prepare_commits_for_bulk_insert' do
    it 'returns the commit hashes and unique user triples' do
      organization_id = create(:organization).id
      commit = double(:commit, to_hash: {
        parent_ids: %w[foo bar],
        author_name: 'a' * 1000,
        author_email: 'a' * 1000,
        committer_name: 'Alice',
        committer_email: 'alice@example.com'
      })
      hashes, triples = described_class.prepare_commits_for_bulk_insert([commit], organization_id)
      expect(hashes).to eq([{
        author_name: 'a' * 512,
        author_email: 'a' * 512,
        committer_name: 'Alice',
        committer_email: 'alice@example.com'
      }])
      expect(triples)
        .to include(['a' * 512, 'a' * 512, organization_id], ['Alice', 'alice@example.com', organization_id])
    end
  end
end
