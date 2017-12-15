module TrackUntrackedUploadsHelpers
  def uploaded_file
    fixture_path = Rails.root.join('spec', 'fixtures', 'rails_sample.jpg')
    fixture_file_upload(fixture_path)
  end

  def ensure_temporary_tracking_table_exists
    Gitlab::BackgroundMigration::PrepareUntrackedUploads.new.send(:ensure_temporary_tracking_table_exists)
  end

  def drop_temp_table_if_exists
    ActiveRecord::Base.connection.drop_table(:untracked_files_for_uploads) if ActiveRecord::Base.connection.table_exists?(:untracked_files_for_uploads)
  end

  def create_or_update_appearance(attrs)
    a = Appearance.first_or_initialize(title: 'foo', description: 'bar')
    a.update!(attrs)
    a
  end
end
