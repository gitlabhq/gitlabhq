# frozen_string_literal: true

class RenameableUpload < SimpleDelegator
  attr_accessor :original_filename

  # Get a fixture file with a new unique name, and the same extension
  def self.unique_file(name)
    upload = new(Rack::Test::UploadedFile.new("spec/fixtures/#{name}"))
    ext = File.extname(name)
    new_name = File.basename(FactoryBot.generate(:filename), '.*')
    upload.original_filename = new_name + ext

    upload
  end
end
