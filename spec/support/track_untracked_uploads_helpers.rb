module TrackUntrackedUploadsHelpers
  def uploaded_file
    fixture_path = Rails.root.join('spec', 'fixtures', 'rails_sample.jpg')
    fixture_file_upload(fixture_path)
  end

  def recreate_temp_table_if_dropped
    TrackUntrackedUploads.new.ensure_temporary_tracking_table_exists
  end

  RSpec.configure do |config|
    config.after(:each, :temp_table_may_drop) do
      recreate_temp_table_if_dropped
    end

    config.after(:context, :temp_table_may_drop) do
      recreate_temp_table_if_dropped
    end
  end
end
