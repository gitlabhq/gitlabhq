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
      stub_asset_proxy_enabled(
        url: 'https://assets.example.com',
        secret_key: 'shared-secret',
        allowlist: %W[gitlab.com *.mydomain.com #{Gitlab.config.gitlab.host}]
      )
    end

    it 'prepares asset proxy URLs for any URLs found in the source' do
      doc = pipeline.call(source)[:output]
      result = doc.css('code').first

      expect(result['class']).to include('js-render-mermaid')
      proxied_urls = Gitlab::Json.parse(result['data-proxied-urls'])
      expect(proxied_urls).to have_key(gotcha_url)
      expect(proxied_urls[gotcha_url]).to match(%r{\Ahttps://assets\.example\.com/\w+/\w+\z})
    end

    context 'when mermaid source contains gid: scheme URIs' do
      # The globalid gem registers "gid" as a URI scheme. When URI.parse is called
      # with a malformed gid: URI like "gid:foo" (no hierarchical path), URI::GID
      # is instantiated but its #set_model_components method calls path.split on
      # a nil path, raising NoMethodError instead of URI::Error.
      let(:source) do
        <<~MARKDOWN
          ```mermaid
          graph TD
            A --gid:relation--> B
            classDef gid:style fill:#f9f
          ```
        MARKDOWN
      end

      it 'does not raise an error when parsing malformed gid: URIs' do
        expect { pipeline.call(source) }.not_to raise_error
      end
    end
  end

  it_behaves_like 'pipeline timing check'
end
