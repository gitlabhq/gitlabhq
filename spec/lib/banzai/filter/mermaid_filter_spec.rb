# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MermaidFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'adds `js-render-mermaid` class to the `code` tag' do
    doc = filter("<pre class='code highlight js-syntax-highlight mermaid' data-canonical-lang='mermaid' v-pre='true'><code>graph TD;\n  A--&gt;B;\n</code></pre>")
    result = doc.css('code').first

    expect(result[:class]).to include('js-render-mermaid')
  end

  context 'when interoperating with AssetProxyFilter' do
    let(:pipeline) do
      filters = [
        Banzai::Filter::MarkdownFilter,
        Banzai::Filter::CodeLanguageFilter,
        Banzai::Filter::AssetProxyFilter,
        described_class
      ]

      context = Banzai::Filter::AssetProxyFilter.transform_context({ project: nil })
      HTML::Pipeline.new(filters, context)
    end

    let(:gotcha_url) { 'https://exfiltrate.example/gotcha.png' }

    let(:source) do
      <<~MARKDOWN
        ```mermaid
        graph TD
          A --> B
          C --> D[<img src='#{gotcha_url}'>]
        ```
      MARKDOWN
    end

    before do
      # TODO: refactor this (and similar usages elsewhere) so we don't have to
      # manually recapitulate the work of AssetProxy.initialize_settings.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/582610
      allowlist = %W[gitlab.com *.mydomain.com #{Gitlab.config.gitlab.host}]
      stub_asset_proxy_setting(
        enabled: true,
        secret_key: 'shared-secret',
        url: 'https://assets.example.com',
        allowlist: allowlist)
      stub_asset_proxy_setting(
        domain_regexp: Banzai::Filter::AssetProxyFilter.host_regexp_for_allowlist(allowlist),
        csp_directives: Banzai::Filter::AssetProxyFilter.csp_for_allowlist(allowlist))
    end

    it 'prepares asset proxy URLs for any URLs found in the source' do
      doc = pipeline.call(source)[:output]
      result = doc.css('code').first

      expect(result['class']).to include('js-render-mermaid')
      proxied_urls = Gitlab::Json.parse(result['data-proxied-urls'])
      expect(proxied_urls).to have_key(gotcha_url)
      expect(proxied_urls[gotcha_url]).to match(%r{\Ahttps://assets\.example\.com/\w+/\w+\z})
    end
  end

  it_behaves_like 'pipeline timing check'
end
