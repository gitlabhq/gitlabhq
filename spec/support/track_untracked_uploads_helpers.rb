module TrackUntrackedUploadsHelpers
  def uploaded_file
    fixture_path = Rails.root.join('spec', 'fixtures', 'rails_sample.jpg')
    fixture_file_upload(fixture_path)
  end
end
