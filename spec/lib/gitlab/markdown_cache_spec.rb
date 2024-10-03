# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MarkdownCache, feature_category: :markdown do
  it 'returns proper latest_cached_markdown_version' do
    stub_application_setting(local_markdown_version: 2)

    expect(described_class.latest_cached_markdown_version(local_version: nil))
      .to eq described_class::CACHE_COMMONMARK_VERSION_SHIFTED | 2
  end

  it 'uses passed in local_version' do
    stub_application_setting(local_markdown_version: 2)

    expect(described_class.latest_cached_markdown_version(local_version: 5))
      .to eq described_class::CACHE_COMMONMARK_VERSION_SHIFTED | 5
  end
end
