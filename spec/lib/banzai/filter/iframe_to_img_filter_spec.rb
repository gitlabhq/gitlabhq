# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::IframeToImgFilter, feature_category: :markdown do
  def filter(html)
    described_class.call(html, {})
  end

  before do
    allow(Gitlab::CurrentSettings).to receive(:iframe_rendering_enabled?).and_return(true)
  end

  context 'when an iframe has a src attribute' do
    it 'converts the iframe to an img tag' do
      html = '<iframe src="https://www.youtube.com/embed/abc123"></iframe>'
      result = filter(html)

      img = result.at_css('img')
      expect(img).to be_present
      expect(img['src']).to eq 'https://www.youtube.com/embed/abc123'
      expect(result.at_css('iframe')).to be_nil
    end

    it 'preserves width and height attributes' do
      html = '<iframe src="https://www.youtube.com/embed/abc123" width="560" height="315"></iframe>'
      result = filter(html)

      img = result.at_css('img')
      expect(img['src']).to eq 'https://www.youtube.com/embed/abc123'
      expect(img['width']).to eq '560'
      expect(img['height']).to eq '315'
    end

    it 'preserves only width when height is absent' do
      html = '<iframe src="https://www.youtube.com/embed/abc123" width="560"></iframe>'
      result = filter(html)

      img = result.at_css('img')
      expect(img['width']).to eq '560'
      expect(img['height']).to be_nil
    end

    it 'preserves only height when width is absent' do
      html = '<iframe src="https://embed.figma.com/design/abc" height="450"></iframe>'
      result = filter(html)

      img = result.at_css('img')
      expect(img['height']).to eq '450'
      expect(img['width']).to be_nil
    end

    it 'does not carry over unsafe attributes' do
      html = '<iframe src="https://www.youtube.com/embed/abc123" onload="alert(1)" style="display:none"></iframe>'
      result = filter(html)

      img = result.at_css('img')
      expect(img['onload']).to be_nil
      expect(img['style']).to be_nil
    end

    it 'converts iframes regardless of domain' do
      html = '<iframe src="https://evil.example.com/embed"></iframe>'
      result = filter(html)

      img = result.at_css('img')
      expect(img).to be_present
      expect(img['src']).to eq 'https://evil.example.com/embed'
    end
  end

  context 'when the iframe has no src attribute' do
    it 'leaves the iframe unchanged' do
      html = '<iframe></iframe>'
      result = filter(html)

      expect(result.at_css('iframe')).to be_present
      expect(result.at_css('img')).to be_nil
    end
  end

  context 'when iframe_rendering_enabled is false' do
    before do
      allow(Gitlab::CurrentSettings).to receive(:iframe_rendering_enabled?).and_return(false)
    end

    it 'does not convert iframes' do
      html = '<iframe src="https://www.youtube.com/embed/abc123"></iframe>'
      result = filter(html)

      expect(result.at_css('iframe')).to be_present
      expect(result.at_css('img')).to be_nil
    end
  end

  context 'with multiple iframes' do
    it 'converts all iframes with src attributes' do
      html = <<~HTML
        <iframe src="https://www.youtube.com/embed/abc123"></iframe>
        <iframe src="https://example.com/embed"></iframe>
        <iframe></iframe>
      HTML
      result = filter(html)

      imgs = result.css('img')
      expect(imgs.length).to eq 2
      expect(imgs[0]['src']).to eq 'https://www.youtube.com/embed/abc123'
      expect(imgs[1]['src']).to eq 'https://example.com/embed'

      iframes = result.css('iframe')
      expect(iframes.length).to eq 1
    end
  end

  it_behaves_like 'pipeline timing check'
end
