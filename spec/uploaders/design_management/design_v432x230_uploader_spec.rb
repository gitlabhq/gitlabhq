# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DesignManagement::DesignV432x230Uploader do
  include CarrierWave::Test::Matchers

  let(:model) { create(:design_action, :with_image_v432x230) }
  let(:upload) { create(:upload, :design_action_image_v432x230_upload, model: model) }

  subject(:uploader) { described_class.new(model, :image_v432x230) }

  it_behaves_like 'builds correct paths',
    store_dir: %r{uploads/-/system/design_management/action/image_v432x230/},
    upload_path: %r{uploads/-/system/design_management/action/image_v432x230/},
    relative_path: %r{uploads/-/system/design_management/action/image_v432x230/},
    absolute_path: %r{#{CarrierWave.root}/uploads/-/system/design_management/action/image_v432x230/}

  context 'object_store is REMOTE' do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths',
      store_dir: %r{design_management/action/image_v432x230/},
      upload_path: %r{design_management/action/image_v432x230/},
      relative_path: %r{design_management/action/image_v432x230/}
  end

  describe "#migrate!" do
    before do
      uploader.store!(fixture_file_upload('spec/fixtures/dk.png'))
      stub_uploads_object_storage
    end

    it_behaves_like 'migrates', to_store: described_class::Store::REMOTE
    it_behaves_like 'migrates', from_store: described_class::Store::REMOTE, to_store: described_class::Store::LOCAL
  end

  it 'resizes images', :aggregate_failures do
    image_loader = CarrierWave::Test::Matchers::ImageLoader
    original_file = fixture_file_upload('spec/fixtures/dk.png')
    uploader.store!(original_file)

    expect(
      image_loader.load_image(original_file.tempfile.path)
    ).to have_attributes(
      width: 460,
      height: 322
    )
    expect(
      image_loader.load_image(uploader.file.file)
    ).to have_attributes(
      width: 329,
      height: 230
    )
  end

  context 'accept allowlisted file content type' do
    # We need to feed through a valid path, but we force the parsed mime type
    # in a stub below so we can set any path.
    let_it_be(:path) { File.join('spec', 'fixtures', 'dk.png') }

    where(:mime_type) { described_class::MIME_TYPE_ALLOWLIST }

    with_them do
      include_context 'force content type detection to mime_type'

      it_behaves_like 'accepted carrierwave upload'
    end
  end

  context 'upload denylisted file content type' do
    let_it_be(:path) { File.join('spec', 'fixtures', 'logo_sample.svg') }

    it_behaves_like 'denied carrierwave upload'
  end

  context 'upload misnamed denylisted file content type' do
    let_it_be(:path) { File.join('spec', 'fixtures', 'not_a_png.png') }

    it_behaves_like 'denied carrierwave upload'
  end
end
