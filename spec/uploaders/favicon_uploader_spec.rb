# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FaviconUploader do
  let_it_be(:model) { build_stubbed(:user) }
  let_it_be(:uploader) { described_class.new(model, :favicon) }

  context 'accept whitelist file content type' do
    include_context 'ignore extension whitelist check'

    # We need to feed through a valid path, but we force the parsed mime type
    # in a stub below so we can set any path.
    let_it_be(:path) { File.join('spec', 'fixtures', 'video_sample.mp4') }

    where(:mime_type) { described_class::MIME_WHITELIST }

    with_them do
      include_context 'force content type detection to mime_type'

      it_behaves_like 'accepted carrierwave upload'
    end
  end

  context 'upload non-whitelisted file content type' do
    include_context 'ignore extension whitelist check'

    let_it_be(:path) { File.join('spec', 'fixtures', 'sanitized.svg') }

    it_behaves_like 'denied carrierwave upload'
  end

  context 'upload misnamed non-whitelisted file content type' do
    include_context 'ignore extension whitelist check'

    let_it_be(:path) { File.join('spec', 'fixtures', 'not_a_png.png') }

    it_behaves_like 'denied carrierwave upload'
  end
end
