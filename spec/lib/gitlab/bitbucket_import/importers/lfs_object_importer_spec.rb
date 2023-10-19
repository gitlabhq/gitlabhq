# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::LfsObjectImporter, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let(:oid) { 'a' * 64 }

  let(:lfs_attributes) do
    {
      'oid' => oid,
      'size' => 1,
      'link' => 'http://www.gitlab.com/lfs_objects/oid',
      'headers' => { 'X-Some-Header' => '456' }
    }
  end

  let(:importer) { described_class.new(project, lfs_attributes) }

  describe '#execute' do
    it 'calls the LfsDownloadService with the lfs object attributes' do
      expect_next_instance_of(
        Projects::LfsPointers::LfsDownloadService, project, have_attributes(lfs_attributes)
      ) do |service|
        expect(service).to receive(:execute).and_return(ServiceResponse.success)
      end

      importer.execute
    end

    context 'when the object is not valid' do
      let(:oid) { 'invalid' }

      it 'tracks the validation errors and does not continue' do
        expect(Gitlab::Import::ImportFailureService).to receive(:track).once

        expect(Projects::LfsPointers::LfsDownloadService).not_to receive(:new)

        importer.execute
      end
    end

    context 'when an error is raised' do
      let(:exception) { StandardError.new('messsage') }

      before do
        allow_next_instance_of(Projects::LfsPointers::LfsDownloadService) do |service|
          allow(service).to receive(:execute).and_raise(exception)
        end
      end

      it 'rescues and logs the exception' do
        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track)
          .with(hash_including(exception: exception))

        importer.execute
      end
    end

    it 'logs its progress' do
      allow_next_instance_of(Projects::LfsPointers::LfsDownloadService) do |service|
        allow(service).to receive(:execute).and_return(ServiceResponse.success)
      end

      common_log_message = {
        oid: oid,
        import_stage: 'import_lfs_object',
        class: described_class.name,
        project_id: project.id,
        project_path: project.full_path
      }

      expect(Gitlab::BitbucketImport::Logger)
        .to receive(:info).with(common_log_message.merge(message: 'starting')).and_call_original
      expect(Gitlab::BitbucketImport::Logger)
        .to receive(:info).with(common_log_message.merge(message: 'finished')).and_call_original

      importer.execute
    end
  end
end
