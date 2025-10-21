# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::IframeLinkFilter, feature_category: :markdown do
  def filter(doc, contexts = {})
    contexts.reverse_merge!({ project: project })

    described_class.call(doc, contexts)
  end

  def link_to_image(path, height = nil, width = nil)
    return '<img/>' if path.nil?

    attrs = %(src="#{path}")
    attrs += %( width="#{width}") if width
    attrs += %( height="#{height}") if height

    %(<img #{attrs}/>)
  end

  let_it_be(:project) { create(:project, :repository) }

  shared_examples 'an iframe element' do
    let(:image) { link_to_image(src, height, width) }

    it 'replaces the image tag with a media container and image tag' do
      container = filter(image).children.first

      expect(container.name).to eq 'span'
      expect(container['class']).to eq 'media-container img-container'

      link, iframe = container.children

      expect(iframe.name).to eq 'img'
      expect(iframe['src']).to eq src
      expect(iframe['height']).to eq height if height
      expect(iframe['width']).to eq width if width

      expect(link.name).to eq 'a'
      expect(link['href']).to eq src
      expect(link['target']).to eq '_blank'
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
    let(:height) { nil }
    let(:width) { nil }

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
      let(:height) { nil }
      let(:width) { '50px' }
    end

    it_behaves_like 'an iframe element' do
      let(:height) { '50px' }
      let(:width) { nil }
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

  context 'when data-canonical-src is empty' do
    let(:image) { %(<img src="#{src}" data-canonical-src=""/>) }

    context 'and src is for an iframe' do
      let(:src) { "https://www.youtube.com/embed/foo" }
      let(:height) { nil }
      let(:width) { nil }

      it_behaves_like 'an iframe element'
    end

    context 'and src is an image' do
      let(:src) { 'https://path/my_image.jpg' }

      it_behaves_like 'an unchanged element'
    end
  end

  context 'when data-canonical-src is set' do
    it 'uses the correct src' do
      proxy_src = 'https://assets.example.com/6d8b63'
      canonical_src = 'https://www.youtube.com/embed/foo'
      image = %(<img src="#{proxy_src}" data-canonical-src="#{canonical_src}"/>)
      container = filter(image).children.first

      expect(container['class']).to eq 'media-container img-container'

      link, iframe = container.children

      expect(iframe['src']).to eq proxy_src
      expect(iframe['data-canonical-src']).to eq canonical_src

      expect(link['href']).to eq proxy_src
    end
  end

  context 'when allow_iframes_in_markdown is disabled' do
    let(:src) { 'https://www.youtube.com/embed/foo' }

    before do
      stub_feature_flags(allow_iframes_in_markdown: false)
    end

    it_behaves_like 'an unchanged element'
  end

  it_behaves_like 'pipeline timing check'
end
