require 'spec_helper'

describe Banzai::Filter::SpacedLinkFilter do
  include FilterSpecHelper

  let(:link)  { '[example](page slug)' }
  let(:image) { '![example](img test.jpg)' }

  context 'when a link is detected' do
    it 'converts slug with spaces to a link' do
      doc = filter("See #{link}")

      expect(doc.at_css('a').text).to eq 'example'
      expect(doc.at_css('a')['href']).to eq 'page%20slug'
      expect(doc.at_css('a')['title']).to be_nil
      expect(doc.at_css('p')).to be_nil
    end

    it 'converts slug with spaces and a title to a link' do
      link = '[example](page slug "title")'
      doc  = filter("See #{link}")

      expect(doc.at_css('a').text).to eq 'example'
      expect(doc.at_css('a')['href']).to eq 'page%20slug'
      expect(doc.at_css('a')['title']).to eq 'title'
      expect(doc.at_css('p')).to be_nil
    end

    it 'does nothing when markdown_engine is redcarpet' do
      exp = act = link
      expect(filter(act, markdown_engine: :redcarpet).to_html).to eq exp
    end

    it 'does nothing with empty text' do
      link = '[](page slug)'
      doc  = filter("See #{link}")

      expect(doc.at_css('a')).to be_nil
    end

    it 'does nothing with an empty slug' do
      link = '[example]()'
      doc  = filter("See #{link}")

      expect(doc.at_css('a')).to be_nil
    end
  end

  context 'when an image is detected' do
    it 'converts slug with spaces to an iamge' do
      doc = filter("See #{image}")

      expect(doc.at_css('img')['src']).to eq 'img%20test.jpg'
      expect(doc.at_css('img')['alt']).to eq 'example'
      expect(doc.at_css('p')).to be_nil
    end

    it 'converts slug with spaces and a title to an image' do
      image = '![example](img test.jpg "title")'
      doc   = filter("See #{image}")

      expect(doc.at_css('img')['src']).to eq 'img%20test.jpg'
      expect(doc.at_css('img')['alt']).to eq 'example'
      expect(doc.at_css('img')['title']).to eq 'title'
      expect(doc.at_css('p')).to be_nil
    end
  end

  it 'converts multiple URLs' do
    link1 = '[first](slug one)'
    link2 = '[second](http://example.com/slug two)'
    doc   = filter("See #{link1} and #{image} and #{link2}")

    found_links = doc.css('a')

    expect(found_links.size).to eq(2)
    expect(found_links[0].text).to eq 'first'
    expect(found_links[0]['href']).to eq 'slug%20one'
    expect(found_links[1].text).to eq 'second'
    expect(found_links[1]['href']).to eq 'http://example.com/slug%20two'

    found_images = doc.css('img')

    expect(found_images.size).to eq(1)
    expect(found_images[0]['src']).to eq 'img%20test.jpg'
    expect(found_images[0]['alt']).to eq 'example'
  end

  described_class::IGNORE_PARENTS.each do |elem|
    it "ignores valid links contained inside '#{elem}' element" do
      exp = act = "<#{elem}>See #{link}</#{elem}>"

      expect(filter(act).to_html).to eq exp
    end
  end
end
