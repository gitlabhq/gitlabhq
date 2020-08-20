# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubService do
  let_it_be(:user) { create(:user) }
  let_it_be(:token) { 'complex-token' }
  let_it_be(:access_params) { { github_access_token: 'github-complex-token' } }
  let_it_be(:params) { { repo_id: 123, new_name: 'new_repo', target_namespace: 'root' } }

  let(:subject) { described_class.new(client, user, params) }

  before do
    allow(subject).to receive(:authorized?).and_return(true)
  end

  shared_examples 'handles errors' do |klass|
    let(:client) { klass.new(token) }

    context 'do not raise an exception on input error' do
      let(:exception) { Octokit::ClientError.new(status: 404, body: 'Not Found') }

      before do
        expect(client).to receive(:repository).and_raise(exception)
      end

      it 'logs the original error' do
        expect(Gitlab::Import::Logger).to receive(:error).with({
          message: 'Import failed due to a GitHub error',
          status: 404,
          error: 'Not Found'
        }).and_call_original

        subject.execute(access_params, :github)
      end

      it 'returns an error' do
        result = subject.execute(access_params, :github)

        expect(result).to include(
          message: 'Import failed due to a GitHub error: Not Found',
          status: :error,
          http_status: :unprocessable_entity
        )
      end
    end

    it 'raises an exception for unknown error causes' do
      exception = StandardError.new('Not Implemented')

      expect(client).to receive(:repository).and_raise(exception)

      expect(Gitlab::Import::Logger).not_to receive(:error)

      expect { subject.execute(access_params, :github) }.to raise_error(exception)
    end
  end

  context 'when remove_legacy_github_client feature flag is enabled' do
    before do
      stub_feature_flags(remove_legacy_github_client: true)
    end

    include_examples 'handles errors', Gitlab::GithubImport::Client
  end

  context 'when remove_legacy_github_client feature flag is enabled' do
    before do
      stub_feature_flags(remove_legacy_github_client: false)
    end

    include_examples 'handles errors', Gitlab::LegacyGithubImport::Client
  end
end
