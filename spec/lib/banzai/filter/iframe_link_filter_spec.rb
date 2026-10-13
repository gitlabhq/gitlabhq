# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::IframeLinkFilter, feature_category: :markdown do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: subgroup) }

  let(:src) { 'https://www.youtube.com/embed/foo' }
  let(:embed_src) { src }
  let(:alt) { nil }
  let(:width) { nil }
  let(:height) { nil }
  let(:image) { build_fragment.tap { |doc| add_image(doc, src: src, alt: alt, width: width, height: height) } }

  before do
    stub_application_setting(iframe_rendering_enabled: true, iframe_rendering_allowlist: %w[youtube])
  end

  def filter(doc, contexts = {})
    described_class.call(doc, contexts.reverse_merge(project: project))
  end

  def build_fragment
    Nokogiri::HTML::DocumentFragment.new(Nokogiri::HTML::Document.new)
  end

  def add_image(parent, src: nil, alt: nil, width: nil, height: nil)
    attributes = { 'src' => src, 'alt' => alt, 'width' => width, 'height' => height }.compact

    parent.add_child(parent.document.create_element('img', attributes))
  end

  shared_examples 'an iframe embed' do
    it 'replaces the image with an embed container carrying the provider data', :aggregate_failures do
      doc = filter(image)
      container = doc.children.first

      expect(doc.css('img')).to be_empty
      expect(doc.xpath('descendant-or-self::*[@src]')).to be_empty
      expect(container.name).to eq 'span'
      expect(container.to_h).to eq({
        'class' => 'media-container iframe-container js-render-iframe',
        'data-iframe-src' => embed_src,
        'data-iframe-canonical-src' => src,
        'data-iframe-provider-id' => 'youtube',
        'data-title' => alt,
        'data-width' => width,
        'data-height' => height
      }.compact)
    end

    it 'falls back to a link to the canonical source', :aggregate_failures do
      link = filter(image).at_css('span > a')

      expect(link['href']).to eq src
      expect(link.text).to eq(alt || src)
    end
  end

  shared_examples 'an unchanged element' do
    it 'leaves the image untouched', :aggregate_failures do
      element = filter(image).children.first

      expect(element.name).to eq 'img'
      expect(element.attributes.transform_values(&:value)).to eq({ 'src' => src }.compact)
    end
  end

  context 'when the element src has a supported iframe domain' do
    it_behaves_like 'an iframe embed'
  end

  context 'when the element has alt, width, or height attributes' do
    where(:alt, :width, :height) do
      'Alt text' | nil    | nil
      nil        | '50px' | '100%'
      nil        | '50px' | nil
      nil        | nil    | '50px'
    end

    with_them do
      it_behaves_like 'an iframe embed'
    end
  end

  context 'when the element src matches a provider rule that rewrites it' do
    let(:src) { 'https://youtu.be/foo' }
    let(:embed_src) { 'https://www.youtube.com/embed/foo' }

    it_behaves_like 'an iframe embed'
  end

  context 'when the element has an empty alt text' do
    let(:alt) { '' }

    it 'omits data-title and links to the canonical source', :aggregate_failures do
      container = filter(image).children.first

      expect(container.to_h).not_to include('data-title')
      expect(container.at_css('a').text).to eq(src)
    end
  end

  context 'when the element has no src attribute' do
    let(:src) { nil }

    it_behaves_like 'an unchanged element'
  end

  context 'when the element src does not match any provider' do
    let(:src) { 'https://path/my_image.jpg' }

    it_behaves_like 'an unchanged element'
  end

  context 'when the element src is on a provider host but does not match its rules' do
    let(:src) { 'https://www.youtube.com/account' }

    it_behaves_like 'an unchanged element'
  end

  context 'when the matching provider is not enabled' do
    let(:src) { 'https://www.figma.com/design/abc123' }

    it_behaves_like 'an unchanged element'
  end

  context 'when the image is wrapped in a link' do
    it 'leaves the image untouched' do
      doc = build_fragment
      link = doc.document.create_element('a', href: 'https://example.com')
      add_image(link, src: src)
      doc.add_child(link)

      filter(doc)

      expect(doc.css('a > img').map { |img| img['src'] }).to eq([src])
    end
  end

  context 'when the document contains several images' do
    it 'only converts those matching an enabled provider', :aggregate_failures do
      doc = build_fragment
      add_image(doc, src: 'https://youtu.be/foo')
      add_image(doc, src: 'https://path/my_image.jpg')

      filter(doc)

      expect(doc.css('.js-render-iframe').map { |embed| embed['data-iframe-src'] })
        .to eq(%w[https://www.youtube.com/embed/foo])
      expect(doc.css('img').map { |img| img['src'] }).to eq(%w[https://path/my_image.jpg])
    end
  end

  context 'when iframe rendering is disabled' do
    before do
      stub_application_setting(iframe_rendering_enabled: false)
    end

    it_behaves_like 'an unchanged element'
  end

  context 'when allow_iframes_in_markdown is disabled' do
    before do
      stub_feature_flags(allow_iframes_in_markdown: false)
    end

    it_behaves_like 'an unchanged element'
  end

  context 'when allow_iframes_in_markdown is set for the project' do
    before do
      stub_feature_flags(allow_iframes_in_markdown: project)
    end

    it_behaves_like 'an iframe embed'
  end

  context 'when allow_iframes_in_markdown is set for the immediate group' do
    before do
      stub_feature_flags(allow_iframes_in_markdown: subgroup)
    end

    it_behaves_like 'an iframe embed'
  end

  context 'when allow_iframes_in_markdown is set for an ancestor group' do
    before do
      stub_feature_flags(allow_iframes_in_markdown: group)
    end

    it_behaves_like 'an iframe embed'
  end

  it_behaves_like 'pipeline timing check' do
    let(:context) { { project: } }
  end

  context 'when the pipeline has exceeded its maximum time' do
    let(:src) { 'https://youtu.be/foo' }

    it 'leaves matching elements untouched', :aggregate_failures do
      instance = described_class.new(image, { project: project })
      allow(instance).to receive(:exceeded_pipeline_max?).and_return(true)

      element = instance.call.children.first

      expect(element.name).to eq 'img'
      expect(element.attributes.transform_values(&:value)).to eq('src' => src)
    end
  end
end
