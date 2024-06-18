# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::IssuesNotesImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started) }
  let_it_be(:issue_1) { create(:issue, project: project) }
  let_it_be(:issue_2) { create(:issue, project: project) }

  subject(:importer) { described_class.new(project) }

  describe '#execute' do
    it 'imports the notes from each issue in parallel' do
      expect(Gitlab::BitbucketImport::ImportIssueNotesWorker).to receive(:perform_in).twice

      waiter = importer.execute

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(2)
      expect(Gitlab::Cache::Import::Caching.values_from_set(importer.already_enqueued_cache_key))
        .to match_array(%w[1 2])
    end

    context 'when an error is raised' do
      before do
        allow(importer).to receive(:mark_as_enqueued).and_raise(StandardError)
      end

      it 'tracks the failure and does not fail' do
        expect(Gitlab::Import::ImportFailureService).to receive(:track).once

        expect(importer.execute).to be_a(Gitlab::JobWaiter)
      end
    end

    context 'when issue was already enqueued' do
      before do
        Gitlab::Cache::Import::Caching.set_add(importer.already_enqueued_cache_key, 2)
      end

      it 'does not schedule job for enqueued issues' do
        expect(Gitlab::BitbucketImport::ImportIssueNotesWorker).to receive(:perform_in).once

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(2)
      end
    end
  end
end
