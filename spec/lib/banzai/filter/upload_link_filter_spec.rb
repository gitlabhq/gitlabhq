# encoding: UTF-8

require 'spec_helper'

describe Banzai::Filter::UploadLinkFilter, lib: true do
  def filter(doc, contexts = {})
    contexts.reverse_merge!({
      project: project
    })

    described_class.call(doc, contexts)
  end

  def image(path)
    %(<img src="#{path}" />)
  end

  def link(path)
    %(<a href="#{path}">#{path}</a>)
  end

  let(:project) { create(:project) }

  shared_examples :preserve_unchanged do
    it 'does not modify any relative URL in anchor' do
      doc = filter(link('README.md'))
      expect(doc.at_css('a')['href']).to eq 'README.md'
    end

    it 'does not modify any relative URL in image' do
      doc = filter(image('files/images/logo-black.png'))
      expect(doc.at_css('img')['src']).to eq 'files/images/logo-black.png'
    end
  end

  it 'does not raise an exception on invalid URIs' do
    act = link("://foo")
    expect { filter(act) }.not_to raise_error
  end

  context 'with a valid repository' do
    it 'rebuilds relative URL for a link' do
      doc = filter(link('/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg'))
      expect(doc.at_css('a')['href']).
        to eq "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg"
    end

    it 'rebuilds relative URL for an image' do
      doc = filter(link('/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg'))
      expect(doc.at_css('a')['href']).
        to eq "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/uploads/e90decf88d8f96fe9e1389afc2e4a91f/test.jpg"
    end

    it 'does not modify absolute URL' do
      doc = filter(link('http://example.com'))
      expect(doc.at_css('a')['href']).to eq 'http://example.com'
    end

    it 'supports Unicode filenames' do
      path = '/uploads/한글.png'
      escaped = Addressable::URI.escape(path)

      # Stub these methods so the file doesn't actually need to be in the repo
      allow_any_instance_of(described_class).
        to receive(:file_exists?).and_return(true)
      allow_any_instance_of(described_class).
        to receive(:image?).with(path).and_return(true)

      doc = filter(image(escaped))
      expect(doc.at_css('img')['src']).to match "#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}/uploads/%ED%95%9C%EA%B8%80.png"
    end
  end
end
