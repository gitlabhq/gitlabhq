# frozen_string_literal: true

# Construct an `uploader` variable that is configured to `check_upload_type`
# with `mime_types` and `extensions`.
# @param uploader [CarrierWave::Uploader::Base] uploader with extension_whitelist method.
RSpec.shared_context 'ignore extension whitelist check' do
  before do
    allow(uploader).to receive(:extension_whitelist).and_return(nil)
  end
end

# This works with a content_type_whitelist and content_type_blacklist type check.
# @param mime_type [String] mime type to forcibly detect.
RSpec.shared_context 'force content type detection to mime_type' do
  before do
    allow(Gitlab::Utils::MimeType).to receive(:from_io).and_return(mime_type)
  end
end
