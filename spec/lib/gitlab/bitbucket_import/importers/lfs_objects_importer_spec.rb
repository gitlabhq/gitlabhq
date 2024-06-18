# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::LfsObjectsImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
        credentials: { 'token' => 'token' }
      }
    )
  end

  let(:lfs_attributes) do
    {
      oid: 'a' * 64,
      size: 1,
      link: 'http://www.gitlab.com/lfs_objects/oid',
      headers: { 'X-Some-Header' => '456' }
    }
  end

  let(:lfs_download_object) { LfsDownloadObject.new(**lfs_attributes) }

  let(:common_log_messages) do
    {
      import_stage: 'import_lfs_objects',
      class: described_class.name,
      project_id: project.id,
      project_path: project.full_path
    }
  end

  describe '#execute' do
    context 'when lfs is enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(true)
      end

      it 'imports each lfs object in parallel' do
        importer = described_class.new(project)

        expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
          expect(service).to receive(:each_list_item).and_yield(lfs_download_object)
        end

        expect(Gitlab::BitbucketImport::ImportLfsObjectWorker).to receive(:perform_in)
          .with(an_instance_of(Float), project.id,
            lfs_attributes.stringify_keys, start_with(Gitlab::JobWaiter::KEY_PREFIX))

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(1)
      end

      it 'logs its progress' do
        importer = described_class.new(project)

        expect(Gitlab::BitbucketImport::Logger)
          .to receive(:info).with(common_log_messages.merge(message: 'starting')).and_call_original
        expect(Gitlab::BitbucketImport::Logger)
          .to receive(:info).with(common_log_messages.merge(message: 'finished')).and_call_original

        importer.execute
      end

      context 'when LFS list download fails' do
        let(:exception) { StandardError.new('Invalid Project URL') }

        before do
          allow_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |service|
            allow(service).to receive(:each_list_item).and_raise(exception)
          end
        end

        it 'rescues and logs the exception' do
          importer = described_class.new(project)

          expect(Gitlab::Import::ImportFailureService)
            .to receive(:track)
            .with(
              project_id: project.id,
              exception: exception,
              error_source: described_class.name
            ).and_call_original

          expect(Gitlab::BitbucketImport::ImportLfsObjectWorker).not_to receive(:perform_in)

          waiter = importer.execute

          expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
          expect(waiter.jobs_remaining).to eq(0)
        end
      end
    end

    context 'when LFS is not enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(false)
      end

      it 'logs progress but does nothing' do
        importer = described_class.new(project)

        expect(Gitlab::BitbucketImport::Logger).to receive(:info).twice
        expect(Gitlab::BitbucketImport::ImportLfsObjectWorker).not_to receive(:perform_in)

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(0)
      end
    end
  end
end
