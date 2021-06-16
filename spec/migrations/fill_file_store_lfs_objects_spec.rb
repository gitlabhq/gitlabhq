# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FillFileStoreLfsObjects do
  let(:lfs_objects) { table(:lfs_objects) }
  let(:oid) { 'b804383982bb89b00e828e3f44c038cc991d3d1768009fc39ba8e2c081b9fb75' }

  context 'when file_store is nil' do
    it 'updates file_store to local' do
      lfs_objects.create!(oid: oid, size: 1062, file_store: nil)
      lfs_object = lfs_objects.find_by(oid: oid)

      expect { migrate! }.to change { lfs_object.reload.file_store }.from(nil).to(1)
    end
  end

  context 'when file_store is set to local' do
    it 'does not update file_store' do
      lfs_objects.create!(oid: oid, size: 1062, file_store: 1)
      lfs_object = lfs_objects.find_by(oid: oid)

      expect { migrate! }.not_to change { lfs_object.reload.file_store }
    end
  end

  context 'when file_store is set to object storage' do
    it 'does not update file_store' do
      lfs_objects.create!(oid: oid, size: 1062, file_store: 2)
      lfs_object = lfs_objects.find_by(oid: oid)

      expect { migrate! }.not_to change { lfs_object.reload.file_store }
    end
  end
end
