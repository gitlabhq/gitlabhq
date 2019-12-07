# frozen_string_literal: true

require 'spec_helper'

# We stub Gitaly in `spec/support/gitaly.rb` for other tests. We don't want
# those stubs while testing the GitalyClient itself.
describe Gitlab::GitalyClient do
  let(:sample_cert) { Rails.root.join('spec/fixtures/clusters/sample_cert.pem').to_s }

  before do
    allow(described_class)
      .to receive(:stub_cert_paths)
      .and_return([sample_cert])
  end

  def stub_repos_storages(address)
    allow(Gitlab.config.repositories).to receive(:storages).and_return({
      'default' => { 'gitaly_address' => address }
    })
  end

  describe '.long_timeout' do
    context 'default case' do
      it { expect(subject.long_timeout).to eq(6.hours) }
    end

    context 'running in Unicorn' do
      before do
        stub_const('Unicorn', 1)
      end

      it { expect(subject.long_timeout).to eq(55) }
    end

    context 'running in Puma' do
      before do
        stub_const('Puma', 1)
      end

      it { expect(subject.long_timeout).to eq(55) }
    end
  end

  describe '.filesystem_id_from_disk' do
    it 'catches errors' do
      [Errno::ENOENT, Errno::EACCES, JSON::ParserError].each do |error|
        allow(File).to receive(:read).with(described_class.storage_metadata_file_path('default')).and_raise(error)

        expect(described_class.filesystem_id_from_disk('default')).to be_nil
      end
    end
  end

  describe '.filesystem_id' do
    it 'returns an empty string when the storage is not found in the response' do
      response = double("response")
      allow(response).to receive(:storage_statuses).and_return([])
      allow_next_instance_of(Gitlab::GitalyClient::ServerService) do |instance|
        allow(instance).to receive(:info).and_return(response)
      end

      expect(described_class.filesystem_id('default')).to eq(nil)
    end
  end

  describe '.stub_class' do
    it 'returns the gRPC health check stub' do
      expect(described_class.stub_class(:health_check)).to eq(::Grpc::Health::V1::Health::Stub)
    end

    it 'returns a Gitaly stub' do
      expect(described_class.stub_class(:ref_service)).to eq(::Gitaly::RefService::Stub)
    end
  end

  describe '.stub_address' do
    it 'returns the same result after being called multiple times' do
      address = 'tcp://localhost:9876'
      stub_repos_storages address

      2.times do
        expect(described_class.stub_address('default')).to eq('localhost:9876')
      end
    end
  end

  describe '.stub_certs' do
    it 'skips certificates if OpenSSLError is raised and report it' do
      expect(Rails.logger).to receive(:error).at_least(:once)
      expect(Gitlab::Sentry)
        .to receive(:track_exception)
        .with(
          a_kind_of(OpenSSL::X509::CertificateError),
          extra: { cert_file: a_kind_of(String) }).at_least(:once)

      expect(OpenSSL::X509::Certificate)
        .to receive(:new)
        .and_raise(OpenSSL::X509::CertificateError).at_least(:once)

      expect(described_class.stub_certs).to be_a(String)
    end
  end
  describe '.stub_creds' do
    it 'returns :this_channel_is_insecure if unix' do
      address = 'unix:/tmp/gitaly.sock'
      stub_repos_storages address

      expect(described_class.stub_creds('default')).to eq(:this_channel_is_insecure)
    end

    it 'returns :this_channel_is_insecure if tcp' do
      address = 'tcp://localhost:9876'
      stub_repos_storages address

      expect(described_class.stub_creds('default')).to eq(:this_channel_is_insecure)
    end

    it 'returns Credentials object if tls' do
      address = 'tls://localhost:9876'
      stub_repos_storages address

      expect(described_class.stub_creds('default')).to be_a(GRPC::Core::ChannelCredentials)
    end
  end

  describe '.stub' do
    # Notice that this is referring to gRPC "stubs", not rspec stubs
    before do
      described_class.clear_stubs!
    end

    context 'when passed a UNIX socket address' do
      it 'passes the address as-is to GRPC' do
        address = 'unix:/tmp/gitaly.sock'
        stub_repos_storages address

        expect(Gitaly::CommitService::Stub).to receive(:new).with(address, any_args)

        described_class.stub(:commit_service, 'default')
      end
    end

    context 'when passed a TLS address' do
      it 'strips tls:// prefix before passing it to GRPC::Core::Channel initializer' do
        address = 'localhost:9876'
        prefixed_address = "tls://#{address}"
        stub_repos_storages prefixed_address

        expect(Gitaly::CommitService::Stub).to receive(:new).with(address, any_args)

        described_class.stub(:commit_service, 'default')
      end
    end

    context 'when passed a TCP address' do
      it 'strips tcp:// prefix before passing it to GRPC::Core::Channel initializer' do
        address = 'localhost:9876'
        prefixed_address = "tcp://#{address}"
        stub_repos_storages prefixed_address

        expect(Gitaly::CommitService::Stub).to receive(:new).with(address, any_args)

        described_class.stub(:commit_service, 'default')
      end
    end
  end

  describe '.can_use_disk?' do
    it 'properly caches a false result' do
      # spec_helper stubs this globally
      allow(described_class).to receive(:can_use_disk?).and_call_original
      expect(described_class).to receive(:filesystem_id).once
      expect(described_class).to receive(:filesystem_id_from_disk).once

      2.times do
        described_class.can_use_disk?('unknown')
      end
    end
  end

  describe '.connection_data' do
    it 'returns connection data' do
      address = 'tcp://localhost:9876'
      stub_repos_storages address

      expect(described_class.connection_data('default')).to eq({ 'address' => address, 'token' => 'secret' })
    end
  end

  describe 'allow_n_plus_1_calls' do
    context 'when RequestStore is enabled', :request_store do
      it 'returns the result of the allow_n_plus_1_calls block' do
        expect(described_class.allow_n_plus_1_calls { "result" }).to eq("result")
      end
    end

    context 'when RequestStore is not active' do
      it 'returns the result of the allow_n_plus_1_calls block' do
        expect(described_class.allow_n_plus_1_calls { "something" }).to eq("something")
      end
    end
  end

  describe '.request_kwargs' do
    context 'when catfile-cache feature is enabled' do
      before do
        stub_feature_flags('gitaly_catfile-cache': true)
      end

      it 'sets the gitaly-session-id in the metadata' do
        results = described_class.request_kwargs('default', timeout: 1)
        expect(results[:metadata]).to include('gitaly-session-id')
      end

      context 'when RequestStore is not enabled' do
        it 'sets a different gitaly-session-id per request' do
          gitaly_session_id = described_class.request_kwargs('default', timeout: 1)[:metadata]['gitaly-session-id']

          expect(described_class.request_kwargs('default', timeout: 1)[:metadata]['gitaly-session-id']).not_to eq(gitaly_session_id)
        end
      end

      context 'when RequestStore is enabled', :request_store do
        it 'sets the same gitaly-session-id on every outgoing request metadata' do
          gitaly_session_id = described_class.request_kwargs('default', timeout: 1)[:metadata]['gitaly-session-id']

          3.times do
            expect(described_class.request_kwargs('default', timeout: 1)[:metadata]['gitaly-session-id']).to eq(gitaly_session_id)
          end
        end
      end
    end
  end

  describe 'enforce_gitaly_request_limits?' do
    def call_gitaly(count = 1)
      (1..count).each do
        described_class.enforce_gitaly_request_limits(:test)
      end
    end

    context 'when RequestStore is enabled and the maximum number of calls is not enforced by a feature flag', :request_store do
      before do
        stub_feature_flags(gitaly_enforce_requests_limits: false)
      end

      it 'allows up the maximum number of allowed calls' do
        expect { call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS) }.not_to raise_error
      end

      it 'allows the maximum number of calls to be exceeded if GITALY_DISABLE_REQUEST_LIMITS is set' do
        stub_env('GITALY_DISABLE_REQUEST_LIMITS', 'true')

        expect { call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS + 1) }.not_to raise_error
      end

      context 'when the maximum number of calls has been reached' do
        before do
          call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS)
        end

        it 'fails on the next call' do
          expect { call_gitaly(1) }.to raise_error(Gitlab::GitalyClient::TooManyInvocationsError)
        end
      end

      it 'allows the maximum number of calls to be exceeded within an allow_n_plus_1_calls block' do
        expect do
          described_class.allow_n_plus_1_calls do
            call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS + 1)
          end
        end.not_to raise_error
      end

      context 'when the maximum number of calls has been reached within an allow_n_plus_1_calls block' do
        before do
          described_class.allow_n_plus_1_calls do
            call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS)
          end
        end

        it 'allows up to the maximum number of calls outside of an allow_n_plus_1_calls block' do
          expect { call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS) }.not_to raise_error
        end

        it 'does not allow the maximum number of calls to be exceeded outside of an allow_n_plus_1_calls block' do
          expect { call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS + 1) }.to raise_error(Gitlab::GitalyClient::TooManyInvocationsError)
        end
      end
    end

    context 'in production and when RequestStore is enabled', :request_store do
      before do
        stub_rails_env('production')
      end

      context 'when the maximum number of calls is enforced by a feature flag' do
        before do
          stub_feature_flags(gitaly_enforce_requests_limits: true)
        end

        it 'does not allow the maximum number of calls to be exceeded' do
          expect { call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS + 1) }.to raise_error(Gitlab::GitalyClient::TooManyInvocationsError)
        end
      end

      context 'when the maximum number of calls is not enforced by a feature flag' do
        before do
          stub_feature_flags(gitaly_enforce_requests_limits: false)
        end

        it 'allows the maximum number of calls to be exceeded' do
          expect { call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS + 1) }.not_to raise_error
        end
      end
    end

    context 'when RequestStore is not active' do
      it 'does not raise errors when the maximum number of allowed calls is exceeded' do
        expect { call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS + 2) }.not_to raise_error
      end

      it 'does not fail when the maximum number of calls is exceeded within an allow_n_plus_1_calls block' do
        expect do
          described_class.allow_n_plus_1_calls do
            call_gitaly(Gitlab::GitalyClient::MAXIMUM_GITALY_CALLS + 1)
          end
        end.not_to raise_error
      end
    end
  end

  describe 'get_request_count' do
    context 'when RequestStore is enabled', :request_store do
      context 'when enforce_gitaly_request_limits is called outside of allow_n_plus_1_calls blocks' do
        before do
          described_class.enforce_gitaly_request_limits(:call)
        end

        it 'counts gitaly calls' do
          expect(described_class.get_request_count).to eq(1)
        end
      end

      context 'when enforce_gitaly_request_limits is called inside and outside of allow_n_plus_1_calls blocks' do
        before do
          described_class.enforce_gitaly_request_limits(:call)
          described_class.allow_n_plus_1_calls do
            described_class.enforce_gitaly_request_limits(:call)
          end
        end

        it 'counts gitaly calls' do
          expect(described_class.get_request_count).to eq(2)
        end
      end

      context 'when reset_counts is called' do
        before do
          described_class.enforce_gitaly_request_limits(:call)
          described_class.reset_counts
        end

        it 'resets counts' do
          expect(described_class.get_request_count).to eq(0)
        end
      end
    end

    context 'when RequestStore is not active' do
      before do
        described_class.enforce_gitaly_request_limits(:call)
      end

      it 'returns zero' do
        expect(described_class.get_request_count).to eq(0)
      end
    end
  end

  describe 'timeouts' do
    context 'with default values' do
      before do
        stub_application_setting(gitaly_timeout_default: 55)
        stub_application_setting(gitaly_timeout_medium: 30)
        stub_application_setting(gitaly_timeout_fast: 10)
      end

      it 'returns expected values' do
        expect(described_class.default_timeout).to be(55)
        expect(described_class.medium_timeout).to be(30)
        expect(described_class.fast_timeout).to be(10)
      end
    end
  end

  describe 'Peek Performance bar details' do
    let(:gitaly_server) { Gitaly::Server.all.first }

    before do
      Gitlab::SafeRequestStore[:peek_enabled] = true
    end

    context 'when the request store is active', :request_store do
      it 'records call details if a RPC is called' do
        expect(described_class).to receive(:measure_timings).and_call_original

        gitaly_server.server_version

        expect(described_class.list_call_details).not_to be_empty
        expect(described_class.list_call_details.size).to be(1)
      end
    end

    context 'when no request store is active' do
      it 'records nothing' do
        gitaly_server.server_version

        expect(described_class.list_call_details).to be_empty
      end
    end
  end
end
