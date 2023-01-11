# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Github::GistsImportService, feature_category: :importers do
  subject(:import) { described_class.new(user, client, params) }

  let_it_be(:user) { create(:user) }
  let(:params) { { github_access_token: 'token' } }
  let(:import_status) { instance_double('Gitlab::GithubGistsImport::Status') }
  let(:client) { Gitlab::GithubImport::Client.new(params[:github_access_token]) }
  let(:octokit_user) { { login: 'user_login' } }

  describe '#execute', :aggregate_failures do
    before do
      allow(Gitlab::GithubGistsImport::Status).to receive(:new).and_return(import_status)
      allow(client.octokit).to receive(:user).and_return(octokit_user)
    end

    context 'when import in progress' do
      let(:expected_result) do
        {
          status: :error,
          http_status: 422,
          message: 'Import already in progress'
        }
      end

      it 'returns error' do
        expect(import_status).to receive(:started?).and_return(true)
        expect(import.execute).to eq(expected_result)
      end
    end

    context 'when import was not started' do
      it 'returns success' do
        encrypted_token = Gitlab::CryptoHelper.aes256_gcm_encrypt(params[:github_access_token])
        expect(import_status).to receive(:started?).and_return(false)
        expect(Gitlab::CryptoHelper)
          .to receive(:aes256_gcm_encrypt).with(params[:github_access_token])
          .and_return(encrypted_token)
        expect(Gitlab::GithubGistsImport::StartImportWorker)
          .to receive(:perform_async).with(user.id, encrypted_token)
        expect(import_status).to receive(:start!)

        expect(import.execute).to eq({ status: :success })
      end
    end

    context 'when user token is invalid' do
      before do
        allow(client.octokit).to receive(:user).and_raise(Octokit::Unauthorized)
        allow(import_status).to receive(:started?).and_return(false)
      end

      let(:expected_result) do
        {
          http_status: 401,
          message: 'Access denied to the GitHub account.',
          status: :error
        }
      end

      it 'returns 401 error' do
        expect(import.execute).to eq(expected_result)
      end
    end
  end
end
