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
    it { is_expected.to belong_to(:merge_request_commits_metadata) }
  end

  describe 'scopes' do
    describe '.for_merge_request_diff' do
      let_it_be(:merge_request2) { create(:merge_request) }
      let_it_be(:diff_1) { create(:merge_request_diff, merge_request: merge_request2) }
      let_it_be(:commit_1) { create(:merge_request_diff_commit, merge_request_diff: diff_1, relative_order: 0) }
      let_it_be(:commit_2) { create(:merge_request_diff_commit, merge_request_diff: diff_1, relative_order: 1) }

      before do
        merge_request_diff_2 = create(:merge_request_diff, merge_request: merge_request2)
        create(:merge_request_diff_commit, merge_request_diff: merge_request_diff_2)
      end

      it 'returns commits for the specified merge request diff' do
        expect(described_class.for_merge_request_diff(diff_1.id)).to contain_exactly(commit_1, commit_2)
      end

      it 'returns empty collection when no commits exist for the diff' do
        expect(described_class.for_merge_request_diff(non_existing_record_id)).to be_empty
      end

      it 'returns empty collection when diff_id is nil' do
        expect(described_class.for_merge_request_diff(nil)).to be_empty
      end
    end
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
    def create_bulk(merge_request_diff_id)
      described_class.create_bulk(
        merge_request_diff_id,
        commits,
        project,
        skip_commit_data: skip_commit_data
      )
    end

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
          trailers: {}.to_json,
          merge_request_commits_metadata_id: an_instance_of(Integer),
          project_id: an_instance_of(Integer)
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
          trailers: {}.to_json,
          merge_request_commits_metadata_id: an_instance_of(Integer),
          project_id: an_instance_of(Integer)
        }
      ]
    end

    it 'inserts the commits into the database en masse' do
      expect(ApplicationRecord).to receive(:legacy_bulk_insert)
        .with(described_class.table_name, rows)

      create_bulk(merge_request_diff_id)
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

    context 'when merge_request_diff_commits_partition is disabled' do
      before do
        stub_feature_flags(merge_request_diff_commits_partition: false)
      end

      it 'does not set `project_id` attribute' do
        expected_attributes = rows.map { |row| row.except(:project_id) }

        expect(ApplicationRecord).to receive(:legacy_bulk_insert)
          .with(described_class.table_name, expected_attributes)

        create_bulk(merge_request_diff_id)
      end
    end

    context 'for merge_request_commits_metadata' do
      let(:merge_request_diff) { create(:merge_request_diff, merge_request: merge_request) }
      let(:merge_request_diff_id) { merge_request_diff.id }

      it 'also inserts all commit metadata to merge_request_commits_metadata' do
        create_bulk(merge_request_diff_id)

        merge_request_diff.merge_request_diff_commits.each do |mrdc|
          metadata = mrdc.merge_request_commits_metadata
          commit = commits[mrdc.relative_order]
          row = rows[mrdc.relative_order]
          commit_author = MergeRequest::DiffCommitUser.find_by(name: commit.author_name)
          committer = MergeRequest::DiffCommitUser.find_by(name: commit.committer_name)

          expect(metadata.commit_author).to eq(commit_author)
          expect(metadata.committer).to eq(committer)
          expect(metadata.authored_date).to eq(row[:authored_date])
          expect(metadata.committed_date).to eq(row[:committed_date])
          expect(metadata.sha).to eq(commit.sha)
          expect(metadata.message).to eq(commit.message)
          expect(metadata.trailers).to eq({})
          expect(metadata.project_id).to eq(project.id)
        end
      end

      context 'when there are already existing commits metadata record for some SHAs' do
        it 'does not create a new merge_request_commits_metadata record' do
          # Call create_bulk to create bulk records and simulate existing records
          # so calling it again for a new `MergeRequestDiff` shouldn't create
          # new commit metadata records.
          create_bulk(merge_request_diff_id)

          expect { create_bulk(create(:merge_request_diff).id) }
            .not_to change { MergeRequest::CommitsMetadata.count }
        end
      end

      context 'when merge_request_diff_commits_dedup is disabled' do
        before do
          stub_feature_flags(merge_request_diff_commits_dedup: false)
        end

        it 'does not create merge_request_commits_metadata records' do
          expect { create_bulk(merge_request_diff_id) }.not_to change { MergeRequest::CommitsMetadata.count }
        end
      end
    end

    context 'when "skip_commit_data: true"' do
      let(:skip_commit_data) { true }

      it 'inserts the commits into the database en masse' do
        rows_with_empty_messages = rows.map { |h| h.merge(message: '') }

        expect(ApplicationRecord).to receive(:legacy_bulk_insert)
          .with(described_class.table_name, rows_with_empty_messages)

        create_bulk(merge_request_diff_id)
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
          trailers: {}.to_json,
          merge_request_commits_metadata_id: an_instance_of(Integer),
          project_id: an_instance_of(Integer)
        }]
      end

      it 'uses a sanitized date' do
        expect(ApplicationRecord).to receive(:legacy_bulk_insert)
          .with(described_class.table_name, rows)

        create_bulk(merge_request_diff_id)
      end
    end

    context 'with organization_id in lookup' do
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
          message: 'Test commit',
          project_id: test_project.id
        })]
      end

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

  describe '#merge_request_commits_metadata' do
    let_it_be(:project) { create(:project) }
    let_it_be(:commits_metadata_1) { create(:merge_request_commits_metadata, project: project) }
    let_it_be(:commits_metadata_2) { create(:merge_request_commits_metadata, project: project) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let_it_be(:merge_request_diff) { create(:merge_request_diff, merge_request: merge_request) }

    let_it_be(:merge_request_diff_commit) do
      create(
        :merge_request_diff_commit,
        merge_request_diff: merge_request_diff,
        merge_request_commits_metadata_id: commits_metadata_1.id
      )
    end

    it 'returns associated merge request commits metadata record' do
      expect(merge_request_diff_commit.merge_request_commits_metadata)
        .to eq(commits_metadata_1)
    end
  end

  describe '#project_id' do
    let(:merge_request_diff) { create(:merge_request_diff) }
    let(:merge_request_diff_commit) { create(:merge_request_diff_commit, merge_request_diff: merge_request_diff) }

    it 'returns the project ID of the associated merge request diff' do
      expect(merge_request_diff_commit.project_id).to eq(merge_request_diff.project_id)
    end
  end

  describe 'methods delegated to merge_request_commits_metadata' do
    let_it_be(:project) { create(:project) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let_it_be(:merge_request_diff) { create(:merge_request_diff, merge_request: merge_request) }

    let_it_be(:commits_metadata) do
      create(
        :merge_request_commits_metadata,
        project: project,
        message: 'This is a commit metadata message'
      )
    end

    let_it_be(:diff_commit_with_metadata) do
      create(
        :merge_request_diff_commit,
        merge_request_diff: merge_request_diff,
        merge_request_commits_metadata_id: commits_metadata.id,
        commit_author: create(:merge_request_diff_commit_user),
        committer: create(:merge_request_diff_commit_user),
        authored_date: 2.days.ago,
        committed_date: 2.days.ago,
        message: 'This is a diff commit message',
        relative_order: 0
      )
    end

    let_it_be(:diff_commit_without_metadata) do
      create(
        :merge_request_diff_commit,
        merge_request_diff: merge_request_diff,
        commit_author: create(:merge_request_diff_commit_user),
        committer: create(:merge_request_diff_commit_user),
        authored_date: 2.days.ago,
        committed_date: 2.days.ago,
        message: 'This is a diff commit message',
        relative_order: 1
      )
    end

    shared_examples_for 'delegated method to merge_request_commits_metadata' do |delegated_method|
      context 'when diff commit has merge_request_commits_metadata_id' do
        it 'returns data from merge_request_commits_metadata' do
          method_value = diff_commit_with_metadata.public_send(delegated_method)
          method_value = method_value.to_i if method_value.is_a?(Time)
          expected_method_value = commits_metadata.public_send(delegated_method)
          expected_method_value = expected_method_value.to_i if expected_method_value.is_a?(Time)

          expect(method_value).to eq(expected_method_value)
        end

        context 'when merge_request_diff_commits_dedup is disabled' do
          before do
            stub_feature_flags(merge_request_diff_commits_dedup: false)
          end

          it 'returns data from diff commit' do
            expect(diff_commit_with_metadata.public_send(delegated_method))
              .not_to eq(commits_metadata.public_send(delegated_method))
          end
        end
      end

      context 'when diff commit has no merge_request_commits_metadata_id' do
        it 'returns data from diff commit' do
          expect(diff_commit_without_metadata.public_send(delegated_method))
            .to be_present
        end
      end

      context 'when merge_request_commits_metadata_id attribute is missing' do
        before do
          allow(diff_commit_without_metadata).to receive(:merge_request_commits_metadata_id)
                                             .and_raise(ActiveModel::MissingAttributeError)
        end

        it 'returns data from diff commit and tracks an exception' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            instance_of(ActiveModel::MissingAttributeError),
            diff_commit_without_metadata.attributes
          )

          expect(diff_commit_without_metadata.public_send(delegated_method)).to be_present
        end
      end
    end

    describe '#authored_date' do
      it_behaves_like 'delegated method to merge_request_commits_metadata', :authored_date
    end

    describe '#committed_date' do
      it_behaves_like 'delegated method to merge_request_commits_metadata', :committed_date
    end

    describe '#sha' do
      it_behaves_like 'delegated method to merge_request_commits_metadata', :sha
    end

    describe '#commit_author' do
      it_behaves_like 'delegated method to merge_request_commits_metadata', :commit_author
    end

    describe '#committer' do
      it_behaves_like 'delegated method to merge_request_commits_metadata', :committer
    end

    describe '#message' do
      it 'returns blank string' do
        expect(diff_commit_with_metadata.message).to eq('')
        expect(diff_commit_without_metadata.message).to eq('')
      end

      context 'when disable_message_attribute_on_mr_diff_commits is disabled' do
        before do
          stub_feature_flags(disable_message_attribute_on_mr_diff_commits: false)
        end

        it_behaves_like 'delegated method to merge_request_commits_metadata', :message
      end
    end
  end
end
