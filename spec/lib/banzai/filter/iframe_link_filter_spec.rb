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
  let_it_be(:project) { create(:project, :repository, group: subgroup) }

  let(:width) { nil }
  let(:height) { nil }

  before do
    allow(Gitlab::CurrentSettings).to receive_messages(
      iframe_rendering_enabled?: true,
      iframe_rendering_allowlist: ["www.youtube.com"])
  end

  shared_examples 'an iframe element' do
    let(:image) { link_to_image(src, height, width) }

    it 'replaces the image tag with a media container and image tag' do
      container = filter(image).children.first

      expect(container.name).to eq 'span'
      expect(container['class']).to eq 'media-container img-container'

      iframe = container.children.first

      expect(iframe.name).to eq 'img'
      expect(iframe['src']).to eq src
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

  context 'when the element src does not match a domain' do
    let(:src) { 'https://path/my_image.jpg' }

    it_behaves_like 'an unchanged element'
  end

  context 'when the element src matches a URL transform rule' do
    it 'transforms a YouTube watch URL and matches the allowlist' do
      image = link_to_image('https://www.youtube.com/watch?v=foo')
      container = filter(image).children.first

      expect(container.name).to eq 'span'
      expect(container['class']).to eq 'media-container img-container'

      iframe = container.children.first
      expect(iframe.name).to eq 'img'
      expect(iframe['src']).to eq 'https://www.youtube.com/embed/foo'
      expect(iframe['data-iframe-canonical-src']).to eq 'https://www.youtube.com/watch?v=foo'
    end

    it 'transforms a YouTube short URL and matches the allowlist' do
      image = link_to_image('https://youtu.be/foo')
      container = filter(image).children.first

      expect(container['class']).to eq 'media-container img-container'

      iframe = container.children.first
      expect(iframe['src']).to eq 'https://www.youtube.com/embed/foo'
      expect(iframe['data-iframe-canonical-src']).to eq 'https://youtu.be/foo'
    end

    it 'transforms a Figma view URL and matches the allowlist' do
      allow(Gitlab::CurrentSettings).to receive(:iframe_rendering_allowlist)
        .and_return(["embed.figma.com"])

      image = link_to_image('https://www.figma.com/design/abc123/My-Design')
      container = filter(image).children.first

      expect(container['class']).to eq 'media-container img-container'

      iframe = container.children.first
      expect(iframe['src']).to eq 'https://embed.figma.com/design/abc123?embed-host=gitlab'
      expect(iframe['data-iframe-canonical-src']).to eq 'https://www.figma.com/design/abc123/My-Design'
    end

    it 'does not set data-iframe-canonical-src when no transform is applied' do
      image = link_to_image('https://www.youtube.com/embed/foo')
      container = filter(image).children.first
      iframe = container.children.first

      expect(iframe['data-iframe-canonical-src']).to be_nil
    end

    it 'leaves the element unchanged when the transformed URL does not match the allowlist' do
      image = link_to_image('https://www.figma.com/design/abc123')
      element = filter(image).children.first

      expect(element.name).to eq 'img'
    end
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
end
