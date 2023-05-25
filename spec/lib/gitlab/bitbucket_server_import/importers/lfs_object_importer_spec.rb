# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::LfsObjectImporter, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let(:lfs_attributes) do
    {
      'oid' => 'myoid',
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

    it 'logs its progress' do
      allow_next_instance_of(Projects::LfsPointers::LfsDownloadService) do |service|
        allow(service).to receive(:execute).and_return(ServiceResponse.success)
      end

      common_log_message = {
        oid: 'myoid',
        import_stage: 'import_lfs_object',
        class: described_class.name,
        project_id: project.id,
        project_path: project.full_path
      }

      expect(Gitlab::BitbucketServerImport::Logger)
        .to receive(:info).with(common_log_message.merge(message: 'starting')).and_call_original
      expect(Gitlab::BitbucketServerImport::Logger)
        .to receive(:info).with(common_log_message.merge(message: 'finished')).and_call_original

      importer.execute
    end
  end
end
