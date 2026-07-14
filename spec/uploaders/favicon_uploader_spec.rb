# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FaviconUploader, feature_category: :navigation do
  let_it_be(:model) { build_stubbed(:user) }
  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be(:uploader, freeze: false) { described_class.new(model, :favicon) }

  context 'accept allowlist file content type' do
    include_context 'ignore extension allowlist check'

    # We need to feed through a valid path, but we force the parsed mime type
    # in a stub below so we can set any path.
    let_it_be(:path) { File.join('spec', 'fixtures', 'video_sample.mp4') }

    where(:mime_type) { described_class::MIME_ALLOWLIST }

    with_them do
      include_context 'force content type detection to mime_type'

      it_behaves_like 'accepted carrierwave upload'
    end
  end

  context 'upload denylisted file content type' do
    include_context 'ignore extension allowlist check'

    let_it_be(:path) { File.join('spec', 'fixtures', 'sanitized.svg') }

    it_behaves_like 'denied carrierwave upload'
  end

  context 'upload misnamed denylisted file content type' do
    include_context 'ignore extension allowlist check'

    let_it_be(:path) { File.join('spec', 'fixtures', 'not_a_png.png') }

    it_behaves_like 'denied carrierwave upload'
  end
end
