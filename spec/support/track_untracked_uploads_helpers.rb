module TrackUntrackedUploadsHelpers
  def uploaded_file
    fixture_path = Rails.root.join('spec/fixtures/rails_sample.jpg')
    fixture_file_upload(fixture_path)
  end

  def ensure_temporary_tracking_table_exists
    Gitlab::BackgroundMigration::PrepareUntrackedUploads.new.send(:ensure_temporary_tracking_table_exists)
  end

  def create_or_update_appearance(attrs)
    a = Appearance.first_or_initialize(title: 'foo', description: 'bar')
    a.update!(attrs)
    a
  end
end
