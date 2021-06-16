# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FillStoreUploads do
  let(:uploads) { table(:uploads) }
  let(:path) { 'uploads/-/system/avatar.jpg' }

  context 'when store is nil' do
    it 'updates store to local' do
      uploads.create!(size: 100.kilobytes,
                     uploader: 'AvatarUploader',
                     path: path,
                     store: nil)

      upload = uploads.find_by(path: path)

      expect { migrate! }.to change { upload.reload.store }.from(nil).to(1)
    end
  end

  context 'when store is set to local' do
    it 'does not update store' do
      uploads.create!(size: 100.kilobytes,
                     uploader: 'AvatarUploader',
                     path: path,
                     store: 1)

      upload = uploads.find_by(path: path)

      expect { migrate! }.not_to change { upload.reload.store }
    end
  end

  context 'when store is set to object storage' do
    it 'does not update store' do
      uploads.create!(size: 100.kilobytes,
                     uploader: 'AvatarUploader',
                     path: path,
                     store: 2)

      upload = uploads.find_by(path: path)

      expect { migrate! }.not_to change { upload.reload.store }
    end
  end
end
