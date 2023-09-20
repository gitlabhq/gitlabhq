# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetBlobPresenter do
  let_it_be(:snippet) { create(:personal_snippet, :repository) }

  let(:branch) { snippet.default_branch }
  let(:blob) { snippet.blobs.first }

  describe '#rich_data' do
    let(:data_endpoint_url) { "/-/snippets/#{snippet.id}/raw/#{branch}/#{file}" }
    let(:data_raw_dir) { "/-/snippets/#{snippet.id}/raw/#{branch}/" }

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
          expect(subject).to include('file-content js-markup-content md')
        end
      end

      context 'with notebook format' do
        let(:file) { 'test.ipynb' }

        it 'returns rich notebook content' do
          expect(subject.strip).to eq %(<div class="file-content" data-endpoint="#{data_endpoint_url}" data-relative-raw-path="#{data_raw_dir}" id="js-notebook-viewer"></div>)
        end
      end

      context 'with openapi format' do
        let(:file) { 'openapi.yml' }

        it 'returns rich openapi content' do
          expect(subject).to eq %(<div class="file-content" data-endpoint="#{data_endpoint_url}" id="js-openapi-viewer"></div>\n)
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

    describe '#raw_plain_data' do
      context "with a plain file" do
        subject { described_class.new(blob, current_user: user) }

        it 'shows raw data for non binary files' do
          expect(subject.raw_plain_data).to eq(blob.data)
        end
      end

      context "with a binary file" do
        let(:file) { 'files/images/logo-black.png' }
        let(:blob) { blob_at(file) }

        subject { described_class.new(blob, current_user: user) }

        it 'returns nil' do
          expect(subject.raw_plain_data).to be_nil
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
