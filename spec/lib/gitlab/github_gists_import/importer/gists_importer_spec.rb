# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubGistsImport::Importer::GistsImporter, feature_category: :importers do
  subject(:result) { described_class.new(user, token).execute }

  let_it_be(:user) { create(:user) }
  let(:client) { instance_double('Gitlab::GithubImport::Client', rate_limit_resets_in: 5) }
  let(:token) { 'token' }
  let(:page_counter) { instance_double('Gitlab::Import::PageCounter', current: 1, set: true, expire!: true) }
  let(:page) { instance_double('Gitlab::GithubImport::Client::Page', objects: [gist], number: 1) }
  let(:url) { 'https://gist.github.com/foo/bar.git' }
  let(:waiter) { Gitlab::JobWaiter.new(0, 'some-job-key') }

  let(:gist) do
    {
      id: '055b70',
      git_pull_url: url,
      files: {
        'random.txt': {
          filename: 'random.txt',
          type: 'text/plain',
          language: 'Text',
          raw_url: 'https://gist.githubusercontent.com/user_name/055b70/raw/66a7be0d/random.txt',
          size: 166903
        }
      },
      public: false,
      created_at: '2022-09-06T11:38:18Z',
      updated_at: '2022-09-06T11:38:18Z',
      description: 'random text'
    }
  end

  let(:gist_hash) do
    {
      id: '055b70',
      import_url: url,
      files: {
        'random.txt': {
          filename: 'random.txt',
          type: 'text/plain',
          language: 'Text',
          raw_url: 'https://gist.githubusercontent.com/user_name/055b70/raw/66a7be0d/random.txt',
          size: 166903
        }
      },
      public: false,
      created_at: '2022-09-06T11:38:18Z',
      updated_at: '2022-09-06T11:38:18Z',
      title: 'random text'
    }
  end

  let(:gist_represent) { instance_double('Gitlab::GithubGistsImport::Representation::Gist', to_hash: gist_hash) }

  describe '#execute' do
    before do
      allow(Gitlab::GithubImport::Client)
        .to receive(:new)
        .with(token, parallel: true)
        .and_return(client)

      allow(Gitlab::Import::PageCounter)
        .to receive(:new)
        .with(user, :gists, 'github-gists-importer')
        .and_return(page_counter)

      allow(client)
        .to receive(:each_page)
        .with(:gists, nil, { page: 1 })
        .and_yield(page)

      allow(Gitlab::GithubGistsImport::Representation::Gist)
        .to receive(:from_api_response)
        .with(gist)
        .and_return(gist_represent)

      allow(Gitlab::JobWaiter)
        .to receive(:new)
        .and_return(waiter)
    end

    context 'when success' do
      it 'spread parallel import' do
        expect(Gitlab::GithubGistsImport::ImportGistWorker)
          .to receive(:bulk_perform_in)
          .with(
            1.second,
            [[user.id, gist_hash, waiter.key]],
            batch_delay: 1.minute,
            batch_size: 1000
          )

        expect(result.waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(result.waiter.jobs_remaining).to eq(1)
      end
    end

    context 'when failure' do
      it 'returns an error' do
        expect(Gitlab::GithubGistsImport::ImportGistWorker)
          .to receive(:bulk_perform_in)
          .and_raise(StandardError, 'Error Message')

        expect(result.error).to be_an_instance_of(StandardError)
      end
    end

    context 'when rate limit reached' do
      it 'returns an error' do
        expect(Gitlab::GithubGistsImport::ImportGistWorker)
          .to receive(:bulk_perform_in)
          .and_raise(Gitlab::GithubImport::RateLimitError)

        expect(result.error).to be_an_instance_of(Gitlab::GithubImport::RateLimitError)
      end
    end
  end
end
