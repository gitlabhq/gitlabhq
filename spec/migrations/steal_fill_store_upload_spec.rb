# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20181105201455_steal_fill_store_upload.rb')

describe StealFillStoreUpload, :migration do
  let(:uploads) { table(:uploads) }

  describe '#up' do
    it 'steals the FillStoreUpload background migration' do
      expect(Gitlab::BackgroundMigration).to receive(:steal).with('FillStoreUpload').and_call_original

      migrate!
    end

    it 'does not run migration if not needed' do
      uploads.create(size: 100.kilobytes,
                     uploader: 'AvatarUploader',
                     path: 'uploads/-/system/avatar.jpg',
                     store: 1)

      expect_any_instance_of(Gitlab::BackgroundMigration::FillStoreUpload).not_to receive(:perform)

      migrate!
    end

    it 'ensures all rows are migrated' do
      uploads.create(size: 100.kilobytes,
                     uploader: 'AvatarUploader',
                     path: 'uploads/-/system/avatar.jpg',
                     store: nil)

      expect_any_instance_of(Gitlab::BackgroundMigration::FillStoreUpload).to receive(:perform).and_call_original

      expect do
        migrate!
      end.to change { uploads.where(store: nil).count }.from(1).to(0)
    end
  end
end
