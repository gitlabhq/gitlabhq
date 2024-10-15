# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::ImageLazyLoadFilter, feature_category: :markdown do
  include FilterSpecHelper

  def image(path)
    %(<img src="#{path}" />)
  end

  def image_with_class(path, class_attr = nil)
    %(<img src="#{path}" class="#{class_attr}"/>)
  end

  it 'adds a class attribute' do
    doc = filter(image('/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg'))
    expect(doc.at_css('img')['class']).to eq 'lazy'
  end

  it 'appends to the current class attribute' do
    doc = filter(image_with_class('/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg', 'test'))
    expect(doc.at_css('img')['class']).to eq 'test lazy'
  end

  it 'adds a async decoding attribute' do
    doc = filter(image_with_class('/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg', 'test'))
    expect(doc.at_css('img')['decoding']).to eq 'async'
  end

  it 'transforms the image src to a data-src' do
    doc = filter(image('/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg'))
    expect(doc.at_css('img')['data-src']).to eq '/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg'
  end

  it 'works with external images' do
    doc = filter(image('https://i.imgur.com/DfssX9C.jpg'))
    expect(doc.at_css('img')['data-src']).to eq 'https://i.imgur.com/DfssX9C.jpg'
  end

  it_behaves_like 'pipeline timing check'
end
