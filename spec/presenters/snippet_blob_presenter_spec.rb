# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetBlobPresenter do
  describe '#rich_data' do
    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:current_user).and_return(nil)
      end
    end

    subject { described_class.new(snippet.blob).rich_data }

    context 'with PersonalSnippet' do
      let(:snippet) { create(:personal_snippet, :repository) }

      context 'when blob is binary' do
        it 'returns the HTML associated with the binary' do
          allow(snippet).to receive(:blob).and_return(snippet.repository.blob_at('master', 'files/images/logo-black.png'))

          expect(subject).to include('file-content image_file')
        end
      end

      context 'with markdown format' do
        let(:snippet) { create(:personal_snippet, file_name: 'test.md', content: '*foo*') }

        it 'returns rich markdown content' do
          expected = <<~HTML
            <div class="file-content md">
            <p data-sourcepos="1:1-1:5" dir="auto"><em>foo</em></p>
            </div>
          HTML

          expect(subject).to eq(expected)
        end
      end

      context 'with notebook format' do
        let(:snippet) { create(:personal_snippet, file_name: 'test.ipynb') }

        it 'returns rich notebook content' do
          expect(subject.strip).to eq %Q(<div class="file-content" data-endpoint="/-/snippets/#{snippet.id}/raw" id="js-notebook-viewer"></div>)
        end
      end

      context 'with openapi format' do
        let(:snippet) { create(:personal_snippet, file_name: 'openapi.yml') }

        it 'returns rich openapi content' do
          expect(subject).to eq %Q(<div class="file-content" data-endpoint="/-/snippets/#{snippet.id}/raw" id="js-openapi-viewer"></div>\n)
        end
      end

      context 'with svg format' do
        let(:snippet) { create(:personal_snippet, file_name: 'test.svg') }

        it 'returns rich svg content' do
          result = Nokogiri::HTML::DocumentFragment.parse(subject)
          image_tag = result.search('img').first

          expect(image_tag.attr('src')).to include("data:#{snippet.blob.mime_type};base64")
          expect(image_tag.attr('alt')).to eq('test.svg')
        end
      end

      context 'with other format' do
        let(:snippet) { create(:personal_snippet, file_name: 'test') }

        it 'does not return no rich content' do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe '#plain_data' do
    let(:snippet) { build(:personal_snippet) }

    subject { described_class.new(snippet.blob).plain_data }

    it 'returns nil when the snippet blob is binary' do
      allow(snippet.blob).to receive(:binary?).and_return(true)

      expect(subject).to be_nil
    end

    it 'returns plain content when snippet file is markup' do
      snippet.file_name = 'test.md'
      snippet.content = '*foo*'

      expect(subject).to eq '<span id="LC1" class="line" lang="markdown"><span class="ge">*foo*</span></span>'
    end

    it 'returns highlighted syntax content' do
      snippet.file_name = 'test.rb'
      snippet.content = 'class Foo;end'

      expect(subject)
        .to eq '<span id="LC1" class="line" lang="ruby"><span class="k">class</span> <span class="nc">Foo</span><span class="p">;</span><span class="k">end</span></span>'
    end

    it 'returns plain text highlighted content' do
      snippet.file_name = 'test'
      snippet.content = 'foo'

      expect(subject).to eq '<span id="LC1" class="line" lang="plaintext">foo</span>'
    end
  end

  describe 'route helpers' do
    let_it_be(:project)          { create(:project) }
    let_it_be(:user)             { create(:user) }
    let_it_be(:personal_snippet) { create(:personal_snippet, :repository, author: user) }
    let_it_be(:project_snippet)  { create(:project_snippet, :repository, project: project, author: user) }

    before do
      project.add_developer(user)
    end

    describe '#raw_path' do
      subject { described_class.new(snippet.blobs.first, current_user: user).raw_path }

      it_behaves_like 'snippet blob raw path'

      context 'with snippet_multiple_files feature disabled' do
        before do
          stub_feature_flags(snippet_multiple_files: false)
        end

        context 'with ProjectSnippet' do
          let(:snippet) { project_snippet }

          it 'returns the raw path' do
            expect(subject).to eq "/#{snippet.project.full_path}/-/snippets/#{snippet.id}/raw"
          end
        end

        context 'with PersonalSnippet' do
          let(:snippet) { personal_snippet }

          it 'returns the raw path' do
            expect(subject).to eq "/-/snippets/#{snippet.id}/raw"
          end
        end
      end
    end

    describe '#raw_url' do
      subject { described_class.new(snippet.blobs.first, current_user: user).raw_url }

      before do
        stub_default_url_options(host: 'test.host')
      end

      it_behaves_like 'snippet blob raw url'

      context 'with snippet_multiple_files feature disabled' do
        before do
          stub_feature_flags(snippet_multiple_files: false)
        end

        context 'with ProjectSnippet' do
          let(:snippet) { project_snippet }

          it 'returns the raw project snippet url' do
            expect(subject).to eq("http://test.host/#{project_snippet.project.full_path}/-/snippets/#{project_snippet.id}/raw")
          end
        end

        context 'with PersonalSnippet' do
          let(:snippet) { personal_snippet }

          it 'returns the raw personal snippet url' do
            expect(subject).to eq("http://test.host/-/snippets/#{personal_snippet.id}/raw")
          end
        end
      end
    end
  end
end
