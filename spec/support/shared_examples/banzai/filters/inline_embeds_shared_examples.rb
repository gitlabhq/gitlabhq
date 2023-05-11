# frozen_string_literal: true

# Expects 2 attributes to be defined:
#   trigger_url - Url expected to trigger the insertion of a placeholder.
#   dashboard_url - Url expected to be present in the placeholder.
RSpec.shared_examples 'a metrics embed filter' do
  let(:input) { %(<a href="#{url}">example</a>) }
  let(:doc) { filter(input) }

  before do
    stub_feature_flags(remove_monitor_metrics: false)
  end

  context 'when the document has an external link' do
    let(:url) { 'https://foo.com' }

    it 'leaves regular non-metrics links unchanged' do
      expect(doc.to_s).to eq(input)
    end
  end

  context 'when the document contains an embeddable link' do
    let(:url) { trigger_url }

    it 'leaves the original link unchanged' do
      expect(unescape(doc.at_css('a').to_s)).to eq(input)
    end

    it 'appends a metrics charts placeholder' do
      node = doc.at_css('.js-render-metrics')
      expect(node).to be_present

      expect(node.attribute('data-dashboard-url').to_s).to eq(dashboard_url)
    end

    context 'in a paragraph' do
      let(:paragraph) { %(This is an <a href="#{url}">example</a> of metrics.) }
      let(:input) { %(<p>#{paragraph}</p>) }

      it 'appends a metrics charts placeholder after the enclosing paragraph' do
        expect(unescape(doc.at_css('p').to_s)).to include(paragraph)
        expect(doc.at_css('.js-render-metrics')).to be_present
      end
    end

    context 'when metrics dashboard feature is unavailable' do
      before do
        stub_feature_flags(remove_monitor_metrics: true)
      end

      it 'does not append a metrics chart placeholder' do
        node = doc.at_css('.js-render-metrics')

        expect(node).not_to be_present
      end
    end
  end

  # Nokogiri escapes the URLs, but we don't care about that
  # distinction for the purposes of these filters
  def unescape(html)
    CGI.unescapeHTML(html)
  end
end
