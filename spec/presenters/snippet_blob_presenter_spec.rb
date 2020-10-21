# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetBlobPresenter do
  let_it_be(:snippet) { create(:personal_snippet, :repository) }

  let(:branch) { snippet.default_branch }
  let(:blob) { snippet.blobs.first }

  describe '#rich_data' do
    let(:data_endpoint_url) { "/-/snippets/#{snippet.id}/raw/#{branch}/#{file}" }

    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:current_user).and_return(nil)
      end

      blob.name = File.basename(file)
      blob.path = file
    end

    subject { described_class.new(blob).rich_data }

    context 'with PersonalSnippet' do
      context 'when blob is binary' do
        let(:file) { 'files/images/logo-black.png' }
        let(:blob) { blob_at(file) }

        it 'returns the HTML associated with the binary' do
          expect(subject).to include('file-content image_file')
        end
      end

      context 'with markdown format' do
        let(:file) { 'README.md' }
        let(:blob) { blob_at(file) }

        it 'returns rich markdown content' do
          expect(subject).to include('file-content md')
        end
      end

      context 'with notebook format' do
        let(:file) { 'test.ipynb' }

        it 'returns rich notebook content' do
          expect(subject.strip).to eq %Q(<div class="file-content" data-endpoint="#{data_endpoint_url}" id="js-notebook-viewer"></div>)
        end
      end

      context 'with openapi format' do
        let(:file) { 'openapi.yml' }

        it 'returns rich openapi content' do
          expect(subject).to eq %Q(<div class="file-content" data-endpoint="#{data_endpoint_url}" id="js-openapi-viewer"></div>\n)
        end
      end

      context 'with svg format' do
        let(:file) { 'files/images/wm.svg' }
        let(:blob) { blob_at(file) }

        it 'returns rich svg content' do
          result = Nokogiri::HTML::DocumentFragment.parse(subject)
          image_tag = result.search('img').first

          expect(image_tag.attr('src')).to include("data:#{blob.mime_type};base64")
          expect(image_tag.attr('alt')).to eq(File.basename(file))
        end
      end

      context 'with other format' do
        let(:file) { 'test' }

        it 'does not return no rich content' do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe '#plain_data' do
    let(:blob) { blob_at(file) }

    subject { described_class.new(blob).plain_data }

    context 'when blob is binary' do
      let(:file) { 'files/images/logo-black.png' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when blob is markup' do
      let(:file) { 'README.md' }

      it 'returns plain content' do
        expect(subject).to include('<span id="LC1" class="line" lang="markdown">')
      end
    end

    context 'when blob has syntax' do
      let(:file) { 'files/ruby/regex.rb' }

      it 'returns highlighted syntax content' do
        expect(subject)
          .to include '<span id="LC1" class="line" lang="ruby"><span class="k">module</span> <span class="nn">Gitlab</span>'
      end
    end

    context 'when blob has plain data' do
      let(:file) { 'LICENSE' }

      it 'returns plain text highlighted content' do
        expect(subject).to include('<span id="LC1" class="line" lang="plaintext">The MIT License (MIT)</span>')
      end
    end
  end

  describe 'route helpers' do
    let_it_be(:project)          { create(:project) }
    let_it_be(:user)             { create(:user) }
    let_it_be(:personal_snippet) { create(:personal_snippet, :repository, author: user) }
    let_it_be(:project_snippet)  { create(:project_snippet, :repository, project: project, author: user) }

    let(:blob) { snippet.blobs.first }

    before do
      project.add_developer(user)
    end

    describe '#raw_path' do
      subject { described_class.new(blob, current_user: user).raw_path }

      it_behaves_like 'snippet blob raw path'

      context 'with a snippet without a repository' do
        let(:personal_snippet) { build(:personal_snippet, author: user, id: 1) }
        let(:project_snippet)  { build(:project_snippet, project: project, author: user, id: 1) }
        let(:blob) { snippet.blob }

        context 'with ProjectSnippet' do
          let(:snippet) { project_snippet }

          it 'returns the raw project snippet path' do
            expect(subject).to eq("/#{project_snippet.project.full_path}/-/snippets/#{project_snippet.id}/raw")
          end
        end

        context 'with PersonalSnippet' do
          let(:snippet) { personal_snippet }

          it 'returns the raw personal snippet path' do
            expect(subject).to eq("/-/snippets/#{personal_snippet.id}/raw")
          end
        end
      end
    end

    describe '#raw_url' do
      subject { described_class.new(blob, current_user: user).raw_url }

      before do
        stub_default_url_options(host: 'test.host')
      end

      it_behaves_like 'snippet blob raw url'

      context 'with a snippet without a repository' do
        let(:personal_snippet) { build(:personal_snippet, author: user, id: 1) }
        let(:project_snippet)  { build(:project_snippet, project: project, author: user, id: 1) }
        let(:blob) { snippet.blob }

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

  def blob_at(path)
    snippet.repository.blob_at(branch, path)
  end
end
