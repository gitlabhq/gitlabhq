# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubGistsImport::Importer::GistImporter, feature_category: :importers do
  subject { described_class.new(gist_object, user.id).execute }

  let_it_be(:user) { create(:user) }
  let(:created_at) { Time.utc(2022, 1, 9, 12, 15) }
  let(:updated_at) { Time.utc(2022, 5, 9, 12, 17) }
  let(:gist_file) { { file_name: '_Summary.md', file_content: 'File content' } }
  let(:url) { 'https://host.com/gistid.git' }
  let(:gist_object) do
    instance_double('Gitlab::GithubGistsImport::Representation::Gist',
      truncated_title: 'My Gist',
      visibility_level: 0,
      files: { '_Summary.md': gist_file },
      first_file: gist_file,
      git_pull_url: url,
      created_at: created_at,
      updated_at: updated_at
    )
  end

  let(:expected_snippet_attrs) do
    {
      title: 'My Gist',
      visibility_level: 0,
      content: 'File content',
      file_name: '_Summary.md',
      author_id: user.id,
      created_at: gist_object.created_at,
      updated_at: gist_object.updated_at
    }.stringify_keys
  end

  describe '#execute' do
    context 'when success' do
      it 'creates expected snippet and snippet repository' do
        expect_next_instance_of(Repository) do |repository|
          expect(repository).to receive(:fetch_as_mirror)
        end

        expect { subject }.to change { user.snippets.count }.by(1)
        expect(user.snippets[0].attributes).to include expected_snippet_attrs
      end
    end

    context 'when file size limit exeeded' do
      before do
        files = [].tap { |array| 11.times { |n| array << ["file#{n}.txt", {}] } }.to_h

        allow(gist_object).to receive(:files).and_return(files)
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:fetch_as_mirror)
          allow(repository).to receive(:empty?).and_return(false)
          allow(repository).to receive(:ls_files).and_return(files.keys)
        end
      end

      it 'returns error' do
        result = subject

        expect(user.snippets.count).to eq(0)
        expect(result.error?).to eq(true)
        expect(result.errors).to match_array(['Snippet maximum file count exceeded'])
      end
    end

    context 'when invalid attributes' do
      let(:gist_file) { { file_name: '_Summary.md', file_content: nil } }

      it 'raises an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Content can't be blank")
      end
    end

    context 'when repository cloning fails' do
      it 'returns error' do
        expect_next_instance_of(Repository) do |repository|
          expect(repository).to receive(:fetch_as_mirror).and_raise(Gitlab::Shell::Error)
          expect(repository).to receive(:remove)
        end

        expect { subject }.to raise_error(Gitlab::Shell::Error)
        expect(user.snippets.count).to eq(0)
      end
    end

    context 'when url is invalid' do
      let(:url) { 'invalid' }

      context 'when local network is allowed' do
        before do
          allow(::Gitlab::CurrentSettings)
            .to receive(:allow_local_requests_from_web_hooks_and_services?).and_return(true)
        end

        it 'raises error' do
          expect(Gitlab::UrlBlocker)
            .to receive(:validate!)
            .with(url, ports: [80, 443], schemes: %w[http https git],
                       allow_localhost: true, allow_local_network: true)
            .and_raise(Gitlab::UrlBlocker::BlockedUrlError)

          expect { subject }.to raise_error(Gitlab::UrlBlocker::BlockedUrlError)
        end
      end

      context 'when local network is not allowed' do
        before do
          allow(::Gitlab::CurrentSettings)
            .to receive(:allow_local_requests_from_web_hooks_and_services?).and_return(false)
        end

        it 'raises error' do
          expect(Gitlab::UrlBlocker)
            .to receive(:validate!)
            .with(url, ports: [80, 443], schemes: %w[http https git],
                       allow_localhost: false, allow_local_network: false)
            .and_raise(Gitlab::UrlBlocker::BlockedUrlError)

          expect { subject }.to raise_error(Gitlab::UrlBlocker::BlockedUrlError)
        end
      end
    end
  end
end
