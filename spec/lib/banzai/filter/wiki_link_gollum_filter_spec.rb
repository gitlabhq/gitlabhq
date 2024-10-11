# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::WikiLinkGollumFilter, feature_category: :wiki do
  include FilterSpecHelper

  let_it_be(:project) { create(:project) }
  let_it_be(:wiki) { create(:project_wiki, project: project) }
  let_it_be(:group) { create(:group) }

  context 'when link is not external or to a wiki' do
    it 'does not add additional classes or attributes' do
      tag = '[[Something|unknown]]'
      doc = pipeline_filter("See #{tag}", project: nil)

      expect(doc.to_html).to eq '<p dir="auto">See <a href="unknown" data-wikilink="true">Something</a></p>'
    end
  end

  context 'when linking internal images' do
    it 'creates img tag if image exists' do
      blob = instance_double('Gitlab::Git::Blob', mime_type: 'image/jpeg',
        name: 'images/image.jpg', path: 'images/image.jpg', data: '')
      wiki_file = Gitlab::Git::WikiFile.new(blob)
      expect(wiki).to receive(:find_file).with('images/image.jpg', load_content: false).and_return(wiki_file)

      tag = '[[images/image.jpg]]'
      doc = pipeline_filter("See #{tag}", wiki: wiki)

      expect(doc.at_css('img')['src']).to eq LazyImageTagHelper.placeholder_image
      expect(doc.at_css('img')['data-src']).to eq 'images/image.jpg'
      expect(doc.at_css('img').classes).to include 'gfm'
    end

    it 'does not creates img tag if image does not exist' do
      expect(wiki).to receive(:find_file).with('images/image.jpg', load_content: false).and_return(nil)

      tag = '[[images/image.jpg]]'
      doc = pipeline_filter("See #{tag}", wiki: wiki)

      expect(doc.css('img').size).to eq 0
    end
  end

  context 'when linking external images' do
    it 'creates img tag for valid URL' do
      tag = '[[http://example.com/image.jpg]]'
      doc = pipeline_filter("See #{tag}", wiki: wiki)

      expect(doc.at_css('img')['src']).to eq LazyImageTagHelper.placeholder_image
      expect(doc.at_css('img')['data-src']).to eq 'http://example.com/image.jpg'
    end

    it 'does not creates img tag for invalid URL' do
      tag = '[[http://example.com/image.pdf]]'
      doc = pipeline_filter("See #{tag}", wiki: wiki)

      expect(doc.css('img').size).to eq 0
    end
  end

  context 'when linking external resources' do
    it 'created link text will be equal to the resource text' do
      tag = '[[http://example.com]]'
      doc = pipeline_filter("See #{tag}", wiki: wiki)

      expect(doc.at_css('a').text).to eq 'http://example.com'
      expect(doc.at_css('a')['href']).to eq 'http://example.com'
    end

    it 'created link text will be link-text' do
      tag = '[[link-text|http://example.com/pdfs/gollum.pdf]]'
      doc = pipeline_filter("See #{tag}", wiki: wiki)

      expect(doc.at_css('a').text).to eq 'link-text'
      expect(doc.at_css('a')['href']).to eq 'http://example.com/pdfs/gollum.pdf'
    end

    it 'does not add `gfm-gollum-wiki-page` class to the link' do
      tag = '[[http://example.com]]'
      doc = pipeline_filter("See #{tag}", wiki: wiki)

      expect(doc.at_css('a')['class']).to eq 'gfm'
    end
  end

  context 'when linking internal resources' do
    it 'created link text includes the resource text and wiki base path' do
      tag = '[[wiki-slug]]'
      doc = pipeline_filter("See #{tag}", wiki: wiki)
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

    it 'created link text will be link-text' do
      tag = '[[link-text|wiki-slug]]'
      doc = pipeline_filter("See #{tag}", wiki: wiki)
      expected_path = ::File.join(wiki.wiki_base_path, 'wiki-slug')

      expect(doc.at_css('a').text).to eq 'link-text'
      expect(doc.at_css('a')['href']).to eq expected_path
    end

    it 'inside back ticks will be exempt from linkification' do
      doc = pipeline_filter('`[[link-in-backticks]]`', wiki: wiki)

      expect(doc.at_css('code').text).to eq '[[link-in-backticks]]'
    end

    it 'handles escaping brackets in title' do
      tag = '[[this \[and\] that]]'
      doc = pipeline_filter("See #{tag}", wiki: wiki)
      expected_path = ::File.join(wiki.wiki_base_path, 'this%20%5Band%5D%20that')

      expect(doc.at_css('a').text).to eq 'this [and] that'
      expect(doc.at_css('a')['href']).to eq expected_path
    end

    it 'handles group wiki links' do
      tag = '[[wiki-slug]]'
      doc = pipeline_filter("See #{tag}", project: nil, group: group, wiki: wiki)
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
    doc = pipeline_filter('This is [[a link|link]]', wiki: wiki)

    expect(doc.to_html).to include "This is <a href=\"#{wiki.wiki_base_path}/link\""
  end

  context 'for sanitization of HTML entities' do
    it 'does not unescape HTML entities' do
      doc = pipeline_filter('This is [[a link|&lt;script&gt;alert(0)&lt;/script&gt;]]', wiki: wiki)

      expect(doc.at_css('a').text).to eq 'a link'
      expect(doc.at_css('a')['href']).to eq "#{wiki.wiki_base_path}/%3Cscript%3Ealert(0)%3C/script%3E"
      expect(doc.at_css('a')['data-canonical-src']).to eq '%3Cscript%3Ealert(0)%3C/script%3E'
    end

    it 'does not unescape HTML entities in the link text' do
      doc = pipeline_filter('This is [[&lt;script&gt;alert(0)&lt;/script&gt;|link]]', wiki: wiki)

      expect(doc.at_css('a')['href']).to eq "#{wiki.wiki_base_path}/link"
      expect(doc.at_css('a')['data-canonical-src']).to eq 'link'
      expect(doc.to_html).to end_with '>&lt;script&gt;alert(0)&lt;/script&gt;</a></p>'
    end

    it 'does not unescape HTML entities outside the link text' do
      doc = pipeline_filter('This is &lt;script&gt;alert(0)&lt;/script&gt; [[a link|link]]', wiki: wiki)

      # This is <script>alert(0)</script> <a href="/namespace1/project-1/-/wikis/link"
      # class="gfm gfm-gollum-wiki-page" data-canonical-src="link" data-link="true" data-gollum="true"
      # data-reference-type="wiki_page" data-project="8">a link</a>

      expect(doc.to_html).to start_with '<p dir="auto">This is &lt;script&gt;alert(0)&lt;/script&gt; <a href'
    end
  end

  it 'adds `gfm-gollum-wiki-page` classes to the link' do
    tag = '[[wiki-slug]]'
    doc = pipeline_filter("See #{tag}", wiki: wiki)

    expect(doc.at_css('a')['class']).to eq 'gfm gfm-gollum-wiki-page'
  end

  it 'sanitizes the href attribute (case 1)' do
    tag = '[[a|http:\'"injected=attribute&gt;&lt;img/src="0"onerror="alert(0)"&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1]]'
    doc = pipeline_filter("See #{tag}", wiki: wiki)

    expect(doc.at_css('a')['href']).to eq 'http:\'%22injected=attribute%3E%3Cimg/src=%220%22onerror=%22alert(0)%22%3Ehttps://gitlab.com/gitlab-org/gitlab/-/issues/1'
    expect(doc.at_css('a')['data-canonical-src'])
      .to eq 'http:\'%22injected=attribute%3E%3Cimg/src=%220%22onerror=%22alert(0)%22%3Ehttps://gitlab.com/gitlab-org/gitlab/-/issues/1'
  end

  # rubocop:disable Layout/LineLength -- test data in this format
  it 'sanitizes the href attribute (case 2)' do
    tag = '<i>[[a|\'"&gt;&lt;svg&gt;&lt;i/class=gl-show-field-errors&gt;&lt;input/title="&lt;script&gt;alert(0)&lt;/script&gt;"/&gt;&lt;/svg&gt;https://gitlab.com/gitlab-org/gitlab/-/issues/1]]'
    doc = pipeline_filter("See #{tag}", wiki: wiki)

    expect(doc.at_css('i a')['href']).to eq "#{wiki.wiki_base_path}/'%22%3E%3Csvg%3E%3Ci/class=gl-show-field-errors%3E%3Cinput/title=%22%3Cscript%3Ealert(0)%3C/script%3E%22/%3E%3C/svg%3Ehttps://gitlab.com/gitlab-org/gitlab/-/issues/1"
    expect(doc.at_css('i a')['data-canonical-src']).to eq "'%22%3E%3Csvg%3E%3Ci/class=gl-show-field-errors%3E%3Cinput/title=%22%3Cscript%3Ealert(0)%3C/script%3E%22/%3E%3C/svg%3Ehttps://gitlab.com/gitlab-org/gitlab/-/issues/1"
  end
  # rubocop:enable Layout/LineLength

  context 'when the href gets sanitized out' do
    it 'ignores the link' do
      doc = pipeline_filter('[[test|http://]]', wiki: wiki)

      expect(doc.at_css('a')['data-gollum']).to be_nil
    end
  end

  it_behaves_like 'pipeline timing check'

  describe 'limits the number of filtered image items' do
    before do
      stub_const('Banzai::Filter::WikiLinkGollumFilter::IMAGE_LINK_LIMIT', 2)
    end

    it 'enforces image limits' do
      blob = instance_double('Gitlab::Git::Blob', mime_type: 'image/jpeg',
        name: 'images/image.jpg', path: 'images/image.jpg', data: '')
      wiki_file = Gitlab::Git::WikiFile.new(blob)
      expect(wiki).to receive(:find_file).with('images/image.jpg', load_content: false).twice.and_return(wiki_file)

      text = '[[images/image.jpg]] [[images/image.jpg]] [[images/image.jpg]]'
      ends_with = '>images/image.jpg</a></p>'
      result = pipeline_filter(text, wiki: wiki)

      expect(result.to_html).to end_with ends_with
    end
  end

  it_behaves_like 'limits the number of filtered items' do
    let(:text) { '[[http://example.com]] [[http://example.com]] [[http://example.com]]' }
    let(:filter_result) { pipeline_filter(text, wiki: wiki) }
    let(:ends_with) do
      '<a href="http://example.com" data-wikilink="true" rel="nofollow noreferrer noopener" target="_blank">http://example.com</a></p>'
    end
  end

  def pipeline_filter(text, context = {})
    context = { project: project, no_sourcepos: true }.merge(context)

    doc = Banzai::Pipeline::PreProcessPipeline.call(text, {})
    doc = Banzai::Pipeline::FullPipeline.call(doc[:output], context)

    doc[:output]
  end
end
