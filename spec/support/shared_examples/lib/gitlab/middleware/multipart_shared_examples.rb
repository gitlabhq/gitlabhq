# frozen_string_literal: true

RSpec.shared_examples 'handling all upload parameters conditions' do
  context 'one root parameter' do
    include_context 'with one temporary file for multipart'

    let(:rewritten_fields) { rewritten_fields_hash('file' => uploaded_filepath) }
    let(:params) { upload_parameters_for(filepath: uploaded_filepath, key: 'file', mode: mode, filename: filename, remote_id: remote_id) }

    it 'builds an UploadedFile' do
      expect_uploaded_files(filepath: uploaded_filepath, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w[file])

      subject
    end
  end

  context 'two root parameters' do
    include_context 'with two temporary files for multipart'

    let(:rewritten_fields) { rewritten_fields_hash('file1' => uploaded_filepath, 'file2' => uploaded_filepath2) }
    let(:params) do
      upload_parameters_for(filepath: uploaded_filepath, key: 'file1', mode: mode, filename: filename, remote_id: remote_id).merge(
        upload_parameters_for(filepath: uploaded_filepath2, key: 'file2', mode: mode, filename: filename2, remote_id: remote_id2)
      )
    end

    it 'builds UploadedFiles' do
      expect_uploaded_files(
        [
          { filepath: uploaded_filepath, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w[file1] },
          { filepath: uploaded_filepath2, original_filename: filename2, remote_id: remote_id2, size: uploaded_file2.size, params_path: %w[file2] }
        ]
      )

      subject
    end
  end

  context 'one nested parameter' do
    include_context 'with one temporary file for multipart'

    let(:rewritten_fields) { rewritten_fields_hash('user[avatar]' => uploaded_filepath) }
    let(:params) { { 'user' => { 'avatar' => upload_parameters_for(filepath: uploaded_filepath, mode: mode, filename: filename, remote_id: remote_id) } } }

    it 'builds an UploadedFile' do
      expect_uploaded_files(filepath: uploaded_filepath, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w[user avatar])

      subject
    end
  end

  context 'two nested parameters' do
    include_context 'with two temporary files for multipart'

    let(:rewritten_fields) { rewritten_fields_hash('user[avatar]' => uploaded_filepath, 'user[screenshot]' => uploaded_filepath2) }
    let(:params) do
      {
        'user' => {
          'avatar' => upload_parameters_for(filepath: uploaded_filepath, mode: mode, filename: filename, remote_id: remote_id),
          'screenshot' => upload_parameters_for(filepath: uploaded_filepath2, mode: mode, filename: filename2, remote_id: remote_id2)
        }
      }
    end

    it 'builds UploadedFiles' do
      expect_uploaded_files(
        [
          { filepath: uploaded_filepath, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w[user avatar] },
          { filepath: uploaded_filepath2, original_filename: filename2, remote_id: remote_id2, size: uploaded_file2.size, params_path: %w[user screenshot] }
        ]
      )

      subject
    end
  end

  context 'one deeply nested parameter' do
    include_context 'with one temporary file for multipart'

    let(:rewritten_fields) { rewritten_fields_hash('user[avatar][bananas]' => uploaded_filepath) }
    let(:params) { { 'user' => { 'avatar' => { 'bananas' => upload_parameters_for(filepath: uploaded_filepath, mode: mode, filename: filename, remote_id: remote_id) } } } }

    it 'builds an UploadedFile' do
      expect_uploaded_files(filepath: uploaded_file, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w[user avatar bananas])

      subject
    end
  end

  context 'two deeply nested parameters' do
    include_context 'with two temporary files for multipart'

    let(:rewritten_fields) { rewritten_fields_hash('user[avatar][bananas]' => uploaded_filepath, 'user[friend][ananas]' => uploaded_filepath2) }
    let(:params) do
      {
        'user' => {
          'avatar' => {
            'bananas' => upload_parameters_for(filepath: uploaded_filepath, mode: mode, filename: filename, remote_id: remote_id)
          },
          'friend' => {
            'ananas' => upload_parameters_for(filepath: uploaded_filepath2, mode: mode, filename: filename2, remote_id: remote_id2)
          }
        }
      }
    end

    it 'builds UploadedFiles' do
      expect_uploaded_files(
        [
          { filepath: uploaded_file, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w[user avatar bananas] },
          { filepath: uploaded_file2, original_filename: filename2, remote_id: remote_id2, size: uploaded_file2.size, params_path: %w[user friend ananas] }
        ]
      )

      subject
    end
  end

  context 'three parameters nested at different levels' do
    include_context 'with three temporary files for multipart'

    let(:rewritten_fields) do
      rewritten_fields_hash(
        'file' => uploaded_filepath,
        'user[avatar]' => uploaded_filepath2,
        'user[friend][avatar]' => uploaded_filepath3
      )
    end

    let(:params) do
      upload_parameters_for(filepath: uploaded_filepath, filename: filename, key: 'file', mode: mode, remote_id: remote_id).merge(
        'user' => {
          'avatar' => upload_parameters_for(filepath: uploaded_filepath2, mode: mode, filename: filename2, remote_id: remote_id2),
          'friend' => {
            'avatar' => upload_parameters_for(filepath: uploaded_filepath3, mode: mode, filename: filename3, remote_id: remote_id3)
          }
        }
      )
    end

    it 'builds UploadedFiles' do
      expect_uploaded_files(
        [
          { filepath: uploaded_filepath, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w[file] },
          { filepath: uploaded_filepath2, original_filename: filename2, remote_id: remote_id2, size: uploaded_file2.size, params_path: %w[user avatar] },
          { filepath: uploaded_filepath3, original_filename: filename3, remote_id: remote_id3, size: uploaded_file3.size, params_path: %w[user friend avatar] }
        ]
      )

      subject
    end
  end
end
