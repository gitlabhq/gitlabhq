# frozen_string_literal: true

# @param path [String] the path to file to upload. E.g. File.join('spec', 'fixtures', 'sanitized.svg')
# @param uploader [CarrierWave::Uploader::Base] uploader to handle the upload.
shared_examples 'denied carrierwave upload' do
  it 'will deny upload' do
    fixture_file = fixture_file_upload(path)
    expect { uploader.cache!(fixture_file) }.to raise_exception(CarrierWave::IntegrityError)
  end
end

# @param path [String] the path to file to upload. E.g. File.join('spec', 'fixtures', 'sanitized.svg')
# @param uploader [CarrierWave::Uploader::Base] uploader to handle the upload.
shared_examples 'accepted carrierwave upload' do
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

def check_content_matches_extension!(file = double(read: nil, path: ''))
  magic_file = UploadTypeCheck::MagicFile.new(file)
  uploader.check_content_matches_extension!(magic_file)
end

RSpec.shared_examples 'upload passes content type check' do
  it 'does not raise error' do
    expect { check_content_matches_extension! }.not_to raise_error
  end
end

RSpec.shared_examples 'upload fails content type check' do
  it 'raises error' do
    expect { check_content_matches_extension! }.to raise_error(CarrierWave::IntegrityError)
  end
end

def upload_type_checked_filenames(filenames)
  Array(filenames).each do |filename|
    # Feed the uploader "some" content.
    path = File.join('spec', 'fixtures', 'dk.png')
    file = File.new(path, 'r')
    # Rename the file with what we want.
    allow(file).to receive(:path).and_return(filename)

    # Force the content type to match the extension type.
    mime_type = MimeMagic.by_path(filename)
    allow(MimeMagic).to receive(:by_magic).and_return(mime_type)

    uploaded_file = Rack::Test::UploadedFile.new(file, original_filename: filename)
    uploader.cache!(uploaded_file)
  end
end

def upload_type_checked_fixtures(upload_fixtures)
  upload_fixtures = Array(upload_fixtures)
  upload_fixtures.each do |upload_fixture|
    path = File.join('spec', 'fixtures', upload_fixture)
    uploader.cache!(fixture_file_upload(path))
  end
end

RSpec.shared_examples 'type checked uploads' do |upload_fixtures = nil, filenames: nil|
  it 'check type' do
    upload_fixtures = Array(upload_fixtures)
    filenames = Array(filenames)

    times = upload_fixtures.length + filenames.length
    expect(uploader).to receive(:check_content_matches_extension!).exactly(times).times

    upload_type_checked_fixtures(upload_fixtures) unless upload_fixtures.empty?
    upload_type_checked_filenames(filenames) unless filenames.empty?
  end
end

RSpec.shared_examples 'skipped type checked uploads' do |upload_fixtures = nil, filenames: nil|
  it 'skip type check' do
    expect(uploader).not_to receive(:check_content_matches_extension!)

    upload_type_checked_fixtures(upload_fixtures) if upload_fixtures
    upload_type_checked_filenames(filenames) if filenames
  end
end
