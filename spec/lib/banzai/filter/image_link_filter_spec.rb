# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::ImageLinkFilter do
  include FilterSpecHelper

  let(:path) { '/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg' }
  let(:context) { {} }

  def image(path, alt: nil, data_src: nil)
    alt_tag = alt ? %Q{alt="#{alt}"} : ""
    data_src_tag = data_src ? %Q{data-src="#{data_src}"} : ""

    %(<img src="#{path}" #{alt_tag} #{data_src_tag} />)
  end

  it 'wraps the image with a link to the image src' do
    doc = filter(image(path), context)

    expect(doc.at_css('img')['src']).to eq doc.at_css('a')['href']
  end

  it 'does not wrap a duplicate link' do
    doc = filter(%Q(<a href="/whatever">#{image(path)}</a>), context)

    expect(doc.to_html).to match %r{^<a href="/whatever"><img[^>]*></a>$}
  end

  it 'works with external images' do
    doc = filter(image('https://i.imgur.com/DfssX9C.jpg'), context)

    expect(doc.at_css('img')['src']).to eq doc.at_css('a')['href']
  end

  it 'works with inline images' do
    doc = filter(%Q(<p>test #{image(path)} inline</p>), context)

    expect(doc.to_html).to match %r{^<p>test <a[^>]*><img[^>]*></a> inline</p>$}
  end

  it 'keep the data-canonical-src' do
    doc = filter(%q(<img src="http://assets.example.com/6cd/4d7" data-canonical-src="http://example.com/test.png" />), context)

    expect(doc.at_css('img')['src']).to eq doc.at_css('a')['href']
    expect(doc.at_css('img')['data-canonical-src']).to eq doc.at_css('a')['data-canonical-src']
  end

  it 'adds no-attachment icon class to the link' do
    doc = filter(image(path), context)

    expect(doc.at_css('a')['class']).to match(%r{no-attachment-icon})
  end

  context 'when :link_replaces_image is true' do
    let(:context) { { link_replaces_image: true } }

    it 'replaces the image with link to image src', :aggregate_failures do
      doc = filter(image(path), context)

      expect(doc.to_html).to match(%r{^<a[^>]*>#{path}</a>$})
      expect(doc.at_css('a')['href']).to eq(path)
    end

    it 'uses image alt as a link text', :aggregate_failures do
      doc = filter(image(path, alt: 'My image'), context)

      expect(doc.to_html).to match(%r{^<a[^>]*>My image</a>$})
      expect(doc.at_css('a')['href']).to eq(path)
    end

    it 'uses image data-src as a link text', :aggregate_failures do
      data_src = '/uploads/data-src.png'
      doc = filter(image(path, data_src: data_src), context)

      expect(doc.to_html).to match(%r{^<a[^>]*>#{data_src}</a>$})
      expect(doc.at_css('a')['href']).to eq(data_src)
    end

    it 'adds attachment icon class to the link' do
      doc = filter(image(path), context)

      expect(doc.at_css('a')['class']).to match(%r{with-attachment-icon})
    end
  end
end
