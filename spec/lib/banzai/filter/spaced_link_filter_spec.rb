require 'spec_helper'

describe Banzai::Filter::SpacedLinkFilter do
  include FilterSpecHelper

  let(:link) { '[example](page slug)' }

  it 'converts slug with spaces to a link' do
    doc = filter("See #{link}")

    expect(doc.at_css('a').text).to eq 'example'
    expect(doc.at_css('a')['href']).to eq 'page%20slug'
    expect(doc.at_css('p')).to eq nil
  end

  it 'converts slug with spaces and a title to a link' do
    link = '[example](page slug "title")'
    doc  = filter("See #{link}")

    expect(doc.at_css('a').text).to eq 'example'
    expect(doc.at_css('a')['href']).to eq 'page%20slug'
    expect(doc.at_css('a')['title']).to eq 'title'
    expect(doc.at_css('p')).to eq nil
  end

  it 'does nothing when markdown_engine is redcarpet' do
    exp = act = link
    expect(filter(act, markdown_engine: :redcarpet).to_html).to eq exp
  end

  it 'does nothing with empty text' do
    link = '[](page slug)'
    doc  = filter("See #{link}")

    expect(doc.at_css('a')).to eq nil
  end

  it 'does nothing with an empty slug' do
    link = '[example]()'
    doc  = filter("See #{link}")

    expect(doc.at_css('a')).to eq nil
  end

  it 'converts multiple URLs' do
    link1 = '[first](slug one)'
    link2 = '[second](http://example.com/slug two)'
    doc   = filter("See #{link1} and #{link2}")

    found_links = doc.css('a')

    expect(found_links.size).to eq(2)
    expect(found_links[0].text).to eq 'first'
    expect(found_links[0]['href']).to eq 'slug%20one'
    expect(found_links[1].text).to eq 'second'
    expect(found_links[1]['href']).to eq 'http://example.com/slug%20two'
  end

  described_class::IGNORE_PARENTS.each do |elem|
    it "ignores valid links contained inside '#{elem}' element" do
      exp = act = "<#{elem}>See #{link}</#{elem}>"

      expect(filter(act).to_html).to eq exp
    end
  end
end
