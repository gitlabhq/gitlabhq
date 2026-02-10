# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Import::ValidateRemoteGitEndpointService, feature_category: :importers do
  let(:url) { 'https://demo.host/repo' }

  describe '#execute' do
    let(:repository_exists) { true }

    subject { described_class.new(url: url) }

    before do
      allow(Gitlab::GitalyClient::RemoteService)
        .to receive(:exists?)
        .with(url)
        .and_return(repository_exists)
    end

    context 'when uri is using git:// protocol' do
      let(:url) { 'git://demo.host/repo' }

      it 'returns success' do
        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.success?).to be(true)
      end
    end

    shared_examples 'error response' do
      it 'reports an error' do
        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result.error?).to be(true)
        expect(result.message).to eq('Unable to access repository with the URL and credentials provided')
        expect(result.reason).to eq(400)
      end
    end

    context 'when remote repository does not exist' do
      let(:repository_exists) { false }

      include_examples 'error response'
    end

    context 'when uri is invalid' do
      using RSpec::Parameterized::TableSyntax

      where(:invalid_url) do
        [
          nil,                        # uri is nil
          '',                         # uri is empty string
          'example.com',              # uri does not have a schema
          'ssh://demo.host/repo',     # uri is using an invalid protocol
          'http:example.com'          # uri is malformed
        ]
      end

      with_them do
        it 'returns error for invalid URI' do
          allow(Gitlab::GitalyClient::RemoteService)
            .to receive(:exists?)
            .and_return(true)

          result = described_class.new(url: invalid_url).execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).to eq('Unable to access repository with the URL and credentials provided')
          expect(result.reason).to eq(400)
        end
      end
    end

    context 'when remote times out' do
      before do
        allow(Gitlab::GitalyClient::RemoteService).to receive(:exists?).and_raise(GRPC::DeadlineExceeded)
      end

      include_examples 'error response'
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

      context 'when error occurs with credentials in URL' do
        let(:url) { "https://#{user}:#{password}@demo.host/repo" }

        before do
          allow(Gitlab::GitalyClient::RemoteService).to receive(:exists?).and_return(false)
        end

        it 'masks credentials in error response' do
          result = described_class.new(url: url).execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).not_to include(password)
          expect(result.message).not_to include(user)
        end
      end

      context 'when error occurs with credentials in params' do
        before do
          allow(Gitlab::GitalyClient::RemoteService).to receive(:exists?).and_return(false)
        end

        it 'masks credentials in error response' do
          result = described_class.new(url: url, user: user, password: password).execute

          expect(result).to be_a(ServiceResponse)
          expect(result.error?).to be(true)
          expect(result.message).not_to include(password)
          expect(result.message).not_to include(user)
        end
      end
    end

    context 'with URL security validation' do
      before do
        allow(Gitlab::CurrentSettings).to receive_messages(
          allow_local_requests_from_web_hooks_and_services?: false,
          dns_rebinding_protection_enabled?: true,
          deny_all_requests_except_allowed?: false,
          outbound_local_requests_whitelist: [])
        allow(Gitlab).to receive(:http_proxy_env?).and_return(false)
      end

      context 'when URL resolves to localhost' do
        where(:localhost_url) do
          [
            'http://127.0.0.1:12345',
            'https://localhost'
          ]
        end

        with_them do
          it 'returns error for localhost URI' do
            allow(Gitlab::GitalyClient::RemoteService)
              .to receive(:exists?)
              .and_return(true)

            result = described_class.new(url: localhost_url).execute

            expect(result).to be_a(ServiceResponse)
            expect(result.error?).to be(true)
            expect(result.message).to eq('Requests to localhost are not allowed')
            expect(result.reason).to eq(400)
          end
        end
      end

      context 'when URL resolves to loopback urls' do
        where(:loopback_url) do
          [
            'http://127.0.0.0',
            'http://127.0.0.2/repo'
          ]
        end

        with_them do
          it 'returns error for loopback URI' do
            allow(Gitlab::GitalyClient::RemoteService)
              .to receive(:exists?)
              .and_return(true)

            result = described_class.new(url: loopback_url).execute

            expect(result).to be_a(ServiceResponse)
            expect(result.error?).to be(true)
            expect(result.message).to eq('Requests to loopback addresses are not allowed')
            expect(result.reason).to eq(400)
          end
        end
      end

      context 'when URL resolves to private network' do
        where(:private_network_url) do
          [
            'http://10.0.0.1/repo',
            'http://172.16.0.1/repo',
            'http://192.168.1.1/repo'
          ]
        end

        with_them do
          it 'returns error for private networks' do
            allow(Gitlab::GitalyClient::RemoteService)
              .to receive(:exists?)
              .and_return(true)

            result = described_class.new(url: private_network_url).execute

            expect(result).to be_a(ServiceResponse)
            expect(result.error?).to be(true)
            expect(result.message).to eq('Requests to the local network are not allowed')
            expect(result.reason).to eq(400)
          end
        end
      end

      context 'when URL is allowed' do
        let(:url) { 'https://demo.host/repo' }

        it 'proceeds with validation' do
          result = subject.execute

          expect(result).to be_a(ServiceResponse)
          expect(result.success?).to be(true)
        end
      end

      context 'when http_proxy_env? is true' do
        it 'disables dns_rebind_protection' do
          allow(Gitlab).to receive(:http_proxy_env?).and_return(true)

          expect(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!).with(
            url,
            hash_including(dns_rebind_protection: false)
          ).and_return([url, nil])

          subject.execute
        end
      end

      context 'when http_proxy_env? is false' do
        it 'enables dns_rebind_protection' do
          allow(Gitlab).to receive(:http_proxy_env?).and_return(false)

          expect(Gitlab::HTTP_V2::UrlBlocker).to receive(:validate!).with(
            url,
            hash_including(dns_rebind_protection: true)
          ).and_return([url, nil])

          subject.execute
        end
      end
    end
  end
end
