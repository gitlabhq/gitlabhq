# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::GollumTagsFilter, feature_category: :wiki do
  include FilterSpecHelper

  shared_examples 'gollum tag parsing' do
    context 'when tag is only a page name or url' do
      it 'creates a link' do
        tag = '[[page name or url]]'
        doc = filter("See #{tag}", context)

        expect(doc.at_css('a').text).to eq 'page name or url'
        expect(doc.at_css('a')['href']).to eq 'page%20name%20or%20url'
        expect(doc.at_css('a')['data-wikilink']).to eq 'true'
      end
    end

    context 'when tag is link text and a page name or url' do
      it 'creates a link' do
        tag = '[[link-text|http://example.com/pdfs/gollum.pdf]]'
        doc = filter("See #{tag}", context)

        expect(doc.at_css('a').text).to eq 'link-text'
        expect(doc.at_css('a')['href']).to eq 'http://example.com/pdfs/gollum.pdf'
        expect(doc.at_css('a')['data-wikilink']).to eq 'true'
      end
    end

    it 'inside back ticks will be exempt from linkification' do
      doc = filter('<code>[[link-in-backticks]]</code>', context)

      expect(doc.at_css('code').text).to eq '[[link-in-backticks]]'
    end

    it 'leaves other text content untouched' do
      doc = filter('This is [[a link|link]]', context)

      expect(doc.to_html).to eq 'This is <a href="link" data-wikilink="true">a link</a>'
    end

    context 'sanitization of HTML entities' do
      it 'does not unescape HTML entities' do
        doc = filter('This is [[a link|&lt;script&gt;alert(0)&lt;/script&gt;]]', context)

        expect(doc.to_html).to eq 'This is <a href="&lt;script&gt;alert(0)&lt;/script&gt;" data-wikilink="true">a link</a>'
      end

      it 'does not unescape HTML entities in the link text' do
        doc = filter('This is [[&lt;script&gt;alert(0)&lt;/script&gt;|link]]', context)

        expect(doc.to_html).to eq 'This is <a href="link" data-wikilink="true">&lt;script&gt;alert(0)&lt;/script&gt;</a>'
      end

      it 'does not unescape HTML entities outside the link text' do
        doc = filter('This is &lt;script&gt;alert(0)&lt;/script&gt; [[a link|link]]', context)

        expect(doc.to_html).to eq 'This is &lt;script&gt;alert(0)&lt;/script&gt; <a href="link" data-wikilink="true">a link</a>'
      end
    end

    it 'sanitizes the href attribute (case 1)' do
      tag = '[[a|http:\'"injected=attribute&gt;&lt;img/src="0"onerror="alert(0)"&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1]]'
      doc = filter("See #{tag}", context)

      expect(doc.at_css('a').to_html).to eq '<a href="http:\'%22injected=attribute&gt;&lt;img/src=%220%22onerror=%22alert(0)%22&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1" data-wikilink="true">a</a>'
    end

    it 'sanitizes the href attribute (case 2)' do
      tag = '<i>[[a|\'"&gt;&lt;svg&gt;&lt;i/class=gl-show-field-errors&gt;&lt;input/title="&lt;script&gt;alert(0)&lt;/script&gt;"/&gt;&lt;/svg&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1]]'
      doc = filter("See #{tag}", context)

      expect(doc.at_css('i a').to_html).to eq "<a href=\"'%22&gt;&lt;svg&gt;&lt;i/class=gl-show-field-errors&gt;&lt;input/title=%22&lt;script&gt;alert(0)&lt;/script&gt;%22/&gt;&lt;/svg&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1\" data-wikilink=\"true\">a</a>"
    end

    it 'protects against malicious input' do
      text = "]#{'[[a' * 200000}[]"

      expect do
        Timeout.timeout(BANZAI_FILTER_TIMEOUT_MAX) { filter(text, context) }
      end.not_to raise_error
    end
  end

  it_behaves_like 'gollum tag parsing' do
    let_it_be(:context) { { markdown_engine: Banzai::Filter::MarkdownFilter::CMARK_ENGINE } }
  end

  it_behaves_like 'gollum tag parsing' do
    let_it_be(:context) { { pipeline: :ascii_doc } }
  end

  context 'when parsing default markdown' do
    let_it_be(:context) { {} }

    it 'ignores the tag' do
      tag = '[[page name or url]]'
      doc = filter("See #{tag}", context)

      expect(doc.at_css('a')).to be_nil
    end
  end

  it_behaves_like 'pipeline timing check'

  it_behaves_like 'limits the number of filtered items', context: { pipeline: :ascii_doc } do
    let(:text) { '[[page name or url]] [[page name or url]] [[page name or url]]' }
    let(:ends_with) { '</a> [[page name or url]]' }
  end
end
