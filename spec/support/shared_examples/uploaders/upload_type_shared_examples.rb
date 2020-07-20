# frozen_string_literal: true

# @param path [String] the path to file to upload. E.g. File.join('spec', 'fixtures', 'sanitized.svg')
# @param uploader [CarrierWave::Uploader::Base] uploader to handle the upload.
RSpec.shared_examples 'denied carrierwave upload' do
  it 'will deny upload' do
    fixture_file = fixture_file_upload(path)
    expect { uploader.cache!(fixture_file) }.to raise_exception(CarrierWave::IntegrityError)
  end
end

# @param path [String] the path to file to upload. E.g. File.join('spec', 'fixtures', 'sanitized.svg')
# @param uploader [CarrierWave::Uploader::Base] uploader to handle the upload.
RSpec.shared_examples 'accepted carrierwave upload' do
  let(:fixture_file) { fixture_file_upload(path) }

  before do
    uploader.remove!
  end

  it 'will accept upload' do
    expect { uploader.cache!(fixture_file) }.not_to raise_exception
  end

  it 'will cache uploaded file' do
    expect { uploader.cache!(fixture_file) }.to change { uploader.file }.from(nil).to(kind_of(CarrierWave::SanitizedFile))
  end
end

# @param path [String] the path to file to upload. E.g. File.join('spec', 'fixtures', 'sanitized.svg')
# @param uploader [CarrierWave::Uploader::Base] uploader to handle the upload.
# @param content_type [String] the upload file content type after cache
RSpec.shared_examples 'upload with content type' do |content_type|
  let(:fixture_file) { fixture_file_upload(path, content_type) }

  it 'will not change upload file content type' do
    uploader.cache!(fixture_file)
    expect(uploader.file.content_type).to eq(content_type)
  end
end
