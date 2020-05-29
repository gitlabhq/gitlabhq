# frozen_string_literal: true

require 'spec_helper'

describe Import::GithubService do
  let_it_be(:user) { create(:user) }
  let_it_be(:token) { 'complex-token' }
  let_it_be(:access_params) { { github_access_token: 'github-complex-token' } }
  let_it_be(:client) { Gitlab::LegacyGithubImport::Client.new(token) }
  let_it_be(:params) { { repo_id: 123, new_name: 'new_repo', target_namespace: 'root' } }

  let(:subject) { described_class.new(client, user, params) }

  before do
    allow(subject).to receive(:authorized?).and_return(true)
  end

  context 'do not raise an exception on input error' do
    let(:exception) { Octokit::ClientError.new(status: 404, body: 'Not Found') }

    before do
      expect(client).to receive(:repo).and_raise(exception)
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

    expect(client).to receive(:repo).and_raise(exception)

    expect(Gitlab::Import::Logger).not_to receive(:error)

    expect { subject.execute(access_params, :github) }.to raise_error(exception)
  end
end
