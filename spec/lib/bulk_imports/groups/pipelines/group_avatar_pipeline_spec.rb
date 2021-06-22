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

  describe '#extract' do
    it 'downloads the group avatar' do
      expect_next_instance_of(
        BulkImports::FileDownloadService,
        configuration: context.configuration,
        relative_url: "/groups/source%2Ffull%2Fpath/avatar",
        dir: an_instance_of(String),
        file_size_limit: Avatarable::MAXIMUM_FILE_SIZE,
        allowed_content_types: described_class::ALLOWED_AVATAR_DOWNLOAD_TYPES
      ) do |downloader|
        expect(downloader).to receive(:execute)
      end

      subject.run
    end
  end

  describe '#transform' do
    it 'returns the given data' do
      expect(subject.transform(nil, :value)).to eq(:value)
    end
  end

  describe '#load' do
    it 'updates the group avatar' do
      avatar_path = 'spec/fixtures/dk.png'
      data = { filepath: fixture_file_upload(avatar_path) }

      expect { subject.load(context, data) }.to change(group, :avatar)

      expect(FileUtils.identical?(avatar_path, group.avatar.file.file)).to eq(true)
    end

    it 'raises an error when the avatar upload fails' do
      avatar_path = 'spec/fixtures/aosp_manifest.xml'
      data = { filepath: fixture_file_upload(avatar_path) }

      expect { subject.load(context, data) }.to raise_error(
        described_class::GroupAvatarLoadingError,
        "Avatar file format is not supported. Please try one of the following supported formats: image/png, image/jpeg, image/gif, image/bmp, image/tiff, image/vnd.microsoft.icon"
      )
    end
  end
end
