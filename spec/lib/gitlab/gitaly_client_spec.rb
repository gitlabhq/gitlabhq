# frozen_string_literal: true

require 'spec_helper'

# We stub Gitaly in `spec/support/gitaly.rb` for other tests. We don't want
# those stubs while testing the GitalyClient itself.
RSpec.describe Gitlab::GitalyClient, feature_category: :gitaly do
  def stub_repos_storages(address)
    allow(Gitlab.config.repositories).to receive(:storages).and_return({
      'default' => { 'gitaly_address' => address }
    })
  end

  around do |example|
    described_class.clear_stubs!
    example.run
    described_class.clear_stubs!
  end

  describe '.query_time', :request_store do
    it 'increments query times' do
      subject.add_query_time(0.4510004)
      subject.add_query_time(0.3220004)

      expect(subject.query_time).to eq(0.773001)
    end
  end

  describe '.long_timeout' do
    context 'default case' do
      it { expect(subject.long_timeout).to eq(6.hours) }
    end

    context 'running in Puma' do
      before do
        allow(Gitlab::Runtime).to receive(:puma?).and_return(true)
      end

      it { expect(subject.long_timeout).to eq(55) }
    end
  end

  describe '.filesystem_id' do
    it 'returns an empty string when the relevant storage status is not found in the response' do
      response = double("response")
      allow(response).to receive(:storage_statuses).and_return([])
      allow_next_instance_of(Gitlab::GitalyClient::ServerService) do |instance|
        allow(instance).to receive(:info).and_return(response)
      end

      expect(described_class.filesystem_id('default')).to eq(nil)
    end
  end

  context 'when the relevant storage status is not found' do
    before do
      response = double('response')
      allow(response).to receive(:storage_statuses).and_return([])
      allow_next_instance_of(Gitlab::GitalyClient::ServerService) do |instance|
        allow(instance).to receive(:disk_statistics).and_return(response)
        expect(instance).to receive(:storage_disk_statistics)
      end
    end

    describe '.filesystem_disk_available' do
      it 'returns nil when the relevant storage status is not found in the response' do
        expect(described_class.filesystem_disk_available('default')).to eq(nil)
      end
    end

    describe '.filesystem_disk_used' do
      it 'returns nil when the relevant storage status is not found in the response' do
        expect(described_class.filesystem_disk_used('default')).to eq(nil)
      end
    end
  end

  context 'when the relevant storage status is found' do
    let(:disk_available) { 42 }
    let(:disk_used) { 42 }
    let(:storage_status) { double('storage_status') }

    before do
      allow(storage_status).to receive(:storage_name).and_return('default')
      allow(storage_status).to receive(:used).and_return(disk_used)
      allow(storage_status).to receive(:available).and_return(disk_available)
      response = double('response')
      allow(response).to receive(:storage_statuses).and_return([storage_status])
      allow_next_instance_of(Gitlab::GitalyClient::ServerService) do |instance|
        allow(instance).to receive(:disk_statistics).and_return(response)
      end
      expect_next_instance_of(Gitlab::GitalyClient::ServerService) do |instance|
        expect(instance).to receive(:storage_disk_statistics).and_return(storage_status)
      end
    end

    describe '.filesystem_disk_available' do
      it 'returns disk available when the relevant storage status is found in the response' do
        expect(storage_status).to receive(:available)
        expect(described_class.filesystem_disk_available('default')).to eq(disk_available)
      end
    end

    describe '.filesystem_disk_used' do
      it 'returns disk used when the relevant storage status is found in the response' do
        expect(storage_status).to receive(:used)
        expect(described_class.filesystem_disk_used('default')).to eq(disk_used)
      end
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

    it 'returns :this_channel_is_insecure if dns' do
      address = 'dns:///localhost:9876'
      stub_repos_storages address

      expect(described_class.stub_creds('default')).to eq(:this_channel_is_insecure)
    end

    it 'returns :this_channel_is_insecure if dns (short-form)' do
      address = 'dns:localhost:9876'
      stub_repos_storages address

      expect(described_class.stub_creds('default')).to eq(:this_channel_is_insecure)
    end

    it 'returns :this_channel_is_insecure if dns (with authority)' do
      address = 'dns://1.1.1.1/localhost:9876'
      stub_repos_storages address

      expect(described_class.stub_creds('default')).to eq(:this_channel_is_insecure)
    end

    it 'returns Credentials object if tls' do
      address = 'tls://localhost:9876'
      stub_repos_storages address

      expect(described_class.stub_creds('default')).to be_a(GRPC::Core::ChannelCredentials)
    end

    it 'raise an exception if the scheme is not supported' do
      address = 'custom://localhost:9876'
      stub_repos_storages address

      expect do
        described_class.stub_creds('default')
      end.to raise_error(/unsupported Gitaly address/i)
    end
  end

  describe '.create_channel' do
    where(:storage, :address, :expected_target) do
      [
        ['default', 'unix:tmp/gitaly.sock', 'unix:tmp/gitaly.sock'],
        ['default', 'tcp://localhost:9876', 'dns:///localhost:9876'],
        ['default', 'tls://localhost:9876', 'dns:///localhost:9876'],
        ['default', 'dns:///localhost:9876', 'dns:///localhost:9876'],
        ['default', 'dns:localhost:9876', 'dns:localhost:9876'],
        ['default', 'dns://1.1.1.1/localhost:9876', 'dns://1.1.1.1/localhost:9876']
      ]
    end

    with_them do
      before do
        allow(Gitlab.config.repositories).to receive(:storages).and_return(
          'default' => { 'gitaly_address' => address },
          'other' => { 'gitaly_address' => address }
        )
      end

      it 'creates channel based on storage' do
        channel = described_class.create_channel(storage)

        expect(channel).to be_a(GRPC::Core::Channel)
        expect(channel.target).to eql(expected_target)
      end

      it 'caches channel based on storage' do
        channel_1 = described_class.create_channel(storage)
        channel_2 = described_class.create_channel(storage)

        expect(channel_1).to equal(channel_2)
      end

      it 'returns different channels for different storages' do
        channel_1 = described_class.create_channel(storage)
        channel_2 = described_class.create_channel('other')

        expect(channel_1).not_to equal(channel_2)
      end
    end
  end

  describe '.stub' do
    matcher :be_a_grpc_channel do |expected_address|
      match { |actual| actual.is_a?(::GRPC::Core::Channel) && actual.target == expected_address }
    end

    matcher :have_same_channel do |expected|
      match do |actual|
        # gRPC client stub does not expose the underlying channel. We need a way
        # to verify two stubs have the same channel. So, no way around.
        expected_channel = expected.instance_variable_get(:@ch)
        actual_channel = actual.instance_variable_get(:@ch)
        expected_channel.is_a?(GRPC::Core::Channel) &&
          actual_channel.is_a?(GRPC::Core::Channel) &&
          expected_channel == actual_channel
      end
    end

    context 'when passed a UNIX socket address' do
      let(:address) { 'unix:/tmp/gitaly.sock' }

      before do
        stub_repos_storages address
      end

      it 'passes the address as-is to GRPC' do
        expect(Gitaly::CommitService::Stub).to receive(:new).with(
          address, nil, channel_override: be_a_grpc_channel(address), interceptors: []
        )
        described_class.stub(:commit_service, 'default')
      end

      it 'shares the same channel object with other stub' do
        stub_commit = described_class.stub(:commit_service, 'default')
        stub_blob = described_class.stub(:blob_service, 'default')

        expect(stub_commit).to have_same_channel(stub_blob)
      end
    end

    context 'when passed a TLS address' do
      let(:address) { 'localhost:9876' }

      before do
        prefixed_address = "tls://#{address}"
        stub_repos_storages prefixed_address
      end

      it 'strips tls:// prefix before passing it to GRPC::Core::Channel initializer' do
        expect(Gitaly::CommitService::Stub).to receive(:new).with(
          "dns:///#{address}", nil, channel_override: be_a(GRPC::Core::Channel), interceptors: []
        )

        described_class.stub(:commit_service, 'default')
      end

      it 'shares the same channel object with other stub' do
        stub_commit = described_class.stub(:commit_service, 'default')
        stub_blob = described_class.stub(:blob_service, 'default')

        expect(stub_commit).to have_same_channel(stub_blob)
      end
    end

    context 'when passed a TCP address' do
      let(:address) { 'localhost:9876' }

      before do
        prefixed_address = "tcp://#{address}"
        stub_repos_storages prefixed_address
      end

      it 'strips tcp:// prefix before passing it to GRPC::Core::Channel initializer' do
        expect(Gitaly::CommitService::Stub).to receive(:new).with(
          "dns:///#{address}", nil, channel_override: be_a(GRPC::Core::Channel), interceptors: []
        )

        described_class.stub(:commit_service, 'default')
      end

      it 'shares the same channel object with other stub' do
        stub_commit = described_class.stub(:commit_service, 'default')
        stub_blob = described_class.stub(:blob_service, 'default')

        expect(stub_commit).to have_same_channel(stub_blob)
      end
    end

    context 'when passed a DNS address' do
      let(:address) { 'dns:///localhost:9876' }

      before do
        stub_repos_storages address
      end

      it 'strips dns:/// prefix before passing it to GRPC::Core::Channel initializer' do
        expect(Gitaly::CommitService::Stub).to receive(:new).with(
          address, nil, channel_override: be_a(GRPC::Core::Channel), interceptors: []
        )

        described_class.stub(:commit_service, 'default')
      end

      it 'shares the same channel object with other stub' do
        stub_commit = described_class.stub(:commit_service, 'default')
        stub_blob = described_class.stub(:blob_service, 'default')

        expect(stub_commit).to have_same_channel(stub_blob)
      end
    end

    context 'when passed an unsupported scheme' do
      let(:address) { 'custom://localhost:9876' }

      before do
        stub_repos_storages address
      end

      it 'strips dns:/// prefix before passing it to GRPC::Core::Channel initializer' do
        expect do
          described_class.stub(:commit_service, 'default')
        end.to raise_error(/Unsupported Gitaly address/i)
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

      context 'when the `gitaly_call_count_exception_block_depth` key is not present' do
        before do
          allow(Gitlab::SafeRequestStore).to receive(:[]).with(:gitaly_call_count_exception_block_depth).and_return(0, 1, nil)
          allow(Gitlab::SafeRequestStore).to receive(:+)
          allow(Gitlab::SafeRequestStore).to receive(:-)
        end

        it 'does not decrement call count' do
          expect(Gitlab::SafeRequestStore).not_to have_received(:-)

          described_class.allow_n_plus_1_calls { "result" }
        end
      end
    end

    context 'when RequestStore is not active' do
      it 'returns the result of the allow_n_plus_1_calls block' do
        expect(described_class.allow_n_plus_1_calls { "something" }).to eq("something")
      end
    end
  end

  describe '.request_kwargs' do
    it 'sets the gitaly-session-id in the metadata' do
      results = described_class.request_kwargs('default', timeout: 1)
      expect(results[:metadata]).to include('gitaly-session-id')
    end

    context 'with gitaly_context' do
      let(:gitaly_context) { { key: :value } }

      it 'passes context as "gitaly-client-context-bin"' do
        kwargs = described_class.request_kwargs('default', timeout: 1, gitaly_context: gitaly_context)

        expect(kwargs[:metadata]['gitaly-client-context-bin']).to eq(gitaly_context.to_json)
      end

      context 'when empty context' do
        let(:gitaly_context) { {} }

        it 'does not provide "gitaly-client-context-bin"' do
          kwargs = described_class.request_kwargs('default', timeout: 1, gitaly_context: gitaly_context)

          expect(kwargs[:metadata]).not_to have_key('gitaly-client-context-bin')
        end
      end
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

    shared_examples 'gitaly feature flags in metadata' do
      before do
        allow(Feature::Gitaly).to receive(:server_feature_flags).and_return(
          'gitaly-feature-a' => 'true',
          'gitaly-feature-b' => 'false'
        )
      end

      it 'evaluates Gitaly server feature flags' do
        metadata = described_class.request_kwargs('default', timeout: 1)[:metadata]

        expect(Feature::Gitaly).to have_received(:server_feature_flags).with(no_args)
        expect(metadata['gitaly-feature-a']).to be('true')
        expect(metadata['gitaly-feature-b']).to be('false')
      end

      context 'when there are actors' do
        let(:repository_actor) { double(:actor) }
        let(:project_actor) { double(:actor) }
        let(:user_actor) { double(:actor) }
        let(:group_actor) { double(:actor) }

        it 'evaluates Gitaly server feature flags with actors' do
          metadata = described_class.with_feature_flag_actors(
            repository: repository_actor,
            project: project_actor,
            user: user_actor,
            group: group_actor
          ) do
            described_class.request_kwargs('default', timeout: 1)[:metadata]
          end

          expect(Feature::Gitaly).to have_received(:server_feature_flags).with(
            repository: repository_actor,
            project: project_actor,
            user: user_actor,
            group: group_actor
          )
          expect(metadata['gitaly-feature-a']).to be('true')
          expect(metadata['gitaly-feature-b']).to be('false')
        end
      end
    end

    context 'server_feature_flags when RequestStore is activated', :request_store do
      it_behaves_like 'gitaly feature flags in metadata'
    end

    context 'server_feature_flags when RequestStore is not activated' do
      it_behaves_like 'gitaly feature flags in metadata'
    end

    context 'logging information in metadata' do
      let(:user) { create(:user) }

      context 'user is added to application context' do
        it 'injects username and user_id into gRPC metadata' do
          metadata = {}
          ::Gitlab::ApplicationContext.with_context(user: user) do
            metadata = described_class.request_kwargs('default', timeout: 1)[:metadata]
          end

          expect(metadata['username']).to eql(user.username)
          expect(metadata['user_id']).to eql(user.id.to_s)
        end
      end

      context 'user is not added to application context' do
        it 'does not inject username and user_id into gRPC metadata' do
          metadata = described_class.request_kwargs('default', timeout: 1)[:metadata]

          expect(metadata).not_to have_key('username')
          expect(metadata).not_to have_key('user_id')
        end
      end

      context 'remote_ip is added to application context' do
        it 'injects remote_ip into gRPC metadata' do
          metadata = {}
          ::Gitlab::ApplicationContext.with_context(remote_ip: '1.2.3.4') do
            metadata = described_class.request_kwargs('default', timeout: 1)[:metadata]
          end

          expect(metadata['remote_ip']).to eql('1.2.3.4')
        end
      end

      context 'remote_ip is not added to application context' do
        it 'does not inject remote_ip into gRPC metadata' do
          metadata = described_class.request_kwargs('default', timeout: 1)[:metadata]

          expect(metadata).not_to have_key('remote_ip')
        end
      end
    end

    describe '.fetch_relative_path' do
      subject { described_class.request_kwargs('default', timeout: 1)[:metadata]['relative-path-bin'] }

      let(:relative_path) { 'relative_path' }

      context 'when RequestStore is disabled' do
        it 'does not set a relative path' do
          is_expected.to be_nil
        end
      end

      context 'when RequestStore is enabled', :request_store do
        context 'when RequestStore is empty' do
          it 'does not set a relative path' do
            is_expected.to be_nil
          end
        end

        context 'when RequestStore contains a relalive_path value' do
          before do
            Gitlab::SafeRequestStore[:gitlab_git_relative_path] = relative_path
          end

          it 'sets a base64 encoded version of relative_path' do
            is_expected.to eq(relative_path)
          end

          context 'when relalive_path is empty' do
            let(:relative_path) { '' }

            it 'does not set a relative path' do
              is_expected.to be_nil
            end
          end
        end
      end
    end

    context 'gitlab_git_env' do
      let(:policy) { 'gitaly-route-repository-accessor-policy' }

      context 'when RequestStore is disabled' do
        it 'does not force-route to primary' do
          expect(described_class.request_kwargs('default', timeout: 1)[:metadata][policy]).to be_nil
        end
      end

      context 'when RequestStore is enabled without git_env', :request_store do
        it 'does not force-orute to primary' do
          expect(described_class.request_kwargs('default', timeout: 1)[:metadata][policy]).to be_nil
        end
      end

      context 'when RequestStore is enabled with empty git_env', :request_store do
        before do
          Gitlab::SafeRequestStore[:gitlab_git_env] = {}
        end

        it 'disables force-routing to primary' do
          expect(described_class.request_kwargs('default', timeout: 1)[:metadata][policy]).to be_nil
        end
      end

      context 'when RequestStore is enabled with populated git_env', :request_store do
        before do
          Gitlab::SafeRequestStore[:gitlab_git_env] = {
            "GIT_OBJECT_DIRECTORY_RELATIVE" => "foo/bar"
          }
        end

        it 'enables force-routing to primary' do
          expect(described_class.request_kwargs('default', timeout: 1)[:metadata][policy]).to eq('primary-only')
        end
      end
    end

    context 'deadlines', :request_store do
      let(:request_deadline) { real_time + 10.0 }

      before do
        allow(Gitlab::RequestContext.instance).to receive(:request_deadline).and_return(request_deadline)
      end

      it 'includes the deadline information', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/450626' do
        kword_args = described_class.request_kwargs('default', timeout: 2)

        expect(kword_args[:deadline])
          .to be_within(1).of(real_time + 2)
        expect(kword_args[:metadata][:deadline_type]).to eq("regular")
      end

      it 'limits the deadline do the request deadline if that is closer', :aggregate_failures do
        kword_args = described_class.request_kwargs('default', timeout: 15)

        expect(kword_args[:deadline]).to eq(request_deadline)
        expect(kword_args[:metadata][:deadline_type]).to eq("limited")
      end

      it 'does not limit calls in sidekiq' do
        expect(Sidekiq).to receive(:server?).and_return(true)

        kword_args = described_class.request_kwargs('default', timeout: 6.hours.to_i)

        expect(kword_args[:deadline]).to be_within(1).of(real_time + 6.hours.to_i)
        expect(kword_args[:metadata][:deadline_type]).to be_nil
      end

      it 'does not limit calls in sidekiq when allowed unlimited' do
        expect(Sidekiq).to receive(:server?).and_return(true)

        kword_args = described_class.request_kwargs('default', timeout: 0)

        expect(kword_args[:deadline]).to be_nil
        expect(kword_args[:metadata][:deadline_type]).to be_nil
      end

      it 'includes only the deadline specified by the timeout when there was no deadline' do
        allow(Gitlab::RequestContext.instance).to receive(:request_deadline).and_return(nil)
        kword_args = described_class.request_kwargs('default', timeout: 6.hours.to_i)

        expect(kword_args[:deadline]).to be_within(1).of(Gitlab::Metrics::System.real_time + 6.hours.to_i)
        expect(kword_args[:metadata][:deadline_type]).to be_nil
      end

      def real_time
        Gitlab::Metrics::System.real_time
      end
    end
  end

  describe 'enforce_gitaly_request_limits?' do
    def call_gitaly(count = 1)
      (1..count).each do
        described_class.enforce_gitaly_request_limits(:test)
      end
    end

    shared_examples 'enforces maximum allowed Gitaly calls' do
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

    context 'when RequestStore is enabled and the maximum number of calls is enforced by a feature flag', :request_store do
      include_examples 'enforces maximum allowed Gitaly calls'
    end

    context 'when RequestStore is enabled and the maximum number of calls is not enforced by a feature flag', :request_store do
      before do
        stub_feature_flags(gitaly_enforce_requests_limits: false)
      end

      include_examples 'enforces maximum allowed Gitaly calls'
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

  describe '.decode_detailed_error' do
    let(:detailed_error) do
      new_detailed_error(GRPC::Core::StatusCodes::INVALID_ARGUMENT,
        "error message",
        Gitaly::InvalidRefFormatError.new)
    end

    let(:error_without_details) do
      error_code = GRPC::Core::StatusCodes::INVALID_ARGUMENT
      error_message = "error message"

      status_error = Google::Rpc::Status.new(
        code: error_code,
        message: error_message,
        details: nil
      )

      GRPC::BadStatus.new(
        error_code,
        error_message,
        { "grpc-status-details-bin" => Google::Rpc::Status.encode(status_error) })
    end

    context 'decodes a structured error' do
      using RSpec::Parameterized::TableSyntax

      where(:error, :result) do
        detailed_error | Gitaly::InvalidRefFormatError.new
        error_without_details | nil
        StandardError.new | nil
      end

      with_them do
        it 'returns correct detailed error' do
          expect(described_class.decode_detailed_error(error)).to eq(result)
        end
      end
    end
  end

  describe '.unwrap_detailed_error' do
    let(:wrapped_detailed_error) do
      new_detailed_error(GRPC::Core::StatusCodes::INVALID_ARGUMENT,
        "error message",
        Gitaly::UpdateReferencesError.new(invalid_format: Gitaly::InvalidRefFormatError.new(refs: ['\invali.\d/1', '\.invali/d/2'])))
    end

    let(:detailed_error) do
      new_detailed_error(GRPC::Core::StatusCodes::INVALID_ARGUMENT,
        "error message",
        Gitaly::InvalidRefFormatError.new)
    end

    let(:error_without_details) do
      error_code = GRPC::Core::StatusCodes::INVALID_ARGUMENT
      error_message = "error message"

      status_error = Google::Rpc::Status.new(
        code: error_code,
        message: error_message,
        details: nil
      )

      GRPC::BadStatus.new(
        error_code,
        error_message,
        { "grpc-status-details-bin" => Google::Rpc::Status.encode(status_error) })
    end

    context 'unwraps detailed errors' do
      using RSpec::Parameterized::TableSyntax

      where(:error, :result) do
        wrapped_detailed_error | Gitaly::InvalidRefFormatError.new(refs: ['\invali.\d/1', '\.invali/d/2'])
        detailed_error | Gitaly::InvalidRefFormatError.new
        error_without_details | nil
        StandardError.new | nil
        nil | nil
      end

      with_them do
        it 'returns unwrapped detailed error' do
          expect(described_class.unwrap_detailed_error(error)).to eq(result)
        end
      end
    end
  end

  describe '.with_feature_flag_actor', :request_store do
    shared_examples 'with_feature_flag_actor' do
      let(:repository_actor) { double(:actor) }
      let(:project_actor) { double(:actor) }
      let(:user_actor) { double(:actor) }
      let(:group_actor) { double(:actor) }

      it 'allows access to feature flag actors inside the block' do
        expect(described_class.feature_flag_actors).to eql({})

        described_class.with_feature_flag_actors(
          repository: repository_actor,
          project: project_actor,
          user: user_actor,
          group: group_actor
        ) do
          expect(
            described_class.feature_flag_actors
          ).to eql(
            repository: repository_actor,
            project: project_actor,
            user: user_actor,
            group: group_actor)
        end

        expect(described_class.feature_flag_actors).to eql({})
      end
    end

    context 'when RequestStore is activated', :request_store do
      it_behaves_like 'with_feature_flag_actor'
    end

    context 'when RequestStore is not activated' do
      it_behaves_like 'with_feature_flag_actor'
    end
  end

  describe '.call' do
    subject(:call) do
      described_class.call(storage, service, rpc, request, remote_storage: remote_storage, timeout: timeout, gitaly_context: gitaly_context)
    end

    let(:storage) { 'default' }
    let(:service) { :ref_service }
    let(:rpc) { :find_local_branches }
    let(:request) { Gitaly::FindLocalBranchesRequest.new }
    let(:remote_storage) { nil }
    let(:timeout) { 10.seconds }
    let(:gitaly_context) { { key: :value } }

    it 'inits Gitlab::GitalyClient::Call instance with provided arguments' do
      expect(Gitlab::GitalyClient::Call).to receive(:new).with(
        storage, service, rpc, request, remote_storage, timeout, gitaly_context: gitaly_context
      ).and_call_original

      call
    end
  end

  describe '.execute' do
    subject(:execute) do
      described_class.execute('default', :ref_service, :find_local_branches, Gitaly::FindLocalBranchesRequest.new,
        remote_storage: nil, timeout: 10.seconds, gitaly_context: gitaly_context)
    end

    let(:gitaly_context) { {} }

    it 'raises an exception when running within a concurrent Ruby thread' do
      Thread.current[:restrict_within_concurrent_ruby] = true

      expect { execute }.to raise_error(Gitlab::Utils::ConcurrentRubyThreadIsUsedError,
        "Cannot run 'gitaly' if running from `Concurrent::Promise`.")

      Thread.current[:restrict_within_concurrent_ruby] = nil
    end

    context 'with gitaly_context' do
      let(:gitaly_context) { { key: :value } }

      it 'passes the gitaly_context to .request_kwargs' do
        expect(described_class).to receive(:request_kwargs).with(
          'default', timeout: 10.seconds, remote_storage: nil, gitaly_context: gitaly_context
        ).and_call_original

        execute
      end
    end
  end
end
