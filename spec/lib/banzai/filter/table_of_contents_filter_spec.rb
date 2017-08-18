require 'spec_helper'

describe Banzai::Filter::TableOfContentsFilter do
  include FilterSpecHelper

  def header(level, text)
    "<h#{level}>#{text}</h#{level}>\n"
  end

  it 'does nothing when :no_header_anchors is truthy' do
    exp = act = header(1, 'Header')
    expect(filter(act, no_header_anchors: 1).to_html).to eq exp
  end

  it 'does nothing with empty headers' do
    exp = act = header(1, nil)
    expect(filter(act).to_html).to eq exp
  end

  1.upto(6) do |i|
    it "processes h#{i} elements" do
      html = header(i, "Header #{i}")
      doc = filter(html)

      expect(doc.css("h#{i} a").first.attr('id')).to eq "user-content-header-#{i}"
    end
  end

  describe 'anchor tag' do
    it 'has an `anchor` class' do
      doc = filter(header(1, 'Header'))
      expect(doc.css('h1 a').first.attr('class')).to eq 'anchor'
    end

    it 'has a namespaced id' do
      doc = filter(header(1, 'Header'))
      expect(doc.css('h1 a').first.attr('id')).to eq 'user-content-header'
    end

    it 'links to the non-namespaced id' do
      doc = filter(header(1, 'Header'))
      expect(doc.css('h1 a').first.attr('href')).to eq '#header'
    end

    describe 'generated IDs' do
      it 'translates spaces to dashes' do
        doc = filter(header(1, 'This header has spaces in it'))
        expect(doc.css('h1 a').first.attr('href')).to eq '#this-header-has-spaces-in-it'
      end

      it 'squeezes multiple spaces and dashes' do
        doc = filter(header(1, 'This---header     is poorly-formatted'))
        expect(doc.css('h1 a').first.attr('href')).to eq '#this-header-is-poorly-formatted'
      end

      it 'removes punctuation' do
        doc = filter(header(1, "This, header! is, filled. with @ punctuation?"))
        expect(doc.css('h1 a').first.attr('href')).to eq '#this-header-is-filled-with-punctuation'
      end

      it 'appends a unique number to duplicates' do
        doc = filter(header(1, 'One') + header(2, 'One'))

        expect(doc.css('h1 a').first.attr('href')).to eq '#one'
        expect(doc.css('h2 a').first.attr('href')).to eq '#one-1'
      end

      it 'supports Unicode' do
        doc = filter(header(1, '한글'))
        expect(doc.css('h1 a').first.attr('id')).to eq 'user-content-한글'
        expect(doc.css('h1 a').first.attr('href')).to eq '#한글'
      end
    end
  end

  describe 'result' do
    def result(html)
      HTML::Pipeline.new([described_class]).call(html)
    end

    let(:results) { result(header(1, 'Header 1') + header(2, 'Header 1-1') + header(3, 'Header 1-1-1') + header(2, 'Header 1-2') + header(1, 'Header 2') + header(2, 'Header 2-1')) }
    let(:doc) { Nokogiri::XML::DocumentFragment.parse(results[:toc]) }

    it 'is contained within a `ul` element' do
      expect(doc.children.first.name).to eq 'ul'
      expect(doc.children.first.attr('class')).to eq 'section-nav'
    end

    it 'contains an `li` element for each header' do
      expect(doc.css('li').length).to eq 6

      links = doc.css('li a')

      expect(links[0].attr('href')).to eq '#header-1'
      expect(links[0].text).to eq 'Header 1'
      expect(links[1].attr('href')).to eq '#header-1-1'
      expect(links[1].text).to eq 'Header 1-1'
      expect(links[2].attr('href')).to eq '#header-1-1-1'
      expect(links[2].text).to eq 'Header 1-1-1'
      expect(links[3].attr('href')).to eq '#header-1-2'
      expect(links[3].text).to eq 'Header 1-2'
      expect(links[4].attr('href')).to eq '#header-2'
      expect(links[4].text).to eq 'Header 2'
      expect(links[5].attr('href')).to eq '#header-2-1'
      expect(links[5].text).to eq 'Header 2-1'
    end

    it 'keeps list levels regarding header levels' do
      items = doc.css('li')

      # Header 1
      expect(items[0].ancestors.any? {|node| node.name == 'li'}).to eq false

      # Header 1-1
      expect(items[1].ancestors.include?(items[0])).to eq true

      # Header 1-1-1
      expect(items[2].ancestors.include?(items[0])).to eq true
      expect(items[2].ancestors.include?(items[1])).to eq true

      # Header 1-2
      expect(items[3].ancestors.include?(items[0])).to eq true
      expect(items[3].ancestors.include?(items[1])).to eq false

      # Header 2
      expect(items[4].ancestors.any? {|node| node.name == 'li'}).to eq false

      # Header 2-1
      expect(items[5].ancestors.include?(items[4])).to eq true
    end
  end
end
