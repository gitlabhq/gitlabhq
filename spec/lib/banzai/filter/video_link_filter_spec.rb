# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::VideoLinkFilter, feature_category: :markdown do
  def filter(doc, contexts = {})
    contexts.reverse_merge!({
      project: project
    })

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

  shared_examples 'a video element' do
    let(:image) { link_to_image(src, height, width) }

    it 'replaces the image tag with a video tag' do
      container = filter(image).children.first

      expect(container.name).to eq 'span'
      expect(container['class']).to eq 'media-container video-container'

      video, link = container.children

      expect(video.name).to eq 'video'
      expect(video['src']).to eq src
      expect(video['height']).to eq height if height
      expect(video['width']).to eq width if width
      expect(video['preload']).to eq 'metadata'

      expect(link.name).to eq 'a'
      expect(link['href']).to eq src
      expect(link['target']).to eq '_blank'
    end
  end

  shared_examples 'an unchanged element' do |ext|
    it 'leaves the document unchanged' do
      element = filter(link_to_image(src)).children.first

      expect(element.name).to eq 'img'
      expect(element['src']).to eq src
    end
  end

  context 'when the element src has a video extension' do
    let(:height) { nil }
    let(:width) { nil }

    Gitlab::FileTypeDetection::SAFE_VIDEO_EXT.each do |ext|
      it_behaves_like 'a video element' do
        let(:src) { "/path/video.#{ext}" }
      end

      it_behaves_like 'a video element' do
        let(:src) { "/path/video.#{ext.upcase}" }
      end
    end
  end

  context 'when the element has height or width specified' do
    let(:src) { '/path/video.mp4' }

    it_behaves_like 'a video element' do
      let(:height) { '100%' }
      let(:width) { '50px' }
    end

    it_behaves_like 'a video element' do
      let(:height) { nil }
      let(:width) { '50px' }
    end

    it_behaves_like 'a video element' do
      let(:height) { '50px' }
      let(:width) { nil }
    end
  end

  context 'when the element has no src attribute' do
    let(:src) { nil }

    it_behaves_like 'an unchanged element'
  end

  context 'when the element src is an image' do
    let(:src) { '/path/my_image.jpg' }

    it_behaves_like 'an unchanged element'
  end

  context 'when the element src has an invalid file extension' do
    let(:src) { '/path/my_video.somemp4' }

    it_behaves_like 'an unchanged element'
  end

  context 'when data-canonical-src is empty' do
    let(:image) { %(<img src="#{src}" data-canonical-src=""/>) }

    context 'and src is a video' do
      let(:src) { '/path/video.mp4' }
      let(:height) { nil }
      let(:width) { nil }

      it_behaves_like 'a video element'
    end

    context 'and src is an image' do
      let(:src) { '/path/my_image.jpg' }

      it_behaves_like 'an unchanged element'
    end
  end

  context 'when data-canonical-src is set' do
    it 'uses the correct src' do
      proxy_src = 'https://assets.example.com/6d8b63'
      canonical_src = 'http://example.com/test.mp4'
      image = %(<img src="#{proxy_src}" data-canonical-src="#{canonical_src}"/>)
      container = filter(image).children.first

      expect(container['class']).to eq 'media-container video-container'

      video, link = container.children

      expect(video['src']).to eq proxy_src
      expect(video['data-canonical-src']).to eq canonical_src

      expect(link['href']).to eq proxy_src
    end
  end

  it_behaves_like 'pipeline timing check'
end
