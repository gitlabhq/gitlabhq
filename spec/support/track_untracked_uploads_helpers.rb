module TrackUntrackedUploadsHelpers
  def rails_sample_jpg_attrs
    @rails_sample_jpg_attrs ||= {
      "size"       => File.size(rails_sample_file_path),
      "checksum"   => Digest::SHA256.file(rails_sample_file_path).hexdigest
    }
  end

  def rails_sample_file_path
    Rails.root.join('spec', 'fixtures', 'rails_sample.jpg')
  end
end
