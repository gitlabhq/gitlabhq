# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::SanitizeLinkFilter, feature_category: :markdown do
  include FilterSpecHelper

  it_behaves_like 'XSS prevention'
  it_behaves_like 'sanitize link'
  it_behaves_like 'does not use pipeline timing check'

  it_behaves_like 'a filter timeout' do
    let(:text) { 'text' }
    let(:expected_result) { described_class::TIMEOUT_MARKDOWN_MESSAGE }
    let(:expected_timeout) { described_class::SANITIZATION_RENDER_TIMEOUT }
  end
end
