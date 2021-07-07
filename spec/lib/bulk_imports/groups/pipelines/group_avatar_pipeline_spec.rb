# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::GroupAvatarPipeline do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }

  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      group: group,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_name: 'My Destination Group',
      destination_namespace: group.full_path
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject { described_class.new(context) }

  describe '#run' do
    it 'updates the group avatar' do
      avatar_path = 'spec/fixtures/dk.png'
      stub_file_download(
        avatar_path,
        configuration: context.configuration,
        relative_url: "/groups/source%2Ffull%2Fpath/avatar",
        dir: an_instance_of(String),
        file_size_limit: Avatarable::MAXIMUM_FILE_SIZE,
        allowed_content_types: described_class::ALLOWED_AVATAR_DOWNLOAD_TYPES
      )

      expect { subject.run }.to change(context.group, :avatar)

      expect(context.group.avatar.filename).to eq(File.basename(avatar_path))
    end

    it 'raises an error when the avatar upload fails' do
      avatar_path = 'spec/fixtures/aosp_manifest.xml'
      stub_file_download(
        avatar_path,
        configuration: context.configuration,
        relative_url: "/groups/source%2Ffull%2Fpath/avatar",
        dir: an_instance_of(String),
        file_size_limit: Avatarable::MAXIMUM_FILE_SIZE,
        allowed_content_types: described_class::ALLOWED_AVATAR_DOWNLOAD_TYPES
      )

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger).to receive(:error)
          .with(
            bulk_import_id: context.bulk_import.id,
            bulk_import_entity_id: context.entity.id,
            bulk_import_entity_type: context.entity.source_type,
            context_extra: context.extra,
            exception_class: "BulkImports::Groups::Pipelines::GroupAvatarPipeline::GroupAvatarLoadingError",
            exception_message: "Avatar file format is not supported. Please try one of the following supported formats: image/png, image/jpeg, image/gif, image/bmp, image/tiff, image/vnd.microsoft.icon",
            pipeline_class: "BulkImports::Groups::Pipelines::GroupAvatarPipeline",
            pipeline_step: :loader
          )
      end

      expect { subject.run }.to change(BulkImports::Failure, :count)
    end
  end

  def stub_file_download(filepath = 'file/path.png', **params)
    expect_next_instance_of(BulkImports::FileDownloadService, params.presence) do |downloader|
      expect(downloader).to receive(:execute).and_return(filepath)
    end
  end
end
