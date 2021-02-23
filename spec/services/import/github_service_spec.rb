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

    context 'repository size validation' do
      let(:repository_double) { double(name: 'repository', size: 99) }

      before do
        expect(client).to receive(:repository).and_return(repository_double)

        allow_next_instance_of(Gitlab::LegacyGithubImport::ProjectCreator) do |creator|
          allow(creator).to receive(:execute).and_return(double(persisted?: true))
        end
      end

      context 'when there is no repository size limit defined' do
        it 'skips the check and succeeds' do
          expect(subject.execute(access_params, :github)).to include(status: :success)
        end
      end

      context 'when the target namespace repository size limit is defined' do
        let_it_be(:group) { create(:group, repository_size_limit: 100) }

        before do
          params[:target_namespace] = group.full_path
        end

        it 'succeeds when the repository is smaller than the limit' do
          expect(subject.execute(access_params, :github)).to include(status: :success)
        end

        it 'returns error when the repository is larger than the limit' do
          allow(repository_double).to receive(:size).and_return(101)

          expect(subject.execute(access_params, :github)).to include(size_limit_error)
        end
      end

      context 'when target namespace repository limit is not defined' do
        let_it_be(:group) { create(:group) }

        before do
          stub_application_setting(repository_size_limit: 100)
        end

        context 'when application size limit is defined' do
          it 'succeeds when the repository is smaller than the limit' do
            expect(subject.execute(access_params, :github)).to include(status: :success)
          end

          it 'returns error when the repository is larger than the limit' do
            allow(repository_double).to receive(:size).and_return(101)

            expect(subject.execute(access_params, :github)).to include(size_limit_error)
          end
        end
      end
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

  def size_limit_error
    {
      status: :error,
      http_status: :unprocessable_entity,
      message: '"repository" size (101 Bytes) is larger than the limit of 100 Bytes.'
    }
  end
end
