# encoding: UTF-8

require 'spec_helper'

module Gitlab::Markdown
  describe RelativeLinkFilter do
    def filter(doc, contexts = {})
      contexts.reverse_merge!({
        commit:         project.commit,
        project:        project,
        project_wiki:   project_wiki,
        ref:            ref,
        requested_path: requested_path
      })

      described_class.call(doc, contexts)
    end

    def image(path)
      %(<img src="#{path}" />)
    end

    def link(path)
      %(<a href="#{path}">#{path}</a>)
    end

    let(:project)        { create(:project) }
    let(:project_path)   { project.path_with_namespace }
    let(:ref)            { 'markdown' }
    let(:project_wiki)   { nil }
    let(:requested_path) { '/' }

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

    shared_examples :relative_to_requested do
      it 'rebuilds URL relative to the requested path' do
        doc = filter(link('users.md'))
        expect(doc.at_css('a')['href']).
          to eq "/#{project_path}/blob/#{ref}/doc/api/users.md"
      end
    end

    context 'with a project_wiki' do
      let(:project_wiki) { double('ProjectWiki') }
      include_examples :preserve_unchanged
    end

    context 'without a repository' do
      let(:project) { create(:empty_project) }
      include_examples :preserve_unchanged
    end

    context 'with an empty repository' do
      let(:project) { create(:project_empty_repo) }
      include_examples :preserve_unchanged
    end

    it 'does not raise an exception on invalid URIs' do
      act = link("://foo")
      expect { filter(act) }.not_to raise_error
    end

    context 'with a valid repository' do
      it 'rebuilds relative URL for a file in the repo' do
        doc = filter(link('doc/api/README.md'))
        expect(doc.at_css('a')['href']).
          to eq "/#{project_path}/blob/#{ref}/doc/api/README.md"
      end

      it 'rebuilds relative URL for a file in the repo up one directory' do
        relative_link = link('../api/README.md')
        doc = filter(relative_link, requested_path: 'doc/update/7.14-to-8.0.md')

        expect(doc.at_css('a')['href']).
          to eq "/#{project_path}/blob/#{ref}/doc/api/README.md"
      end

      it 'rebuilds relative URL for a file in the repo up multiple directories' do
        relative_link = link('../../../api/README.md')
        doc = filter(relative_link, requested_path: 'doc/foo/bar/baz/README.md')

        expect(doc.at_css('a')['href']).
          to eq "/#{project_path}/blob/#{ref}/doc/api/README.md"
      end

      it 'rebuilds relative URL for a file in the repo with an anchor' do
        doc = filter(link('README.md#section'))
        expect(doc.at_css('a')['href']).
          to eq "/#{project_path}/blob/#{ref}/README.md#section"
      end

      it 'rebuilds relative URL for a directory in the repo' do
        doc = filter(link('doc/api/'))
        expect(doc.at_css('a')['href']).
          to eq "/#{project_path}/tree/#{ref}/doc/api"
      end

      it 'rebuilds relative URL for an image in the repo' do
        doc = filter(link('files/images/logo-black.png'))
        expect(doc.at_css('a')['href']).
          to eq "/#{project_path}/raw/#{ref}/files/images/logo-black.png"
      end

      it 'does not modify relative URL with an anchor only' do
        doc = filter(link('#section-1'))
        expect(doc.at_css('a')['href']).to eq '#section-1'
      end

      it 'does not modify absolute URL' do
        doc = filter(link('http://example.com'))
        expect(doc.at_css('a')['href']).to eq 'http://example.com'
      end

      it 'supports Unicode filenames' do
        path = 'files/images/한글.png'
        escaped = Addressable::URI.escape(path)

        # Stub these methods so the file doesn't actually need to be in the repo
        allow_any_instance_of(described_class).
          to receive(:file_exists?).and_return(true)
        allow_any_instance_of(described_class).
          to receive(:image?).with(path).and_return(true)

        doc = filter(image(escaped))
        expect(doc.at_css('img')['src']).to match '/raw/'
      end

      context 'when requested path is a file in the repo' do
        let(:requested_path) { 'doc/api/README.md' }
        include_examples :relative_to_requested
      end

      context 'when requested path is a directory in the repo' do
        let(:requested_path) { 'doc/api' }
        include_examples :relative_to_requested
      end
    end
  end
end
