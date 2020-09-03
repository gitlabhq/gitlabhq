# frozen_string_literal: true

# This context provides one temporary file for the multipart spec
#
# Here are the available variables:
# - uploaded_file
# - uploaded_filepath
# - filename
# - remote_id
RSpec.shared_context 'with one temporary file for multipart' do |within_tmp_sub_dir: false|
  let(:uploaded_filepath) { uploaded_file.path }

  around do |example|
    Tempfile.open('uploaded_file2') do |tempfile|
      @uploaded_file = tempfile
      @filename = 'test_file.png'
      @remote_id = 'remote_id'

      example.run
    end
  end

  attr_reader :uploaded_file, :filename, :remote_id
end

# This context provides two temporary files for the multipart spec
#
# Here are the available variables:
# - uploaded_file
# - uploaded_filepath
# - filename
# - remote_id
# - tmp_sub_dir (only when using within_tmp_sub_dir: true)
# - uploaded_file2
# - uploaded_filepath2
# - filename2
# - remote_id2
RSpec.shared_context 'with two temporary files for multipart' do
  include_context 'with one temporary file for multipart'

  let(:uploaded_filepath2) { uploaded_file2.path }

  around do |example|
    Tempfile.open('uploaded_file2') do |tempfile|
      @uploaded_file2 = tempfile
      @filename2 = 'test_file2.png'
      @remote_id2 = 'remote_id2'

      example.run
    end
  end

  attr_reader :uploaded_file2, :filename2, :remote_id2
end

# This context provides three temporary files for the multipart spec
#
# Here are the available variables:
# - uploaded_file
# - uploaded_filepath
# - filename
# - remote_id
# - tmp_sub_dir (only when using within_tmp_sub_dir: true)
# - uploaded_file2
# - uploaded_filepath2
# - filename2
# - remote_id2
# - uploaded_file3
# - uploaded_filepath3
# - filename3
# - remote_id3
RSpec.shared_context 'with three temporary files for multipart' do
  include_context 'with two temporary files for multipart'

  let(:uploaded_filepath3) { uploaded_file3.path }

  around do |example|
    Tempfile.open('uploaded_file3') do |tempfile|
      @uploaded_file3 = tempfile
      @filename3 = 'test_file3.png'
      @remote_id3 = 'remote_id3'

      example.run
    end
  end

  attr_reader :uploaded_file3, :filename3, :remote_id3
end
