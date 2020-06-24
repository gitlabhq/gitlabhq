# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::ImageLinkFilter do
  include FilterSpecHelper

  def image(path)
    %(<img src="#{path}" />)
  end

  it 'wraps the image with a link to the image src' do
    doc = filter(image('/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg'))
    expect(doc.at_css('img')['src']).to eq doc.at_css('a')['href']
  end

  it 'does not wrap a duplicate link' do
    doc = filter(%Q(<a href="/whatever">#{image('/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg')}</a>))
    expect(doc.to_html).to match %r{^<a href="/whatever"><img[^>]*></a>$}
  end

  it 'works with external images' do
    doc = filter(image('https://i.imgur.com/DfssX9C.jpg'))
    expect(doc.at_css('img')['src']).to eq doc.at_css('a')['href']
  end

  it 'works with inline images' do
    doc = filter(%Q(<p>test #{image('/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg')} inline</p>))
    expect(doc.to_html).to match %r{^<p>test <a[^>]*><img[^>]*></a> inline</p>$}
  end

  it 'keep the data-canonical-src' do
    doc = filter(%q(<img src="http://assets.example.com/6cd/4d7" data-canonical-src="http://example.com/test.png" />))

    expect(doc.at_css('img')['src']).to eq doc.at_css('a')['href']
    expect(doc.at_css('img')['data-canonical-src']).to eq doc.at_css('a')['data-canonical-src']
  end
end
