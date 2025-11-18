# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::PlainMarkdownPipeline, feature_category: :markdown do
  include FakeBlobHelpers
  include RepoHelpers
  using RSpec::Parameterized::TableSyntax

  context 'with project' do
    let_it_be(:project)        { create(:project, :repository) }
    let_it_be(:ref)            { 'markdown' }
    let_it_be(:requested_path) { '/' }
    let_it_be(:commit)         { project.commit(ref) }

    let(:context) do
      {
        commit: commit,
        project: project,
        ref: ref,
        text_source: :blob,
        requested_path: requested_path,
        no_sourcepos: true
      }
    end

    context 'when include directive' do
      subject(:output) { described_class.call(input, context)[:output].to_html }

      let(:input) { "Include this:\n\n::include{file=#{include_path}}" }

      context 'with path to non-existing file' do
        let(:include_path) { 'not-exists.md' }

        it 'renders Unresolved directive placeholder' do
          is_expected.to include error_message(include_path, 'not found')
        end
      end

      shared_examples 'invalid include' do
        let(:include_path) { 'dk.png' }

        before do
          allow(project.repository).to receive(:blob_at).and_return(blob)
        end

        it 'does not read the blob' do
          expect(blob).not_to receive(:data)
        end

        it 'renders Unresolved directive placeholder' do
          is_expected.to include error_message(include_path, 'not found')
        end
      end

      context 'with path to a binary file' do
        let(:blob) { fake_blob(path: 'dk.png', binary: true) }

        include_examples 'invalid include'
      end

      context 'with path to file in external storage' do
        let(:blob) { fake_blob(path: 'dk.png', lfs: true) }

        before do
          allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
          project.update_attribute(:lfs_enabled, true)
        end

        include_examples 'invalid include'
      end

      context 'with a URI that returns 404' do
        let(:include_path) { 'https://example.com/some_file.md' }

        before do
          stub_request(:get, include_path).to_return(status: 404, body: 'not found')
          stub_application_setting(wiki_asciidoc_allow_uri_includes: true)
        end

        it 'renders not readable directive placeholder' do
          is_expected.to include error_message(include_path, 'not readable')
        end
      end

      context 'with path to a textual file' do
        let(:include_path) { 'sample.md' }

        shared_examples 'valid include' do
          [
            ['/doc/sample.md',  'doc/sample.md',     'absolute path'],
            ['sample.md',       'doc/api/sample.md', 'relative path'],
            ['./sample.md',     'doc/api/sample.md', 'relative path with leading ./'],
            ['../sample.md',    'doc/sample.md',     'relative path to a file up one directory'],
            ['../../sample.md', 'sample.md',         'relative path for a file up multiple directories']
          ].each do |include_path_, file_path_, desc|
            context "when the file is specified by #{desc}" do
              let(:include_path) { include_path_ }
              let(:file_path) { file_path_ }

              around do |example|
                create_and_delete_files(project, { file_path => "Content from #{include_path}" }, branch_name: 'markdown') do
                  example.run
                end
              end

              it 'includes content of the file' do
                is_expected.to include('<p>Include this:</p>')
                is_expected.to include("<p>Content from #{include_path}</p>")
              end
            end
          end
        end

        context 'when requested path is a file in the repo' do
          let(:requested_path) { 'doc/api/test.md' }

          include_examples 'valid include'

          context 'without a commit (only ref)' do
            let(:commit) { nil }

            include_examples 'valid include'
          end
        end

        context 'when requested path is a directory in the repo' do
          let(:requested_path) { 'doc/api/' }

          include_examples 'valid include'

          context 'without a commit (only ref)' do
            let(:commit) { nil }

            include_examples 'valid include'
          end
        end
      end

      context 'when repository is passed into the context' do
        let(:wiki_repo) { project.wiki.repository }
        let(:include_path) { 'wiki_file.md' }

        before do
          project.create_wiki
          context.merge!(repository: wiki_repo)
        end

        context 'when the file exists' do
          before do
            create_file(include_path, 'Content from wiki', repository: wiki_repo)
          end

          after do
            delete_file(include_path, repository: wiki_repo)
          end

          it { is_expected.to include('<p>Content from wiki</p>') }
        end

        context 'when the file does not exist' do
          it { is_expected.to include error_message(include_path, 'not found') }
        end
      end

      describe 'the effect of max-includes' do
        let(:input) do
          <<~MD
            Source: requested file

            ::include{file=doc/preface.md}
            ::include{file=https://example.com/some_file.md}
            ::include{file=doc/chapter-1.md}
            ::include{file=https://example.com/other_file.md}
            ::include{file=license.md}
          MD
        end

        let(:project_files) do
          {
            'doc/preface.md' => 'source: preface',
            'doc/chapter-1.md' => 'source: chapter-1',
            'license.md' => 'source: license'
          }
        end

        around do |example|
          create_and_delete_files(project, project_files, branch_name: 'markdown') do
            example.run
          end
        end

        before do
          stub_request(:get, 'https://example.com/some_file.md')
            .to_return(status: 200, body: 'source: interwebs')
          stub_request(:get, 'https://example.com/other_file.md')
            .to_return(status: 200, body: 'source: intertubes')
          stub_application_setting(wiki_asciidoc_allow_uri_includes: true)
        end

        it 'includes the content of all sources' do
          expect(output.gsub(/<[^>]+>/, '').gsub(/\n\s*/, "\n").strip).to eq <<~MD.strip
            Source: requested file
            source: preface
            source: interwebs
            source: chapter-1
            source: intertubes
            source: license
          MD
        end

        context 'when the document includes more than asciidoc_max_includes' do
          it 'includes only the content of the first 2 sources' do
            stub_application_setting(asciidoc_max_includes: 2)

            expect(output.gsub(/<[^>]+>/, '').gsub(/\n\s*/, "\n").strip).to eq <<~MD.strip
              Source: requested file
              source: preface
              source: interwebs
              ::include{file=doc/chapter-1.md}
              ::include{file=https://example.com/other_file.md}
              ::include{file=license.md}
            MD
          end
        end
      end

      def create_file(path, content, repository: project.repository)
        repository.create_file(project.creator, path, content,
          message: "Add #{path}", branch_name: 'markdown')
      end

      def delete_file(path, repository: project.repository)
        repository.delete_file(project.creator, path, message: "Delete #{path}", branch_name: 'markdown')
      end

      def error_message(filename, reason)
        %(Error including '<a href="#{filename}">#{filename}</a>': #{reason})
      end
    end
  end

  def correct_html_included(markdown, expected, context = {})
    result = described_class.call(markdown, context)

    expect(result[:output].to_html).to include(expected)

    result
  end
end
