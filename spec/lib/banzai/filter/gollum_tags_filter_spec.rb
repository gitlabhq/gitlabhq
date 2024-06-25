# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::GollumTagsFilter, feature_category: :wiki do
  include FilterSpecHelper

  let_it_be(:project) { create(:project) }
  let_it_be(:wiki) { create(:project_wiki, project: project) }
  let_it_be(:group) { create(:group) }

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

    it 'does not add `gfm-gollum-wiki-page` class to the link' do
      tag = '[[http://example.com]]'
      doc = filter("See #{tag}", wiki: wiki)

      expect(doc.at_css('a')['class']).to eq 'gfm'
    end
  end

  context 'linking internal resources' do
    it "the created link's text includes the resource's text and wiki base path" do
      tag = '[[wiki-slug]]'
      doc = filter("See #{tag}", wiki: wiki)
      expected_path = ::File.join(wiki.wiki_base_path, 'wiki-slug')

      expect(doc.at_css('a').text).to eq 'wiki-slug'
      expect(doc.at_css('a')['href']).to eq expected_path
      expect(doc.at_css('a')['data-reference-type']).to eq 'wiki_page'
      expect(doc.at_css('a')['data-canonical-src']).to eq 'wiki-slug'
      expect(doc.at_css('a')['data-gollum']).to eq 'true'
      expect(doc.at_css('a')['data-project']).to eq project.id.to_s
      expect(doc.at_css('a')['data-group']).to be_nil
      expect(doc.at_css('a')['class']).to eq 'gfm gfm-gollum-wiki-page'
    end

    it "the created link's text will be link-text" do
      tag = '[[link-text|wiki-slug]]'
      doc = filter("See #{tag}", wiki: wiki)
      expected_path = ::File.join(wiki.wiki_base_path, 'wiki-slug')

      expect(doc.at_css('a').text).to eq 'link-text'
      expect(doc.at_css('a')['href']).to eq expected_path
    end

    it 'inside back ticks will be exempt from linkification' do
      doc = filter('<code>[[link-in-backticks]]</code>', wiki: wiki)

      expect(doc.at_css('code').text).to eq '[[link-in-backticks]]'
    end

    it 'handles group wiki links' do
      tag = '[[wiki-slug]]'
      doc = filter("See #{tag}", project: nil, group: group, wiki: wiki)
      expected_path = ::File.join(wiki.wiki_base_path, 'wiki-slug')

      expect(doc.at_css('a').text).to eq 'wiki-slug'
      expect(doc.at_css('a')['href']).to eq expected_path
      expect(doc.at_css('a')['data-reference-type']).to eq 'wiki_page'
      expect(doc.at_css('a')['data-canonical-src']).to eq 'wiki-slug'
      expect(doc.at_css('a')['data-gollum']).to eq 'true'
      expect(doc.at_css('a')['data-project']).to be_nil
      expect(doc.at_css('a')['data-group']).to eq group.id.to_s
      expect(doc.at_css('a')['class']).to eq 'gfm gfm-gollum-wiki-page'
    end
  end

  it 'leaves other text content untouched' do
    doc = filter('This is [[a link|link]]', wiki: wiki)

    expect(doc.to_html).to eq "This is <a href=\"#{wiki.wiki_base_path}/link\" class=\"gfm gfm-gollum-wiki-page\" data-canonical-src=\"link\" data-link=\"true\" data-gollum=\"true\" data-reference-type=\"wiki_page\" data-project=\"#{project.id}\"\>a link</a>"
  end

  context 'sanitization of HTML entities' do
    it 'does not unescape HTML entities' do
      doc = filter('This is [[a link|&lt;script&gt;alert(0)&lt;/script&gt;]]', wiki: wiki)

      expect(doc.to_html).to eq "This is <a href=\"#{wiki.wiki_base_path}/&lt;script&gt;alert(0)&lt;/script&gt;\" class=\"gfm gfm-gollum-wiki-page\" data-canonical-src=\"&lt;script&gt;alert(0)&lt;/script&gt;\" data-link=\"true\" data-gollum=\"true\" data-reference-type=\"wiki_page\" data-project=\"#{project.id}\">a link</a>"
    end

    it 'does not unescape HTML entities in the link text' do
      doc = filter('This is [[&lt;script&gt;alert(0)&lt;/script&gt;|link]]', wiki: wiki)

      expect(doc.to_html).to eq "This is <a href=\"#{wiki.wiki_base_path}/link\" class=\"gfm gfm-gollum-wiki-page\" data-canonical-src=\"link\" data-link=\"true\" data-gollum=\"true\" data-reference-type=\"wiki_page\" data-project=\"#{project.id}\">&lt;script&gt;alert(0)&lt;/script&gt;</a>"
    end

    it 'does not unescape HTML entities outside the link text' do
      doc = filter('This is &lt;script&gt;alert(0)&lt;/script&gt; [[a link|link]]', wiki: wiki)

      # This is <script>alert(0)</script> <a href="/namespace1/project-1/-/wikis/link" class="gfm gfm-gollum-wiki-page" data-canonical-src="link" data-link="true" data-gollum="true" data-reference-type="wiki_page" data-project="8">a link</a>

      expect(doc.to_html).to eq "This is &lt;script&gt;alert(0)&lt;/script&gt; <a href=\"#{wiki.wiki_base_path}/link\" class=\"gfm gfm-gollum-wiki-page\" data-canonical-src=\"link\" data-link=\"true\" data-gollum=\"true\" data-reference-type=\"wiki_page\" data-project=\"#{project.id}\">a link</a>"
    end
  end

  it 'adds `gfm-gollum-wiki-page` classes to the link' do
    tag = '[[wiki-slug]]'
    doc = filter("See #{tag}", wiki: wiki)

    expect(doc.at_css('a')['class']).to eq 'gfm gfm-gollum-wiki-page'
  end

  it 'sanitizes the href attribute (case 1)' do
    tag = '[[a|http:\'"injected=attribute&gt;&lt;img/src="0"onerror="alert(0)"&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1]]'
    doc = filter("See #{tag}", wiki: wiki)

    expect(doc.at_css('a').to_html).to eq '<a href="http:\'%22injected=attribute&gt;&lt;img/src=%220%22onerror=%22alert(0)%22&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1" class="gfm" data-canonical-src="http:\'&quot;injected=attribute&gt;&lt;img/src=&quot;0&quot;onerror=&quot;alert(0)&quot;&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1" data-link="true" data-gollum="true">a</a>'
  end

  it 'sanitizes the href attribute (case 2)' do
    tag = '<i>[[a|\'"&gt;&lt;svg&gt;&lt;i/class=gl-show-field-errors&gt;&lt;input/title="&lt;script&gt;alert(0)&lt;/script&gt;"/&gt;&lt;/svg&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1]]'
    doc = filter("See #{tag}", wiki: wiki)

    expect(doc.at_css('i a').to_html).to eq "<a href=\"#{wiki.wiki_base_path}/'%22&gt;&lt;svg&gt;&lt;i/class=gl-show-field-errors&gt;&lt;input/title=%22&lt;script&gt;alert(0)&lt;/script&gt;%22/&gt;&lt;/svg&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1\" class=\"gfm gfm-gollum-wiki-page\" data-canonical-src=\"'&quot;&gt;&lt;svg&gt;&lt;i/class=gl-show-field-errors&gt;&lt;input/title=&quot;&lt;script&gt;alert(0)&lt;/script&gt;&quot;/&gt;&lt;/svg&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1\" data-link=\"true\" data-gollum=\"true\" data-reference-type=\"wiki_page\" data-project=\"#{project.id}\">a</a>"
  end

  it 'protects against malicious input' do
    text = "]#{'[[a' * 200000}[]"

    expect do
      Timeout.timeout(3.seconds) { filter(text, wiki: wiki) }
    end.not_to raise_error
  end

  it_behaves_like 'pipeline timing check'
end
