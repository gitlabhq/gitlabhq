require 'fileutils'

module UploadHelpers
  extend self

  def uploaded_image_temp_path
    basename = 'banana_sample.gif'
    orig_path = File.join(Rails.root, 'spec', 'fixtures', basename)
    tmp_path = File.join(Rails.root, 'tmp', 'tests', basename)
    # Because we use 'move_to_store' on all uploaders, we create a new
    # tempfile on each call: the file we return here will be renamed in most
    # cases.
    FileUtils.copy(orig_path, tmp_path)
    tmp_path
  end
end
