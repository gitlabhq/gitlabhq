# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MinimumMarkdownSanitizationFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'sanitizes tags that are not allowed' do
    list = Banzai::Filter::SanitizationFilter::ALLOWLIST[:elements] -
      Banzai::Filter::MinimumMarkdownSanitizationFilter::ALLOWLIST[:elements]
    act = list.map { |tag| "<#{tag}>#{tag}</#{tag}>" }.join(' ')
    exp = list.map { |tag| tag }.join(' ')

    expect(filter(act).to_html.squeeze(' ')).to eq exp
  end

  it 'sanitizes tag attributes' do
    act = %q(<a href="http://example.com/bar.html" onclick="bar">Text</a>)
    exp = %q(<a href="http://example.com/bar.html">Text</a>)

    expect(filter(act).to_html).to eq exp
  end

  it 'allows allowlisted HTML tags from the user' do
    list = Banzai::Filter::MinimumMarkdownSanitizationFilter::ALLOWLIST[:elements]
    act = list.map { |tag| "<#{tag}>#{tag}</#{tag}>" }.join(' ')

    expect(filter(act).to_html.squeeze(' ')).to eq act
  end

  it 'sanitizes `class` attribute on any element' do
    act = %q(<strong class="foo">Strong</strong>)

    expect(filter(act).to_html).to eq %q(<strong>Strong</strong>)
  end

  it 'sanitizes `id` attribute on any element' do
    act = %q(<em>Emphasis</em> <a href="http://foo" id="bar">foo bar</a>)
    exp = %q(<em>Emphasis</em> <a href="http://foo">foo bar</a>)

    expect(filter(act).to_html).to eq exp
  end

  it 'only allows http and https protocols' do
    act = %q(<a href="http://foo">http</a> <a href="https://foo">https</a> <a href="mailto://foo">mailto</a>)
    exp = %q(<a href="http://foo">http</a> <a href="https://foo">https</a> <a>mailto</a>)

    expect(filter(act).to_html).to eq exp
  end

  it_behaves_like 'does not use pipeline timing check'

  it_behaves_like 'a filter timeout' do
    let(:text) { 'text' }
    let(:expected_result) { described_class::COMPLEX_MARKDOWN_MESSAGE }
    let(:expected_timeout) { described_class::SANITIZATION_RENDER_TIMEOUT }
  end
end
