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

  let_it_be(:context) do
    {
      project: project,
      max_includes: max_includes,
      ref: ref,
      requested_path: './',
      text_source: :blob
    }
  end

  let_it_be(:wiki_context) do
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
    expect(filter(text_include, wiki_context)).to eq file_data
  end

  it 'works for blobs' do
    expect(filter(text_include, context)).to eq file_data
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
          expect(filter(markdown, context)).to eq markdown
        end
      end
    end

    context 'when correct syntax' do
      it 'recognizes file syntax' do
        expect(filter('::include{file=file.md}', context)).to eq file_data
      end

      it 'recognizes file syntax with space' do
        allow(project.repository).to receive(:blob_at).with(ref, 'file two.md').and_return(file_blob)
        allow(Gitlab::Git::Blob).to receive(:find).with(project.repository, ref, 'file two.md').and_return(file_blob)

        expect(filter('::include{file=file two.md}', context)).to eq file_data
      end

      it 'recognizes url syntax' do
        expect(filter('::include{file=https://example.com}', context))
          .to eq '[https://example\\.com](<https://example.com>)'
      end
    end
  end

  context 'when reading a file in the repository' do
    it 'returns the blob contents' do
      expect(filter(text_include, context)).to eq file_data
    end

    context 'when the blob does not exist' do
      before do
        allow(Gitlab::Git::Blob).to receive(:find).with(project.repository, ref, 'missing.md').and_return(nil)
      end

      it 'replaces text with error' do
        expect(filter("::include{file=missing.md}\n", context))
          .to eq "**Error including '[missing\\.md](<missing.md>)': not found**\n"
      end
    end

    it 'allows at most N blob includes' do
      text = "#{text_include}\n" * (max_includes + 1)
      result = filter(text, context)

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
        expect(filter('::include{file=wiki.md}', wiki_context)).to eq file_data
      end
    end
  end

  context 'when reading content from a URL' do
    let_it_be(:http_url) { 'http://example.com' }
    let_it_be(:http_include) { '::include{file=http://example.com}' }
    let_it_be(:https_include) { '::include{file=https://example.com}' }
    let_it_be(:space_include) { '::include{file=http://example.com/foo bar}' }
    let_it_be(:bad_include) { '::include{file=https://example.com/esc)aped}' }

    context 'when wiki_asciidoc_allow_uri_includes is false' do
      before do
        stub_application_setting(wiki_asciidoc_allow_uri_includes: false)
      end

      it 'does not allow url includes' do
        expect(filter(http_include, context)).to eq '[http://example\.com](<http://example.com>)'
        expect(filter(https_include, context)).to eq '[https://example\.com](<https://example.com>)'
      end

      it 'does not allow urls that break the link syntax' do
        expect(filter(bad_include, context)).to eq '[https://example\.com/esc\)aped](<https://example.com/esc)aped>)'
      end

      it 'allows non-url includes' do
        expect(filter(text_include, context)).to include 'included text'
      end
    end

    context 'when wiki_asciidoc_allow_uri_includes is true' do
      before do
        stub_application_setting(wiki_asciidoc_allow_uri_includes: true)
      end

      it 'fetches the data using a GET request' do
        stub_request(:get, http_url).to_return(status: 200, body: 'something')

        expect(filter(http_include, context)).to eq 'something'
      end

      context 'when the URI returns 404' do
        it 'raises NoData' do
          stub_request(:get, http_url).to_return(status: 404, body: 'not found')

          expect(filter(http_include, context))
            .to eq "**Error including '[http://example\\.com](<http://example.com>)': not readable**"
        end
      end

      context 'when URI::InvalidURIError' do
        it 'rescues the error' do
          allow(Gitlab::Git::Blob).to receive(:find).with(project.repository, ref, anything).and_return(nil)

          expect(filter(space_include, context))
            .to eq "**Error including '[http://example\\.com/foo bar](<http://example.com/foo bar>)': not found**"
        end
      end

      it 'allows at most N HTTP includes' do
        stub_request(:get, http_url).to_return(status: 200, body: 'something')

        text = "#{http_include}\n" * (max_includes + 1)
        result = filter(text, context)

        expect(result).to start_with("something\n" * max_includes)
        expect(result.chomp).to end_with(http_include)
      end
    end
  end

  context 'when including' do
    it 'truncates to our size limits' do
      text = "#{text_include}\n" * max_includes
      result = filter(text, context.merge(limit: 10))

      expect(result).to eq('include...')
    end
  end
end
