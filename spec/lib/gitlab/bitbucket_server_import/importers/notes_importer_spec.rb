# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::NotesImporter, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
        credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
      }
    )
  end

  let_it_be(:merge_request_1) { create(:merge_request, source_project: project, iid: 100, source_branch: 'branch_1') }
  let_it_be(:merge_request_2) { create(:merge_request, source_project: project, iid: 101, source_branch: 'branch_2') }

  subject(:importer) { described_class.new(project) }

  describe '#execute', :clean_gitlab_redis_cache do
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
end
