require 'spec_helper'

describe Banzai::Filter::ImageLazyLoadFilter, lib: true do
  include FilterSpecHelper

  def image(path)
    %(<img src="#{path}" />)
  end

  it 'transforms the image src to a data-src' do
    doc = filter(image('/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg'))
    expect(doc.at_css('img')['data-src']).to eq '/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg'
  end

  it 'works with external images' do
    doc = filter(image('https://i.imgur.com/DfssX9C.jpg'))
    expect(doc.at_css('img')['data-src']).to eq 'https://i.imgur.com/DfssX9C.jpg'
  end
end
