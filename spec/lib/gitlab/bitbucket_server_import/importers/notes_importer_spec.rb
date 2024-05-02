# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::NotesImporter, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug', 'bitbucket_server_notes_separate_worker' => true },
        credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
      }
    )
  end

  let_it_be(:pull_request_1) { create(:merge_request, source_project: project, iid: 100, source_branch: 'branch_1') }
  let_it_be(:pull_request_2) { create(:merge_request, source_project: project, iid: 101, source_branch: 'branch_2') }

  let(:merge_event) do
    instance_double(
      BitbucketServer::Representation::Activity,
      id: 3,
      comment?: false,
      merge_event?: true,
      approved_event?: false,
      to_hash: {
        id: 3
      }
    )
  end

  let(:approved_event) do
    instance_double(
      BitbucketServer::Representation::Activity,
      id: 4,
      comment?: false,
      merge_event?: false,
      approved_event?: true,
      to_hash: {
        id: 4
      }
    )
  end

  let(:pr_note) do
    instance_double(
      BitbucketServer::Representation::Comment,
      id: 5,
      note: 'Hello world',
      parent_comment: nil,
      to_hash: {
        id: 5
      }
    )
  end

  let(:pr_comment) do
    instance_double(
      BitbucketServer::Representation::Activity,
      id: 5,
      comment?: true,
      inline_comment?: false,
      merge_event?: false,
      comment: pr_note)
  end

  let(:pr_inline_note) do
    instance_double(
      BitbucketServer::Representation::PullRequestComment,
      id: 6,
      file_type: 'ADDED',
      note: 'Hello world inline',
      parent_comment: nil,
      to_hash: {
        id: 6
      }
    )
  end

  let(:pr_inline_comment) do
    instance_double(
      BitbucketServer::Representation::Activity,
      id: 6,
      comment?: true,
      inline_comment?: true,
      merge_event?: false,
      comment: pr_inline_note
    )
  end

  subject(:importer) { described_class.new(project) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    context 'when bitbucket_server_notes_separate_worker is false' do
      # For performance reasons (using as many `let_it_be` as possible), these `let_it_be` is purposely duplicated
      # so that we don't need to use a variable for `bitbucket_server_notes_separate_worker`,
      # which will end up needing to use `let!` for `:pull_request_1` and `:pull_request_2`
      # this duplication will be removed once `bitbucket_server_notes_separate_worker` has been cleaned up
      let_it_be(:project) do
        create(:project, :import_started,
          import_data_attributes: {
            data: { 'project_key' => 'key', 'repo_slug' => 'slug', 'bitbucket_server_notes_separate_worker' => false },
            credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
          }
        )
      end

      let_it_be(:pull_request_1) do
        create(:merge_request, source_project: project, iid: 100, source_branch: 'branch_1')
      end

      let_it_be(:pull_request_2) do
        create(:merge_request, source_project: project, iid: 101, source_branch: 'branch_2')
      end

      it 'schedules a job to import notes for each corresponding merge request', :aggregate_failures do
        expect(Gitlab::BitbucketServerImport::ImportPullRequestNotesWorker).to receive(:perform_in).twice

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(2)
        expect(Gitlab::Cache::Import::Caching.values_from_set(importer.already_processed_cache_key))
          .to match_array(%w[100 101])
      end

      context 'when pull request was already processed' do
        before do
          Gitlab::Cache::Import::Caching.set_add(importer.already_processed_cache_key, "100")
        end

        it 'does not schedule job for processed merge requests', :aggregate_failures do
          expect(Gitlab::BitbucketServerImport::ImportPullRequestNotesWorker).to receive(:perform_in).once

          waiter = importer.execute

          expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
          expect(waiter.jobs_remaining).to eq(2)
        end
      end
    end

    context 'when pull request was already processed' do
      before do
        Gitlab::Cache::Import::Caching.set_add(importer.send(:merge_request_processed_cache_key), "100")
        Gitlab::Cache::Import::Caching.set_add(importer.send(:merge_request_processed_cache_key), "101")
      end

      it 'does not schedule job for processed merge requests', :aggregate_failures do
        expect(Gitlab::BitbucketServerImport::ImportPullRequestNotesWorker).not_to receive(:perform_in)

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(0)
      end
    end

    context 'when PR has comments' do
      before do
        allow_next_instance_of(BitbucketServer::Client) do |instance|
          allow(instance).to receive(:activities).with('key', 'slug', 100).and_return([pr_comment])
          allow(instance).to receive(:activities).with('key', 'slug', 101).and_return([])
        end
      end

      it 'imports the stand alone comments' do
        expect(Gitlab::BitbucketServerImport::ImportPullRequestNotesWorker).to receive(:perform_in).with(
          anything,
          project.id,
          hash_including(
            iid: 100,
            comment_type: 'standalone_notes',
            comment: hash_including('id' => 5)
          ),
          anything
        )

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(1)
        expect(Gitlab::Cache::Import::Caching.read(importer.job_waiter_remaining_cache_key)).to eq('1')
        expect(Gitlab::Cache::Import::Caching.values_from_set(importer.already_processed_cache_key))
          .to match_array(%w[comment-5])
        expect(Gitlab::Cache::Import::Caching.values_from_set(importer.send(:merge_request_processed_cache_key)))
          .to match_array(%w[100 101])
      end
    end

    context 'when PR has inline comment' do
      before do
        allow_next_instance_of(BitbucketServer::Client) do |instance|
          allow(instance).to receive(:activities).with('key', 'slug', 100).and_return([pr_inline_comment])
          allow(instance).to receive(:activities).with('key', 'slug', 101).and_return([])
        end
      end

      it 'imports the inline comment' do
        expect(Gitlab::BitbucketServerImport::ImportPullRequestNotesWorker).to receive(:perform_in).with(
          anything,
          project.id,
          hash_including(
            iid: 100,
            comment_type: 'inline',
            comment: hash_including('id' => 6)
          ),
          anything
        )

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(1)
        expect(Gitlab::Cache::Import::Caching.read(importer.job_waiter_remaining_cache_key)).to eq('1')
        expect(Gitlab::Cache::Import::Caching.values_from_set(importer.already_processed_cache_key))
          .to match_array(%w[comment-6])
        expect(Gitlab::Cache::Import::Caching.values_from_set(importer.send(:merge_request_processed_cache_key)))
          .to match_array(%w[100 101])
      end
    end

    context 'when PR has a merge event' do
      before do
        allow_next_instance_of(BitbucketServer::Client) do |instance|
          allow(instance).to receive(:activities).with('key', 'slug', 100).and_return([merge_event])
          allow(instance).to receive(:activities).with('key', 'slug', 101).and_return([])
        end
      end

      it 'imports the merge event' do
        expect(Gitlab::BitbucketServerImport::ImportPullRequestNotesWorker).to receive(:perform_in).with(
          anything,
          project.id,
          hash_including(
            iid: 100,
            comment_type: 'merge_event',
            comment: hash_including('id' => 3)
          ),
          anything
        )

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(1)
        expect(Gitlab::Cache::Import::Caching.read(importer.job_waiter_remaining_cache_key)).to eq('1')
        expect(Gitlab::Cache::Import::Caching.values_from_set(importer.already_processed_cache_key))
          .to match_array(%w[activity-3])
        expect(Gitlab::Cache::Import::Caching.values_from_set(importer.send(:merge_request_processed_cache_key)))
          .to match_array(%w[100 101])
      end
    end

    context 'when PR has an approved event' do
      before do
        allow_next_instance_of(BitbucketServer::Client) do |instance|
          allow(instance).to receive(:activities).with('key', 'slug', 100).and_return([approved_event])
          allow(instance).to receive(:activities).with('key', 'slug', 101).and_return([])
        end
      end

      it 'imports the approved event' do
        expect(Gitlab::BitbucketServerImport::ImportPullRequestNotesWorker).to receive(:perform_in).with(
          anything,
          project.id,
          hash_including(
            iid: 100,
            comment_type: 'approved_event',
            comment: hash_including('id' => 4)
          ),
          anything
        )

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(1)
        expect(Gitlab::Cache::Import::Caching.read(importer.job_waiter_remaining_cache_key)).to eq('1')
        expect(Gitlab::Cache::Import::Caching.values_from_set(importer.already_processed_cache_key))
          .to match_array(%w[activity-4])
        expect(Gitlab::Cache::Import::Caching.values_from_set(importer.send(:merge_request_processed_cache_key)))
          .to match_array(%w[100 101])
      end
    end
  end
end
