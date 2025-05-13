# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::ValidateRemoteGitEndpointService, feature_category: :importers do
  let(:url) { 'https://demo.host/repo' }

  describe '#execute' do
    context 'when uri is using git:// protocol' do
      let(:url) { 'git://demo.host/repo' }

      subject { described_class.new(url: url) }

      it 'returns success' do
        allow(Gitlab::GitalyClient::RemoteService)
          .to receive(:exists?)
          .with(url)
          .and_return(true)

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.success?).to be(true)
      end
    end

    context 'when uri is invalid' do
      shared_examples 'error response' do
        subject { described_class.new(url: url) }

        it 'reports error when invalid URL is provided' do
          allow(Gitlab::GitalyClient::RemoteService)
            .to receive(:exists?)
            .with(url)
            .and_return(false)

          result = subject.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to eq('Unable to access repository with the URL and credentials provided')
          expect(result.reason).to eq(400)
        end
      end

      context 'when uri is nil' do
        let(:url) { nil }

        include_examples 'error response'
      end

      context 'when uri does not have a schema' do
        let(:url) { 'example.com' }

        include_examples 'error response'
      end

      context 'when uri is using an invalid protocol' do
        let(:url) { 'ssh://demo.host/repo' }

        include_examples 'error response'
      end

      context 'when uri is invalid' do
        let(:url) { 'http:example.com' }

        include_examples 'error response'
      end
    end

    context 'with auth credentials' do
      let(:user) { 'foo' }
      let(:password) { 'bar' }

      context 'when credentials are provided via params' do
        it 'sets basic auth from these credentials' do
          expect(Gitlab::GitalyClient::RemoteService).to receive(:exists?).with('https://foo:bar@demo.host/repo')

          described_class.new(url: url, user: user, password: password).execute
        end
      end

      context 'when credentials are provided in url' do
        let(:url) { "https://#{user}:#{password}@demo.host/repo" }

        it 'passes basic auth from uri credentials' do
          expect(Gitlab::GitalyClient::RemoteService).to receive(:exists?).with('https://foo:bar@demo.host/repo')

          described_class.new(url: url).execute
        end
      end

      context 'when credentials are set via both params and url' do
        let(:url) { "https://uri_user:url_password@demo.host/repo" }

        it 'prefers credentials via params' do
          expect(Gitlab::GitalyClient::RemoteService).to receive(:exists?).with('https://foo:bar@demo.host/repo')

          described_class.new(url: url, user: user, password: password).execute
        end
      end
    end
  end
end
