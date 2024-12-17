# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubGistsImport::Importer::GistImporter, feature_category: :importers do
  subject { described_class.new(gist_object, user.id) }

  let_it_be(:organization) { create(:organization) }
  let_it_be_with_reload(:user) { create(:user, organizations: [organization]) }
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
      updated_at: updated_at,
      total_files_size: Gitlab::CurrentSettings.snippet_size_limit
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
      let(:validator_result) do
        instance_double(ServiceResponse, error?: false)
      end

      it 'creates expected snippet and snippet repository' do
        expect_next_instance_of(Snippets::RepositoryValidationService) do |validator|
          expect(validator).to receive(:execute).and_return(validator_result)
        end

        expect_next_instance_of(Repository) do |repository|
          expect(repository).to receive(:fetch_as_mirror)
        end

        expect { subject.execute }.to change { user.snippets.count }.by(1)
        expect(user.snippets[0].attributes).to include expected_snippet_attrs
        expect(user.snippets[0].organization_id).to eq(user.organizations.first.id)
      end
    end

    describe 'pre-import validations' do
      context 'when file count limit exeeded' do
        before do
          files = [].tap { |array| 11.times { |n| array << ["file#{n}.txt", {}] } }.to_h

          allow(gist_object).to receive(:files).and_return(files)
        end

        it 'validates input and returns error' do
          expect(PersonalSnippet).not_to receive(:new)

          result = subject.execute

          expect(user.snippets.count).to eq(0)
          expect(result.error?).to eq(true)
          expect(result.errors).to match_array(['Snippet maximum file count exceeded'])
        end
      end

      context 'when repo too big' do
        before do
          files = [{ "file1.txt" => {} }, { "file2.txt" => {} }]

          allow(gist_object).to receive(:files).and_return(files)
          allow(gist_object).to receive(:total_files_size).and_return(Gitlab::CurrentSettings.snippet_size_limit + 1)
        end

        it 'validates input and returns error' do
          expect(PersonalSnippet).not_to receive(:new)

          result = subject.execute

          expect(result.error?).to eq(true)
          expect(result.errors).to match_array(['Snippet repository size exceeded'])
        end
      end
    end

    describe 'post-import validations' do
      let(:files) { { "file1.txt" => {}, "file2.txt" => {} } }

      before do
        allow(gist_object).to receive(:files).and_return(files)
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:fetch_as_mirror)
        end
        allow_next_instance_of(Snippets::RepositoryValidationService) do |validator|
          allow(validator).to receive(:execute).and_return(validator_result)
        end
      end

      context 'when file count limit exeeded' do
        let(:validator_result) do
          instance_double(ServiceResponse, error?: true, message: 'Error: Repository files count over the limit')
        end

        it 'returns error' do
          expect(subject).to receive(:remove_snippet_and_repository).and_call_original

          result = subject.execute

          expect(result).to be_error
          expect(result.errors).to match_array(['Error: Repository files count over the limit'])
        end
      end

      context 'when repo too big' do
        let(:validator_result) do
          instance_double(ServiceResponse, error?: true, message: 'Error: Repository size is above the limit.')
        end

        it 'returns error' do
          expect(subject).to receive(:remove_snippet_and_repository).and_call_original

          result = subject.execute

          expect(result).to be_error
          expect(result.errors).to match_array(['Error: Repository size is above the limit.'])
        end
      end
    end

    context 'when invalid attributes' do
      let(:gist_file) { { file_name: '_Summary.md', file_content: nil } }

      it 'raises an error' do
        expect { subject.execute }
          .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Content can't be blank")
      end
    end

    context 'when repository cloning fails' do
      it 'returns error' do
        expect_next_instance_of(Repository) do |repository|
          expect(repository).to receive(:fetch_as_mirror).and_raise(Gitlab::Shell::Error)
          expect(repository).to receive(:remove)
        end

        expect(subject).to receive(:remove_snippet_and_repository).and_call_original

        expect { subject.execute }.to raise_error(Gitlab::Shell::Error)
        expect(user.snippets.count).to eq(0)
      end
    end

    context 'when url is invalid' do
      let(:url) { 'invalid' }

      context 'when local network is allowed' do
        before do
          allow(::Gitlab::CurrentSettings)
            .to receive(:allow_local_requests_from_web_hooks_and_services?).and_return(true)
          allow(::Gitlab::CurrentSettings)
            .to receive(:deny_all_requests_except_allowed?).and_return(true)
          allow(::Gitlab::CurrentSettings)
            .to receive(:outbound_local_requests_allowlist?).and_return([])
        end

        it 'raises error' do
          expect(Gitlab::HTTP_V2::UrlBlocker)
            .to receive(:validate!)
            .with(url, ports: [80, 443], schemes: %w[http https git],
              allow_localhost: true, allow_local_network: true,
              deny_all_requests_except_allowed: true,
              outbound_local_requests_allowlist: [])
            .and_raise(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)

          expect { subject.execute }.to raise_error(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)
        end
      end

      context 'when local network is not allowed' do
        before do
          allow(::Gitlab::CurrentSettings)
            .to receive(:allow_local_requests_from_web_hooks_and_services?).and_return(false)
          allow(::Gitlab::CurrentSettings)
            .to receive(:deny_all_requests_except_allowed?).and_return(true)
          allow(::Gitlab::CurrentSettings)
            .to receive(:outbound_local_requests_allowlist?).and_return([])
        end

        it 'raises error' do
          expect(Gitlab::HTTP_V2::UrlBlocker)
            .to receive(:validate!)
            .with(url, ports: [80, 443], schemes: %w[http https git],
              allow_localhost: false, allow_local_network: false,
              deny_all_requests_except_allowed: true,
              outbound_local_requests_allowlist: [])
            .and_raise(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)

          expect { subject.execute }.to raise_error(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)
        end
      end
    end
  end
end
