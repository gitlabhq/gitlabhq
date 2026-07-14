# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kas::Client, feature_category: :deployment_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:agent) { create(:cluster_agent, project: project) }

  let(:client) { described_class.new }

  describe '#initialize' do
    context 'kas is not enabled' do
      before do
        allow(Gitlab::Kas).to receive(:enabled?).and_return(false)
      end

      it 'raises a configuration error' do
        expect { described_class.new }.to raise_error(described_class::ConfigurationError, 'GitLab KAS is not enabled')
      end
    end

    context 'internal url is not set' do
      before do
        allow(Gitlab::Kas).to receive(:enabled?).and_return(true)
        allow(Gitlab::Kas).to receive(:internal_url).and_return(nil)
      end

      it 'raises a configuration error' do
        expect { described_class.new }.to raise_error(described_class::ConfigurationError, 'KAS internal URL is not configured')
      end
    end
  end

  describe 'gRPC calls' do
    let(:token) { instance_double(JSONWebToken::HMACToken, encoded: 'test-token') }
    let(:kas_url) { 'grpc://example.kas.internal' }
    let(:feature_flags) { { 'kas-feature-a' => 'true', 'kas-feature-b': 'false' } }

    before do
      allow(Gitlab::Kas).to receive(:enabled?).and_return(true)
      allow(Gitlab::Kas).to receive(:internal_url).and_return(kas_url)

      allow(JSONWebToken::HMACToken).to receive(:new)
        .with(Gitlab::Kas.secret)
        .and_return(token)

      allow(token).to receive(:issuer=).with(Settings.gitlab.host)
      allow(token).to receive(:audience=).with(described_class::JWT_AUDIENCE)

      allow(::Feature::Kas).to receive(:server_feature_flags_for_grpc_request).and_return(feature_flags)
    end

    describe '#get_server_info' do
      let(:stub) { instance_double(Gitlab::Agent::ServerInfo::Rpc::ServerInfo::Stub) }
      let(:request) { instance_double(Gitlab::Agent::ServerInfo::Rpc::GetServerInfoRequest) }
      let(:server_info) { double }
      let(:response) { double(Gitlab::Agent::ServerInfo::Rpc::GetServerInfoResponse, current_server_info: server_info) }

      subject { client.get_server_info }

      before do
        expect(Gitlab::Agent::ServerInfo::Rpc::ServerInfo::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: client.send(:timeout))
          .and_return(stub)

        expect(Gitlab::Agent::ServerInfo::Rpc::GetServerInfoRequest).to receive(:new)
          .and_return(request)

        expect(stub).to receive(:get_server_info)
          .with(request, metadata: { 'authorization' => 'bearer test-token', **feature_flags })
          .and_return(response)
      end

      it { is_expected.to eq(server_info) }
    end

    describe '#start_workflow' do
      let(:stub) { instance_double(Gitlab::Agent::AutoFlow::Rpc::AutoFlow::Stub) }
      let(:response) { instance_double(Gitlab::Agent::AutoFlow::Rpc::StartWorkflowResponse) }

      subject(:result) do
        client.start_workflow(
          identity_key: 'rollout-1',
          workflow_definition: "def main(w):\n    pass\n",
          namespace_id: 600956,
          kwargs: { 'environment' => { 'id' => '42' } }
        )
      end

      before do
        expect(Gitlab::Agent::AutoFlow::Rpc::AutoFlow::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: client.send(:timeout))
          .and_return(stub)
      end

      it 'builds the request from plain arguments and returns the response' do
        expect(stub).to receive(:start_workflow) do |request, metadata:|
          expect(metadata).to eq('authorization' => 'bearer test-token', **feature_flags)
          expect(request.identity_key).to eq('rollout-1')
          expect(request.namespace_id).to eq(600956)
          expect(request.kwargs.map(&:name)).to eq(['environment'])

          key_value = request.kwargs.first.value.dict_value.key_values.first
          expect(key_value.key.string_value).to eq('id')
          expect(key_value.val.string_value).to eq('42')

          response
        end

        expect(result).to eq(response)
      end
    end

    describe '#get_connected_agentks_by_agent_ids' do
      let(:stub) { instance_double(Gitlab::Agent::AgentTracker::Rpc::AgentTracker::Stub) }
      let(:request) { instance_double(Gitlab::Agent::AgentTracker::Rpc::GetConnectedAgentksByAgentIDsRequest) }
      let(:response) { double(Gitlab::Agent::AgentTracker::Rpc::GetConnectedAgentksByAgentIDsResponse, agents: connected_agents) }

      let(:connected_agents) { [double] }

      subject { client.get_connected_agentks_by_agent_ids(agent_ids: [agent.id]) }

      before do
        expect(Gitlab::Agent::AgentTracker::Rpc::AgentTracker::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: client.send(:timeout))
          .and_return(stub)

        expect(Gitlab::Agent::AgentTracker::Rpc::GetConnectedAgentksByAgentIDsRequest).to receive(:new)
          .with(agent_ids: [agent.id])
          .and_return(request)

        expect(stub).to receive(:get_connected_agentks_by_agent_i_ds)
          .with(request, metadata: { 'authorization' => 'bearer test-token', **feature_flags })
          .and_return(response)
      end

      it { expect(subject).to eq(connected_agents) }
    end

    describe '#list_agent_config_files' do
      let(:stub) { instance_double(Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub) }

      let(:request) { instance_double(Gitlab::Agent::ConfigurationProject::Rpc::ListAgentConfigFilesRequest) }
      let(:response) { double(Gitlab::Agent::ConfigurationProject::Rpc::ListAgentConfigFilesResponse, config_files: agent_configurations) }

      let(:repository) { instance_double(Gitlab::Agent::Entity::GitalyRepository) }
      let(:gitaly_info) { instance_double(Gitlab::Agent::Entity::GitalyInfo) }
      let(:gitaly_features) { Feature::Gitaly.server_feature_flags }

      let(:agent_configurations) { [double] }

      subject { client.list_agent_config_files(project: project) }

      before do
        expect(Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: client.send(:timeout))
          .and_return(stub)

        expect(Gitlab::Agent::Entity::GitalyRepository).to receive(:new)
          .with(project.repository.gitaly_repository.to_h)
          .and_return(repository)

        expect(Gitlab::Agent::Entity::GitalyInfo).to receive(:new)
          .with(Gitlab::GitalyClient.connection_data(project.repository_storage).merge(features: gitaly_features))
          .and_return(gitaly_info)

        expect(Gitlab::Agent::ConfigurationProject::Rpc::ListAgentConfigFilesRequest).to receive(:new)
          .with(repository: repository, gitaly_info: gitaly_info)
          .and_return(request)

        expect(stub).to receive(:list_agent_config_files)
          .with(request, metadata: { 'authorization' => 'bearer test-token', **feature_flags })
          .and_return(response)
      end

      it { expect(subject).to eq(agent_configurations) }
    end

    describe '#publish_events' do
      let(:topic) { 'test.topic' }
      let(:event) do
        Gitlab::Agent::Event::CloudEvent.new(
          id: 'test-id',
          source: 'test',
          spec_version: '1.0',
          type: 'com.example.test'
        )
      end

      let(:other_event) do
        Gitlab::Agent::Event::CloudEvent.new(
          id: 'other-id',
          source: 'test',
          spec_version: '1.0',
          type: 'com.example.test'
        )
      end

      context 'with one or more events' do
        let(:stub) { instance_double(Gitlab::Agent::EventsPlatform::Rpc::EventsPlatform::Stub) }
        let(:request) { instance_double(Gitlab::Agent::EventsPlatform::Rpc::PublishRequest) }

        before do
          expect(Gitlab::Agent::EventsPlatform::Rpc::EventsPlatform::Stub).to receive(:new)
            .with('example.kas.internal', :this_channel_is_insecure, timeout: client.send(:timeout))
            .and_return(stub)
        end

        it 'wraps a single event in an array before publishing', :aggregate_failures do
          expect(Gitlab::Agent::EventsPlatform::Rpc::PublishRequest).to receive(:new)
            .with(topic: topic, events: [event])
            .and_return(request)

          response = Gitlab::Agent::EventsPlatform::Rpc::PublishResponse.new(message_ids: ['1234567890-0'])

          expect(stub).to receive(:publish)
            .with(request, metadata: { 'authorization' => 'bearer test-token', **feature_flags })
            .and_return(response)

          expect(client.publish_events(topic: topic, events: event)).to eq(['1234567890-0'])
        end

        it 'publishes a batch of events and returns all message IDs', :aggregate_failures do
          expect(Gitlab::Agent::EventsPlatform::Rpc::PublishRequest).to receive(:new)
            .with(topic: topic, events: [event, other_event])
            .and_return(request)

          response = Gitlab::Agent::EventsPlatform::Rpc::PublishResponse.new(
            message_ids: %w[1234567890-0 1234567891-0]
          )

          expect(stub).to receive(:publish)
            .with(request, metadata: { 'authorization' => 'bearer test-token', **feature_flags })
            .and_return(response)

          expect(client.publish_events(topic: topic, events: [event, other_event]))
            .to eq(%w[1234567890-0 1234567891-0])
        end

        it 'propagates gRPC errors from the stub', :aggregate_failures do
          expect(Gitlab::Agent::EventsPlatform::Rpc::PublishRequest).to receive(:new)
            .with(topic: topic, events: [event])
            .and_return(request)

          expect(stub).to receive(:publish)
            .with(request, metadata: { 'authorization' => 'bearer test-token', **feature_flags })
            .and_raise(GRPC::Unavailable.new('relay down'))

          expect { client.publish_events(topic: topic, events: [event]) }
            .to raise_error(GRPC::Unavailable)
        end
      end

      context 'with no events' do
        before do
          expect(Gitlab::Agent::EventsPlatform::Rpc::EventsPlatform::Stub).not_to receive(:new)
          expect(Gitlab::Agent::EventsPlatform::Rpc::PublishRequest).not_to receive(:new)
        end

        it 'returns an empty array and skips the RPC call when events is nil' do
          expect(client.publish_events(topic: topic, events: nil)).to eq([])
        end

        it 'returns an empty array and skips the RPC call when events is an empty array' do
          expect(client.publish_events(topic: topic, events: [])).to eq([])
        end
      end

      context 'when the publish_events_to_relay feature flag is disabled' do
        before do
          stub_feature_flags(publish_events_to_relay: false)

          expect(Gitlab::Agent::EventsPlatform::Rpc::EventsPlatform::Stub).not_to receive(:new)
          expect(Gitlab::Agent::EventsPlatform::Rpc::PublishRequest).not_to receive(:new)
        end

        it 'returns an empty array and skips the RPC call' do
          expect(client.publish_events(topic: topic, events: event)).to eq([])
        end
      end
    end

    describe '#subscribe_events' do
      let(:topic) { 'test.topic' }
      let(:consumer_group) { 'rails-test' }

      # The resilient wrapper reconnects forever, so every test that lets the loop run must arrange
      # for it to terminate (block raise, stop_when, Cancelled, or a permanent error). Tests never
      # sleep for real: the backoff is a stubbed double, or `sleep` is stubbed.

      context 'when the subscribe_events_from_relay feature flag is disabled' do
        before do
          stub_feature_flags(subscribe_events_from_relay: false)
        end

        it 'returns nil and does not subscribe' do
          expect(client).not_to receive(:subscribe_events_single_stream)

          expect(
            client.subscribe_events(topic: topic, consumer_group: consumer_group) { |_event| nil }
          ).to be_nil
        end

        it 'still raises ArgumentError when no block is given' do
          expect do
            client.subscribe_events(topic: topic, consumer_group: consumer_group)
          end.to raise_error(ArgumentError, /block is required/)
        end
      end

      it 'raises ArgumentError when no block is given' do
        expect do
          client.subscribe_events(topic: topic, consumer_group: consumer_group)
        end.to raise_error(ArgumentError, /block is required/)
      end

      describe 'reconnect behavior' do
        let(:backoff) { instance_double(Gitlab::Kas::ExponentialBackoff, next: 0, reset: nil) }

        it 'reconnects when the single-stream helper returns cleanly' do
          allow(client).to receive(:sleep) # non-stable closes back off; keep the test fast
          call_count = 0
          allow(client).to receive(:subscribe_events_single_stream) do
            call_count += 1
            # Simulate a clean stream close by returning; raise on the 3rd attempt to exit the loop.
            raise 'stop after 3 attempts' if call_count >= 3
          end

          expect do
            client.subscribe_events(topic: topic, consumer_group: consumer_group, backoff: backoff) { |_event| nil }
          end.to raise_error('stop after 3 attempts')

          expect(call_count).to eq(3)
        end

        it 'sleeps via the backoff between transient retries' do
          allow(client).to receive(:subscribe_events_single_stream)
            .and_raise(GRPC::Unavailable.new('broker down'))

          sleep_count = 0
          allow(client).to receive(:sleep) do |duration|
            expect(duration).to eq(0)
            sleep_count += 1
            raise 'stop' if sleep_count >= 2 # exit the loop after two retries
          end

          expect do
            client.subscribe_events(topic: topic, consumer_group: consumer_group, backoff: backoff) { |_event| nil }
          end.to raise_error('stop')

          expect(backoff).to have_received(:next).twice
        end

        it 'raises on a permanent gRPC error (InvalidArgument)' do
          allow(client).to receive(:subscribe_events_single_stream)
            .and_raise(GRPC::InvalidArgument.new('bad consumer group'))

          expect do
            client.subscribe_events(topic: topic, consumer_group: consumer_group, backoff: backoff) { |_event| nil }
          end.to raise_error(GRPC::InvalidArgument)
        end

        it 'returns cleanly on Cancelled' do
          allow(client).to receive(:subscribe_events_single_stream)
            .and_raise(GRPC::Cancelled.new('explicit shutdown'))

          expect(
            client.subscribe_events(topic: topic, consumer_group: consumer_group, backoff: backoff) { |_event| nil }
          ).to be_nil
        end

        it 'retries on Unauthenticated (token rotation can self-heal)' do
          call_count = 0
          allow(client).to receive(:subscribe_events_single_stream) do
            call_count += 1
            raise GRPC::Unauthenticated, 'stale token' if call_count == 1
            raise 'stop' if call_count >= 2
          end

          allow(client).to receive(:sleep)

          expect do
            client.subscribe_events(topic: topic, consumer_group: consumer_group, backoff: backoff) { |_event| nil }
          end.to raise_error('stop')

          expect(call_count).to eq(2)
        end

        it 'returns when stop_when becomes truthy between attempts' do
          attempts = 0
          allow(client).to receive(:subscribe_events_single_stream) { attempts += 1 }

          stop_when = -> { attempts >= 2 }

          client.subscribe_events(
            topic: topic, consumer_group: consumer_group, stop_when: stop_when, backoff: backoff
          ) { |_event| nil }

          expect(attempts).to eq(2)
        end

        it 'does not subscribe at all when stop_when is already truthy' do
          expect(client).not_to receive(:subscribe_events_single_stream)

          client.subscribe_events(
            topic: topic, consumer_group: consumer_group, stop_when: -> { true }, backoff: backoff
          ) { |_event| nil }
        end

        it 'propagates a block-raise without retrying' do
          attempts = 0
          allow(client).to receive(:subscribe_events_single_stream) do |&block|
            attempts += 1
            block.call(double('event'))
          end

          expect do
            client.subscribe_events(topic: topic, consumer_group: consumer_group, backoff: backoff) do |_|
              raise 'handler error'
            end
          end.to raise_error('handler error')

          expect(attempts).to eq(1)
        end

        it 'forwards subscribe options through to the single-stream helper' do
          allow(client).to receive(:subscribe_events_single_stream).and_raise('stop')

          expect(client).to receive(:subscribe_events_single_stream).with(
            topic: topic,
            consumer_group: consumer_group,
            event_types: ['com.example.one'],
            deadline: 5.minutes
          )

          expect do
            client.subscribe_events(
              topic: topic,
              consumer_group: consumer_group,
              event_types: ['com.example.one'],
              deadline: 5.minutes,
              backoff: backoff
            ) { |_event| nil }
          end.to raise_error('stop')
        end
      end

      describe 'stable-period backoff reset' do
        let(:backoff) { instance_double(Gitlab::Kas::ExponentialBackoff, next: 0, reset: nil) }

        it 'resets the backoff only after a stream runs longer than the stable period' do
          call_count = 0
          allow(client).to receive(:subscribe_events_single_stream) do
            call_count += 1
            case call_count
            when 1 then travel(1.second) # dies fast: no stable period, no reset
            when 2 then travel((described_class::STABLE_PERIOD_SECONDS + 5).seconds) # stable: reset
            else raise 'stop'
            end
          end

          expect do
            client.subscribe_events(topic: topic, consumer_group: consumer_group, backoff: backoff) { |_event| nil }
          end.to raise_error('stop')

          expect(backoff).to have_received(:reset).once
        end
      end

      describe 'structured logging' do
        let(:backoff) { instance_double(Gitlab::Kas::ExponentialBackoff, next: 0, reset: nil) }
        let(:logger) { instance_double(Gitlab::EventsPlatform::Logger) }

        before do
          allow(Gitlab::EventsPlatform::Logger).to receive(:build).and_return(logger)
          allow(logger).to receive(:info)
          allow(logger).to receive(:warn)
          allow(logger).to receive(:error)
        end

        it 'logs an info entry when a stable stream closes cleanly' do
          call_count = 0
          allow(client).to receive(:subscribe_events_single_stream) do
            call_count += 1
            travel((described_class::STABLE_PERIOD_SECONDS + 5).seconds) if call_count == 1
            raise 'stop' if call_count >= 2
          end

          expect do
            client.subscribe_events(topic: topic, consumer_group: consumer_group, backoff: backoff) { |_event| nil }
          end.to raise_error('stop')

          expect(logger).to have_received(:info).with(
            hash_including(message: 'subscribe_events stream closed cleanly; reconnecting')
          )
        end

        it 'logs a warning and backs off when a stream closes before the stable period' do
          allow(client).to receive(:sleep)
          call_count = 0
          allow(client).to receive(:subscribe_events_single_stream) do
            call_count += 1
            # Each close is immediate (non-stable); raise on the 2nd to exit the loop.
            raise 'stop' if call_count >= 2
          end

          expect do
            client.subscribe_events(topic: topic, consumer_group: consumer_group, backoff: backoff) { |_event| nil }
          end.to raise_error('stop')

          expect(logger).to have_received(:warn).with(
            hash_including(
              message: 'subscribe_events stream closed before stable period; backing off',
              consecutive_failures: 1
            )
          )
          expect(backoff).to have_received(:next)
        end

        it 'logs a warning with the consecutive failure count on a transient error' do
          allow(client).to receive(:subscribe_events_single_stream)
            .and_raise(GRPC::Unavailable.new('broker down'))

          sleep_count = 0
          allow(client).to receive(:sleep) do
            sleep_count += 1
            raise 'stop' if sleep_count >= 2
          end

          expect do
            client.subscribe_events(topic: topic, consumer_group: consumer_group, backoff: backoff) { |_event| nil }
          end.to raise_error('stop')

          expect(logger).to have_received(:warn).with(
            hash_including(
              message: 'subscribe_events transient error; retrying',
              consecutive_failures: 1
            )
          )
        end

        it 'logs an error on a permanent gRPC error' do
          allow(client).to receive(:subscribe_events_single_stream)
            .and_raise(GRPC::InvalidArgument.new('bad consumer group'))

          expect do
            client.subscribe_events(topic: topic, consumer_group: consumer_group, backoff: backoff) { |_event| nil }
          end.to raise_error(GRPC::InvalidArgument)

          expect(logger).to have_received(:error).with(
            hash_including(message: 'subscribe_events permanent error')
          )
        end
      end
    end

    describe '#subscribe_events_single_stream (private)' do
      let(:topic) { 'test.topic' }
      let(:consumer_group) { 'rails-test' }
      let(:stub) { instance_double(Gitlab::Agent::EventsPlatform::Rpc::EventsPlatform::Stub) }
      let(:expected_metadata) { { 'authorization' => 'bearer test-token', **feature_flags } }

      let(:event_one) do
        Gitlab::Agent::Event::CloudEvent.new(
          id: 'event-1', source: 'test', spec_version: '1.0', type: 'com.example.one'
        )
      end

      let(:event_two) do
        Gitlab::Agent::Event::CloudEvent.new(
          id: 'event-2', source: 'test', spec_version: '1.0', type: 'com.example.two'
        )
      end

      let(:server_responses) do
        [
          Gitlab::Agent::EventsPlatform::Rpc::SubscribeResponse.new(
            message_id: '1747840000-0', event: event_one
          ),
          Gitlab::Agent::EventsPlatform::Rpc::SubscribeResponse.new(
            message_id: '1747840001-0', event: event_two
          )
        ]
      end

      before do
        allow(client).to receive(:stub_for).with(:events_platform).and_return(stub)
      end

      # Captures the requests the client sends back so we can assert on the SubscribeConfig and Acks
      # in order. Drains the first request (SubscribeConfig) eagerly so it's captured even when no
      # server responses are produced; subsequent requests (Acks) are pulled after each response to
      # preserve the Config -> Response -> Ack -> Response -> Ack interleaving that exercises the
      # per-event-ack contract.
      def capture_subscribe(server_responses:, captured:)
        allow(stub).to receive(:subscribe) do |requests, **_kwargs|
          captured << requests.next

          Enumerator.new do |y|
            server_responses.each do |resp|
              y << resp
              captured << requests.next
            end
          end
        end
      end

      def subscribe_single_stream(event_types: [], deadline: described_class::DEFAULT_SUBSCRIBE_DEADLINE, &block)
        client.send(
          :subscribe_events_single_stream,
          topic: topic,
          consumer_group: consumer_group,
          event_types: event_types,
          deadline: deadline,
          &block
        )
      end

      it 'sends SubscribeConfig as the first request' do
        captured = []
        capture_subscribe(server_responses: [], captured: captured)

        subscribe_single_stream { |_event| nil }

        expect(captured.first.config).to have_attributes(
          topic: topic,
          consumer_group: consumer_group,
          event_types: []
        )
      end

      it 'sends SubscribeConfig exactly once across the stream lifetime', :aggregate_failures do
        captured = []
        capture_subscribe(server_responses: server_responses, captured: captured)

        subscribe_single_stream { |_event| nil }

        # The first request is the config; everything after must be an ack, never another config.
        configs = captured.select { |req| req.request == :config }
        expect(configs.length).to eq(1)
        expect(captured.first.request).to eq(:config)
        expect(captured.drop(1).map(&:request)).to all(eq(:ack))
      end

      it 'closes the request stream after the response stream ends' do
        captured_requests_enum = nil
        allow(stub).to receive(:subscribe) do |requests, **_kwargs|
          captured_requests_enum = requests
          # Drain the config message so the client moves into the response loop.
          requests.next
          # Empty response stream - the server immediately closes.
          Enumerator.new { |_y| nil }
        end

        subscribe_single_stream { |_event| nil }

        # The `ensure` block pushes nil into the ack queue, which breaks the request enumerator's
        # internal loop. Advancing the enumerator one more time should raise StopIteration.
        expect { captured_requests_enum.next }.to raise_error(StopIteration)
      end

      it 'yields each CloudEvent from the server' do
        capture_subscribe(server_responses: server_responses, captured: [])

        received = []
        subscribe_single_stream do |event|
          received << event
        end

        expect(received).to eq([event_one, event_two])
      end

      it 'acknowledges each event after the block returns successfully' do
        captured = []
        capture_subscribe(server_responses: server_responses, captured: captured)

        subscribe_single_stream { |_event| nil }

        # captured = [config, ack(event_one), ack(event_two)]
        acks = captured.drop(1).map { |req| req.ack.message_ids.to_a }
        expect(acks).to eq([['1747840000-0'], ['1747840001-0']])
      end

      it 'does not acknowledge an event if the block raises' do
        captured = []
        capture_subscribe(server_responses: server_responses, captured: captured)

        expect do
          subscribe_single_stream do |_|
            raise 'boom'
          end
        end.to raise_error(RuntimeError, 'boom')

        # captured = [config] - no ack was sent before the raise
        expect(captured.length).to eq(1)
      end

      it 'forwards event_types as a server-side filter' do
        captured = []
        capture_subscribe(server_responses: [], captured: captured)

        subscribe_single_stream(event_types: ['com.example.one', 'com.example.two']) { |_event| nil }

        expect(captured.first.config.event_types.to_a).to eq(
          ['com.example.one', 'com.example.two']
        )
      end

      it 'passes the auth metadata and a seconds-from-epoch deadline to the stub', :aggregate_failures do
        captured_deadline = nil
        allow(stub).to receive(:subscribe) do |requests, deadline:, **_kwargs|
          captured_deadline = deadline
          requests.next
          Enumerator.new { |_y| nil }
        end

        # The deadline is anchored to the real system clock (Process::CLOCK_REALTIME), not Timecop,
        # because that is the clock the gRPC c-core reads. Bound the expected value without freezing
        # time.
        before_call = Process.clock_gettime(Process::CLOCK_REALTIME)
        subscribe_single_stream { |_event| nil }
        after_call = Process.clock_gettime(Process::CLOCK_REALTIME)

        expect(stub).to have_received(:subscribe).with(
          kind_of(Enumerator),
          deadline: kind_of(Numeric),
          metadata: expected_metadata
        )

        # Must be seconds-from-epoch, NOT an ActiveSupport::TimeWithZone (gRPC rejects the latter
        # with "bad input: (time)->c_timeval").
        expect(captured_deadline).not_to be_a(ActiveSupport::TimeWithZone)
        expect(captured_deadline).to be_between(
          before_call + described_class::DEFAULT_SUBSCRIBE_DEADLINE,
          after_call + described_class::DEFAULT_SUBSCRIBE_DEADLINE
        )
      end

      it 'propagates gRPC errors from the stub' do
        allow(stub).to receive(:subscribe).and_raise(GRPC::Unavailable.new('relay down'))

        expect do
          subscribe_single_stream { |_event| nil }
        end.to raise_error(GRPC::Unavailable)
      end

      # Regression: gRPC's bidi machinery drains the request enumerator in a separate (write) thread
      # and joins it from inside the response iteration when the stream ends. If the request
      # enumerator blocked forever on the ack queue, that join - and therefore the whole call - would
      # deadlock on an idle stream. This mimics that contract: a background thread fully drains the
      # request enumerator, and the response `each` only returns once that thread has finished.
      it 'does not deadlock on an idle stream and returns at the deadline' do
        allow(stub).to receive(:subscribe) do |requests, **_kwargs|
          drain_thread = Thread.new do
            # Faithfully drain the request enumerator the way the gRPC write loop does, until it
            # terminates on its own (StopIteration).
            requests.to_a
          end

          Enumerator.new do |_y|
            # Idle stream: no responses are ever produced. gRPC joins the write thread before the
            # response iteration returns, so we must wait for the enumerator to self-terminate.
            drain_thread.join
          end
        end

        # A short deadline keeps the test fast; the enumerator must tear itself down shortly after.
        expect do
          Timeout.timeout(15) do
            subscribe_single_stream(deadline: 2.seconds) { |_event| nil }
          end
        end.not_to raise_error
      end
    end

    describe '#send_git_push_event' do
      let(:stub) { instance_double(Gitlab::Agent::Notifications::Rpc::Notifications::Stub) }
      let(:request) { instance_double(Gitlab::Agent::Notifications::Rpc::GitPushEventRequest) }
      let(:event_param) { instance_double(Gitlab::Agent::Event::GitPushEvent) }
      let(:project_param) { instance_double(Gitlab::Agent::Event::Project) }
      let(:response) { double(Gitlab::Agent::Notifications::Rpc::GitPushEventResponse) }

      subject { client.send_git_push_event(project: project) }

      before do
        expect(Gitlab::Agent::Notifications::Rpc::Notifications::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: client.send(:timeout))
          .and_return(stub)

        expect(Gitlab::Agent::Event::Project).to receive(:new)
          .with(id: project.id, full_path: project.full_path)
          .and_return(project_param)

        expect(Gitlab::Agent::Event::GitPushEvent).to receive(:new)
          .with(project: project_param)
          .and_return(event_param)

        expect(Gitlab::Agent::Notifications::Rpc::GitPushEventRequest).to receive(:new)
          .with(event: event_param)
          .and_return(request)

        expect(stub).to receive(:git_push_event)
          .with(request, metadata: { 'authorization' => 'bearer test-token', **feature_flags })
          .and_return(response)
      end

      it { expect(subject).to eq(response) }
    end

    describe 'with grpcs' do
      let(:stub) { instance_double(Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub) }
      let(:credentials) { instance_double(GRPC::Core::ChannelCredentials) }
      let(:kas_url) { 'grpcs://example.kas.internal' }

      it 'uses a ChannelCredentials object with the correct certificates' do
        expect(GRPC::Core::ChannelCredentials).to receive(:new)
          .with(Gitlab::X509::Certificate.ca_certs_bundle)
          .and_return(credentials)

        expect(Gitlab::Agent::ConfigurationProject::Rpc::ConfigurationProject::Stub).to receive(:new)
          .with('example.kas.internal', credentials, timeout: client.send(:timeout))
          .and_return(stub)

        allow(stub).to receive(:list_agent_config_files)
          .and_return(double(config_files: []))

        client.list_agent_config_files(project: project)
      end
    end

    describe '#get_environment_template' do
      let(:stub) { instance_double(Gitlab::Agent::ManagedResources::Rpc::Provisioner::Stub) }
      let(:request) { instance_double(Gitlab::Agent::ManagedResources::Rpc::GetEnvironmentTemplateRequest) }
      let(:template) { double("templates", name: "test-template", data: "{}") }
      let(:response) { double(Gitlab::Agent::ManagedResources::Rpc::GetEnvironmentTemplateResponse, template: template) }
      let(:template_name) { 'default' }

      subject { client.get_environment_template(agent: agent, template_name: template_name) }

      before do
        expect(Gitlab::Agent::ManagedResources::Rpc::Provisioner::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: client.send(:timeout))
          .and_return(stub)

        expect(Gitlab::Agent::ManagedResources::Rpc::GetEnvironmentTemplateRequest).to receive(:new)
          .with(
            template_name: template_name,
            agent_name: agent.name,
            gitaly_info: instance_of(Gitlab::Agent::Entity::GitalyInfo),
            gitaly_repository: instance_of(Gitlab::Agent::Entity::GitalyRepository),
            default_branch: project.default_branch_or_main)
          .and_return(request)

        expect(stub).to receive(:get_environment_template)
          .with(request, metadata: { 'authorization' => 'bearer test-token', **feature_flags })
          .and_return(response)
      end

      it { expect(subject).to eq(template) }
    end

    describe '#get_default_environment_template' do
      let(:stub) { instance_double(Gitlab::Agent::ManagedResources::Rpc::Provisioner::Stub) }
      let(:request) { instance_double(Gitlab::Agent::ManagedResources::Rpc::GetDefaultEnvironmentTemplateRequest) }
      let(:template) { double("templates", name: "test-template", data: "{}") }
      let(:response) { double(Gitlab::Agent::ManagedResources::Rpc::GetDefaultEnvironmentTemplateResponse, template: template) }

      subject { client.get_default_environment_template }

      before do
        expect(Gitlab::Agent::ManagedResources::Rpc::Provisioner::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: client.send(:timeout))
          .and_return(stub)

        expect(Gitlab::Agent::ManagedResources::Rpc::GetDefaultEnvironmentTemplateRequest).to receive(:new)
          .and_return(request)

        expect(stub).to receive(:get_default_environment_template)
          .with(request, metadata: { 'authorization' => 'bearer test-token', **feature_flags })
          .and_return(response)
      end

      it { expect(subject).to eq(template) }
    end

    describe '#render_environment_template' do
      let_it_be(:deployment_project) { create(:project, path: "abc_ABC") }
      let_it_be(:environment) { create(:environment, project: deployment_project, cluster_agent: agent) }
      let_it_be(:user) { create(:user) }
      let_it_be(:build) { create(:ci_build, project: deployment_project, user: user) }
      let(:stub) { instance_double(Gitlab::Agent::ManagedResources::Rpc::Provisioner::Stub) }
      let(:request) { instance_double(Gitlab::Agent::ManagedResources::Rpc::RenderEnvironmentTemplateRequest) }
      let(:template) { double("templates", name: "test-template", data: "{}") }
      let(:response) { double(Gitlab::Agent::ManagedResources::Rpc::RenderEnvironmentTemplateResponse, template: template) }

      subject { client.render_environment_template(template: template, environment: environment, build: build) }

      before do
        expect(Gitlab::Agent::ManagedResources::Rpc::Provisioner::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: client.send(:timeout))
          .and_return(stub)

        expect(Gitlab::Agent::ManagedResources::Rpc::RenderEnvironmentTemplateRequest).to receive(:new)
          .with(
            template: Gitlab::Agent::ManagedResources::EnvironmentTemplate.new(
              name: template.name,
              data: template.data),
            info: an_object_having_attributes(
              class: Gitlab::Agent::ManagedResources::TemplatingInfo,
              agent: Gitlab::Agent::ManagedResources::Agent.new(
                id: agent.id,
                name: agent.name,
                url: Gitlab::Routing.url_helpers.project_cluster_agent_url(project, agent.name)),
              legacy_namespace: "abc-abc-#{deployment_project.id}-#{environment.slug}"))
          .and_return(request)

        expect(stub).to receive(:render_environment_template)
          .with(request, metadata: { 'authorization' => 'bearer test-token', **feature_flags })
          .and_return(response)
      end

      it { expect(subject).to eq(template) }
    end

    describe '#ensure_environment' do
      let_it_be(:deployment_project) { create(:project, path: "abc_ABC") }
      let_it_be(:environment) { create(:environment, project: deployment_project, cluster_agent: agent) }
      let_it_be(:user) { create(:user) }
      let_it_be(:build) { create(:ci_build, project: deployment_project, user: user) }
      let(:stub) { instance_double(Gitlab::Agent::ManagedResources::Rpc::Provisioner::Stub) }
      let(:request) { instance_double(Gitlab::Agent::ManagedResources::Rpc::EnsureEnvironmentRequest) }
      let(:template) { double("templates", name: "test-template", data: "{}") }
      let(:response) { double(Gitlab::Agent::ManagedResources::Rpc::EnsureEnvironmentResponse) }

      subject { client.ensure_environment(template: template, environment: environment, build: build) }

      before do
        expect(Gitlab::Agent::ManagedResources::Rpc::Provisioner::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: client.send(:timeout))
          .and_return(stub)

        expect(Gitlab::Agent::ManagedResources::Rpc::EnsureEnvironmentRequest).to receive(:new)
          .with(
            template: Gitlab::Agent::ManagedResources::RenderedEnvironmentTemplate.new(
              name: template.name,
              data: template.data),
            info: an_object_having_attributes(
              class: Gitlab::Agent::ManagedResources::TemplatingInfo,
              agent: Gitlab::Agent::ManagedResources::Agent.new(
                id: agent.id,
                name: agent.name,
                url: Gitlab::Routing.url_helpers.project_cluster_agent_url(project, agent.name)),
              legacy_namespace: "abc-abc-#{deployment_project.id}-#{environment.slug}"))
          .and_return(request)

        expect(stub).to receive(:ensure_environment)
          .with(request, metadata: { 'authorization' => 'bearer test-token', **feature_flags })
          .and_return(response)
      end

      it { expect(subject).to eq(response) }
    end

    describe '#delete_environment' do
      let_it_be(:managed_resource) { create(:managed_resource) }

      let(:stub) { instance_double(Gitlab::Agent::ManagedResources::Rpc::Provisioner::Stub) }
      let(:request) { instance_double(Gitlab::Agent::ManagedResources::Rpc::DeleteEnvironmentRequest) }
      let(:response) { double(Gitlab::Agent::ManagedResources::Rpc::DeleteEnvironmentResponse) }

      subject { client.delete_environment(managed_resource: managed_resource) }

      before do
        expect(Gitlab::Agent::ManagedResources::Rpc::Provisioner::Stub).to receive(:new)
          .with('example.kas.internal', :this_channel_is_insecure, timeout: client.send(:timeout))
          .and_return(stub)

        expect(Gitlab::Agent::ManagedResources::Rpc::DeleteEnvironmentRequest).to receive(:new)
          .with(
            agent_id: managed_resource.cluster_agent_id,
            project_id: managed_resource.project_id,
            environment_slug: managed_resource.environment.slug,
            objects: managed_resource.tracked_objects
          ).and_return(request)

        expect(stub).to receive(:delete_environment)
          .with(request, metadata: { 'authorization' => 'bearer test-token', **feature_flags })
          .and_return(response)
      end

      it { expect(subject).to eq(response) }
    end
  end
end
