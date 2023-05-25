# frozen_string_literal: true

module PendingDirectUploadHelpers
  def prepare_pending_direct_upload(path, time)
    travel_to time do
      ObjectStorage::PendingDirectUpload.prepare(
        location_identifier,
        path
      )
    end
  end

  def expect_to_have_pending_direct_upload(path)
    expect(ObjectStorage::PendingDirectUpload.exists?(location_identifier, path)).to eq(true)
  end

  def expect_not_to_have_pending_direct_upload(path)
    expect(ObjectStorage::PendingDirectUpload.exists?(location_identifier, path)).to eq(false)
  end

  def expect_pending_uploaded_object_not_to_exist(path)
    expect { fog_connection.get_object(location_identifier.to_s, path) }.to raise_error(Excon::Error::NotFound)
  end

  def expect_pending_uploaded_object_to_exist(path)
    expect { fog_connection.get_object(location_identifier.to_s, path) }.not_to raise_error
  end

  def total_pending_direct_uploads
    ObjectStorage::PendingDirectUpload.with_redis do |redis|
      redis.hlen(ObjectStorage::PendingDirectUpload::KEY)
    end
  end
end
