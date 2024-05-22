# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::GollumTagsFilter, feature_category: :wiki do
  include FilterSpecHelper

  let(:project) { create(:project) }
  let(:wiki) { ProjectWiki.new(project, nil) }

  describe 'validation' do
    it 'ensure that a :wiki key exists in context' do
      expect { filter("See [[images/image.jpg]]", {}) }.to raise_error ArgumentError, "Missing context keys for Banzai::Filter::GollumTagsFilter: :wiki"
    end
  end

  context 'linking internal images' do
    it 'creates img tag if image exists' do
      blob = double(mime_type: 'image/jpeg', name: 'images/image.jpg', path: 'images/image.jpg', data: '')
      wiki_file = Gitlab::Git::WikiFile.new(blob)
      expect(wiki).to receive(:find_file).with('images/image.jpg', load_content: false).and_return(wiki_file)

      tag = '[[images/image.jpg]]'
      doc = filter("See #{tag}", wiki: wiki)

      expect(doc.at_css('img')['src']).to eq 'images/image.jpg'
    end

    it 'does not creates img tag if image does not exist' do
      expect(wiki).to receive(:find_file).with('images/image.jpg', load_content: false).and_return(nil)

      tag = '[[images/image.jpg]]'
      doc = filter("See #{tag}", wiki: wiki)

      expect(doc.css('img').size).to eq 0
    end
  end

  context 'linking external images' do
    it 'creates img tag for valid URL' do
      tag = '[[http://example.com/image.jpg]]'
      doc = filter("See #{tag}", wiki: wiki)

      expect(doc.at_css('img')['src']).to eq "http://example.com/image.jpg"
    end

    it 'does not creates img tag for invalid URL' do
      tag = '[[http://example.com/image.pdf]]'
      doc = filter("See #{tag}", wiki: wiki)

      expect(doc.css('img').size).to eq 0
    end
  end

  context 'linking external resources' do
    it "the created link's text will be equal to the resource's text" do
      tag = '[[http://example.com]]'
      doc = filter("See #{tag}", wiki: wiki)

      expect(doc.at_css('a').text).to eq 'http://example.com'
      expect(doc.at_css('a')['href']).to eq 'http://example.com'
    end

    it "the created link's text will be link-text" do
      tag = '[[link-text|http://example.com/pdfs/gollum.pdf]]'
      doc = filter("See #{tag}", wiki: wiki)

      expect(doc.at_css('a').text).to eq 'link-text'
      expect(doc.at_css('a')['href']).to eq 'http://example.com/pdfs/gollum.pdf'
    end
  end

  context 'linking internal resources' do
    it "the created link's text includes the resource's text and wiki base path" do
      tag = '[[wiki-slug]]'
      doc = filter("See #{tag}", wiki: wiki)
      expected_path = ::File.join(wiki.wiki_base_path, 'wiki-slug')

      expect(doc.at_css('a').text).to eq 'wiki-slug'
      expect(doc.at_css('a')['href']).to eq expected_path
    end

    it "the created link's text will be link-text" do
      tag = '[[link-text|wiki-slug]]'
      doc = filter("See #{tag}", wiki: wiki)
      expected_path = ::File.join(wiki.wiki_base_path, 'wiki-slug')

      expect(doc.at_css('a').text).to eq 'link-text'
      expect(doc.at_css('a')['href']).to eq expected_path
    end

    it "inside back ticks will be exempt from linkification" do
      doc = filter('<code>[[link-in-backticks]]</code>', wiki: wiki)

      expect(doc.at_css('code').text).to eq '[[link-in-backticks]]'
    end

    it "sanitizes the href attribute (case 1)" do
      tag = '[[a|http:\'"injected=attribute&gt;&lt;img/src="0"onerror="alert(0)"&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1]]'
      doc = filter("See #{tag}", wiki: wiki)

      expect(doc.at_css('a').to_html).to eq '<a href="http:\'%22injected=attribute&gt;&lt;img/src=%220%22onerror=%22alert(0)%22&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1" class="gfm">a</a>'
    end

    it "sanitizes the href attribute (case 2)" do
      tag = '<i>[[a|\'"&gt;&lt;svg&gt;&lt;i/class=gl-show-field-errors&gt;&lt;input/title="&lt;script&gt;alert(0)&lt;/script&gt;"/&gt;&lt;/svg&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1]]'
      doc = filter("See #{tag}", wiki: wiki)

      expect(doc.at_css('i a').to_html).to eq "<a href=\"#{wiki.wiki_base_path}/\'%22&gt;&lt;svg&gt;&lt;i/class=gl-show-field-errors&gt;&lt;input/title=%22&lt;script&gt;alert(0)&lt;/script&gt;%22/&gt;&lt;/svg&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1\" class=\"gfm\">a</a>"
    end
  end

  it 'protects against malicious input' do
    text = "]#{'[[a' * 200000}[]"

    expect do
      Timeout.timeout(3.seconds) { filter(text, wiki: wiki) }
    end.not_to raise_error
  end
end
