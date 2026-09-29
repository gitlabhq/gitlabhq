# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::IframeLinkFilter, feature_category: :markdown do
  def filter(doc, contexts = {})
    contexts.reverse_merge!({ project: project })

    described_class.call(doc, contexts)
  end

  def link_to_image(path, height = nil, width = nil)
    img = Nokogiri::HTML.fragment("<img>").css('img').first
    return img.to_html if path.nil?

    img["src"] = path
    img["width"] = width if width
    img["height"] = height if height
    img.to_html
  end

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: subgroup) }

  let(:width) { nil }
  let(:height) { nil }

  before do
    stub_application_setting(iframe_rendering_enabled: true, iframe_rendering_allowlist: %w[youtube])
  end

  shared_examples 'an iframe element' do
    let(:image) { link_to_image(src, height, width) }

    it 'replaces the image tag with a media container and image tag' do
      container = filter(image).children.first

      expect(container.name).to eq 'span'
      expect(container['class']).to eq 'media-container img-container'

      iframe = container.children.first

      expect(iframe.name).to eq 'img'
      expect(iframe['class']).to eq 'js-render-iframe'
      expect(iframe['src']).to eq src
      expect(iframe['data-iframe-canonical-src']).to eq src
      expect(iframe['data-iframe-provider-id']).to eq 'youtube'
      expect(iframe['height']).to eq height if height
      expect(iframe['width']).to eq width if width
    end
  end

  shared_examples 'an unchanged element' do
    it 'leaves the document unchanged' do
      element = filter(link_to_image(src)).children.first

      expect(element.name).to eq 'img'
      expect(element['src']).to eq src
    end
  end

  context 'when the element src has a supported iframe domain' do
    it_behaves_like 'an iframe element' do
      let(:src) { "https://www.youtube.com/embed/foo" }
    end
  end

  context 'when the element has height or width specified' do
    let(:src) { "https://www.youtube.com/embed/foo" }

    it_behaves_like 'an iframe element' do
      let(:height) { '100%' }
      let(:width) { '50px' }
    end

    it_behaves_like 'an iframe element' do
      let(:width) { '50px' }
    end

    it_behaves_like 'an iframe element' do
      let(:height) { '50px' }
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

  context 'when the element src matches a provider rule that rewrites it' do
    it 'rewrites the src and records the original and the provider' do
      image = link_to_image('https://youtu.be/foo')
      iframe = filter(image).children.first.children.first

      expect(iframe['class']).to eq 'js-render-iframe'
      expect(iframe['src']).to eq 'https://www.youtube.com/embed/foo'
      expect(iframe['data-iframe-canonical-src']).to eq 'https://youtu.be/foo'
      expect(iframe['data-iframe-provider-id']).to eq 'youtube'
    end
  end

  context 'when the matching provider is not enabled' do
    let(:src) { 'https://www.figma.com/design/abc123' }

    it_behaves_like 'an unchanged element'
  end

  context 'when the document contains several images' do
    it 'only converts those matching an enabled provider' do
      doc = filter(link_to_image('https://youtu.be/foo') + link_to_image('https://path/my_image.jpg'))

      expect(doc.css('img.js-render-iframe').map { |img| img['src'] }).to eq(%w[https://www.youtube.com/embed/foo])
      expect(doc.css('img:not(.js-render-iframe)').map { |img| img['src'] }).to eq(%w[https://path/my_image.jpg])
    end
  end

  context 'when iframe rendering is disabled' do
    before do
      stub_application_setting(iframe_rendering_enabled: false)
    end

    let(:src) { 'https://www.youtube.com/embed/foo' }

    it_behaves_like 'an unchanged element'
  end

  context 'when allow_iframes_in_markdown is disabled' do
    before do
      stub_feature_flags(allow_iframes_in_markdown: false)
    end

    let(:src) { 'https://www.youtube.com/embed/foo' }

    it_behaves_like 'an unchanged element'
  end

  context 'when allow_iframes_in_markdown is set for the project' do
    before do
      stub_feature_flags(allow_iframes_in_markdown: project)
    end

    let(:src) { 'https://www.youtube.com/embed/foo' }

    it_behaves_like 'an iframe element'
  end

  context 'when allow_iframes_in_markdown is set for the immediate group' do
    before do
      stub_feature_flags(allow_iframes_in_markdown: subgroup)
    end

    let(:src) { 'https://www.youtube.com/embed/foo' }

    it_behaves_like 'an iframe element'
  end

  context 'when allow_iframes_in_markdown is set for an ancestor group' do
    before do
      stub_feature_flags(allow_iframes_in_markdown: group)
    end

    let(:src) { 'https://www.youtube.com/embed/foo' }

    it_behaves_like 'an iframe element'
  end

  it_behaves_like 'pipeline timing check' do
    let(:context) { { project: } }
  end

  context 'when the pipeline has exceeded its maximum time' do
    it 'leaves matching elements untouched' do
      src = 'https://youtu.be/foo'
      instance = described_class.new(link_to_image(src), { project: project })
      allow(instance).to receive(:exceeded_pipeline_max?).and_return(true)

      element = instance.call.children.first

      expect(element.name).to eq 'img'
      expect(element.attributes.transform_values(&:value)).to eq('src' => src)
    end
  end
end
