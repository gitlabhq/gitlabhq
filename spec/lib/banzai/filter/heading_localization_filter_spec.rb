# frozen_string_literal: true

require 'fast_spec_helper'
require 'html/pipeline'

RSpec.describe Banzai::Filter::HeadingLocalizationFilter, feature_category: :markdown do
  # Build the HTML structure that the filter expects: a heading with an anchor
  # that has aria-label and data-heading-content (as produced by MarkupHeadingAnchorFilter
  # or the Markdown parser).
  def heading_html(text, include_data_heading_content: true)
    frag = Nokogiri::HTML5.fragment('<h1>')

    h1 = frag.at_css('h1')
    h1.content = text

    a = frag.document.create_element('a')
    a['class'] = 'anchor'
    a['href'] = "##{text.downcase}"
    a['aria-label'] = 'Unmodified'
    a['data-heading-content'] = text if include_data_heading_content
    h1 << a

    frag.to_html
  end

  def filter(html)
    described_class.call(html)
  end

  it 'rewrites heading aria-labels with a localized string' do
    expect_next_instance_of(described_class) do |instance|
      expect(instance).to receive(:_).and_return("Link pealkirjale '%{heading}'")
    end

    doc = filter(heading_html('Tere, maailm!'))
    a = doc.css('h1 > a.anchor').first

    expect(a['aria-label']).to eq("Link pealkirjale 'Tere, maailm!'")
  end

  it 'does not modify anchors without data-heading-content' do
    doc = filter(heading_html('Heading', include_data_heading_content: false))
    a = doc.css('h1 > a.anchor').first

    expect(a['aria-label']).to eq('Unmodified')
  end
end
