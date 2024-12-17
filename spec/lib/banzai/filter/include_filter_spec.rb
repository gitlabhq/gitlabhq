# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::IncludeFilter, feature_category: :markdown do
  include FilterSpecHelper
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:ref) { project.repository.root_ref }
  let_it_be(:text_include) { '::include{file=file.md}' }
  let_it_be(:file_data) { 'included text' }
  let_it_be(:wiki_data) { "---\ntitle: Foo\n---\nincluded text" }
  let_it_be(:max_includes) { 10 }

  let_it_be(:filter_context) do
    {
      project: project,
      max_includes: max_includes,
      ref: ref,
      requested_path: './',
      text_source: :blob
    }
  end

  let_it_be(:filter_wiki_context) do
    {
      project: project,
      max_includes: max_includes,
      ref: ref,
      requested_path: './',
      text_source: :blob,
      wiki: project.wiki
    }
  end

  let(:file_blob) { instance_double(::Blob, readable_text?: true, data: file_data) }

  before do
    allow(project.repository).to receive(:blob_at).with(ref, anything).and_return(nil)
    allow(project.repository).to receive(:blob_at).with(ref, 'file.md').and_return(file_blob)
    allow(Gitlab::Git::Blob).to receive(:find).with(project.repository, ref, 'file.md').and_return(file_blob)
  end

  it 'works for wikis' do
    expect(filter(text_include, filter_wiki_context)).to eq file_data
  end

  it 'works for blobs' do
    expect(filter(text_include, filter_context)).to eq file_data
  end

  it 'does not work for non-wiki/blob' do
    expect(filter(text_include)).to eq text_include
  end

  describe 'include syntax' do
    context 'when incorrect syntax' do
      where(:markdown) do
        [
          ' ::include{file=file.md}',
          '::include{file=file.md} ',
          ':include{file=file.md}',
          '::include{file.md}',
          '::include(file=file.md)'
        ]
      end

      with_them do
        it 'does not change the text' do
          expect(filter(markdown, filter_context)).to eq markdown
        end
      end
    end

    context 'when correct syntax' do
      it 'recognizes file syntax' do
        expect(filter('::include{file=file.md}', filter_context)).to eq file_data
      end

      it 'recognizes file syntax with space' do
        allow(project.repository).to receive(:blob_at).with(ref, 'file two.md').and_return(file_blob)
        allow(Gitlab::Git::Blob).to receive(:find).with(project.repository, ref, 'file two.md').and_return(file_blob)

        expect(filter('::include{file=file two.md}', filter_context)).to eq file_data
      end

      it 'recognizes url syntax' do
        expect(filter('::include{file=https://example.com}', filter_context))
          .to eq '[https://example.com](https://example.com)'
      end
    end

    it 'handles case where the include filename is nil' do
      allow(Gitlab::Utils::Gsub).to receive(:gsub_with_limit)
        .with(anything, anything, limit: anything).and_yield(0 => 'foo')

      expect(filter('::include{file=file.md}', filter_context)).to eq 'foo'
    end
  end

  context 'when reading a file in the repository' do
    it 'returns the blob contents' do
      expect(filter(text_include, filter_context)).to eq file_data
    end

    context 'when the blob does not exist' do
      before do
        allow(Gitlab::Git::Blob).to receive(:find).with(project.repository, ref, 'missing.md').and_return(nil)
      end

      it 'replaces text with error' do
        expect(filter('::include{file=missing.md}', filter_context))
          .to eq "**Error including '[missing.md](missing.md)' : not found**\n"
      end
    end

    it 'allows at most N blob includes' do
      text = "#{text_include}\n" * (max_includes + 1)
      result = filter(text, filter_context)

      expect(result).to start_with("#{file_data}\n" * max_includes)
      expect(result.chomp).to end_with(text_include)
    end

    context 'when reading a wiki blob' do
      let(:wiki_blob) { instance_double(::Blob, readable_text?: true, data: wiki_data) }

      before do
        allow(project.repository).to receive(:blob_at).with(ref, 'wiki.md').and_return(wiki_blob)
        allow(Gitlab::Git::Blob).to receive(:find).with(project.repository, ref, 'wiki.md').and_return(wiki_blob)
      end

      it 'strips any frontmatter' do
        expect(filter('::include{file=wiki.md}', filter_wiki_context)).to eq file_data
      end
    end
  end

  context 'when reading content from a URL' do
    let_it_be(:http_url) { 'http://example.com' }
    let_it_be(:http_include) { '::include{file=http://example.com}' }
    let_it_be(:https_include) { '::include{file=https://example.com}' }
    let_it_be(:invalid_url) { '::include{file=http://example.com/foo bar}' }

    context 'when wiki_asciidoc_allow_uri_includes is false' do
      before do
        stub_application_setting(wiki_asciidoc_allow_uri_includes: false)
      end

      it 'does not allow url includes' do
        expect(filter(http_include, filter_context)).to eq '[http://example.com](http://example.com)'
        expect(filter(https_include, filter_context)).to eq '[https://example.com](https://example.com)'
      end

      it 'allows non-url includes' do
        expect(filter(text_include, filter_context)).to include 'included text'
      end
    end

    context 'when wiki_asciidoc_allow_uri_includes is true' do
      before do
        stub_application_setting(wiki_asciidoc_allow_uri_includes: true)
      end

      it 'fetches the data using a GET request' do
        stub_request(:get, http_url).to_return(status: 200, body: 'something')

        expect(filter(http_include, filter_context)).to eq 'something'
      end

      context 'when the URI returns 404' do
        it 'raises NoData' do
          stub_request(:get, http_url).to_return(status: 404, body: 'not found')

          expect(filter(http_include, filter_context))
            .to eq "**Error including '[http://example.com](http://example.com)' : not readable**\n"
        end
      end

      context 'when URI::InvalidURIError' do
        it 'rescues the error' do
          allow(Gitlab::Git::Blob).to receive(:find).with(project.repository, ref, anything).and_return(nil)

          expect(filter(invalid_url, filter_context))
            .to eq "**Error including '[http://example.com/foo bar](http://example.com/foo bar)' : not found**\n"
        end
      end

      it 'allows at most N HTTP includes' do
        stub_request(:get, http_url).to_return(status: 200, body: 'something')

        text = "#{http_include}\n" * (max_includes + 1)
        result = filter(text, filter_context)

        expect(result).to start_with("something\n" * max_includes)
        expect(result.chomp).to end_with(http_include)
      end
    end
  end

  context 'when including' do
    it 'truncates to our size limits' do
      text = "#{text_include}\n" * max_includes
      result = filter(text, filter_context.merge(limit: 10))

      expect(result).to eq('include...')
    end
  end
end
