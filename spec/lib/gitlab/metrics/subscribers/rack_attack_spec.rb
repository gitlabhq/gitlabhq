# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Subscribers::RackAttack, :request_store do
  let(:subscriber) { described_class.new }

  describe '.payload' do
    context 'when the request store is empty' do
      it 'returns empty data' do
        expect(described_class.payload).to eql(
          rack_attack_redis_count: 0,
          rack_attack_redis_duration_s: 0.0
        )
      end
    end

    context 'when the request store already has data' do
      before do
        Gitlab::SafeRequestStore[:rack_attack_instrumentation] = {
          rack_attack_redis_count: 10,
          rack_attack_redis_duration_s: 9.0
        }
      end

      it 'returns the accumulated data' do
        expect(described_class.payload).to eql(
          rack_attack_redis_count: 10,
          rack_attack_redis_duration_s: 9.0
        )
      end
    end
  end

  shared_examples 'log into auth logger' do
    context 'when matched throttle does not require user information' do
      let(:event) do
        ActiveSupport::Notifications::Event.new(
          event_name, Time.current, Time.current + 2.seconds, '1', request: double(
            :request,
            ip: '1.2.3.4',
            request_method: 'GET',
            path: '/api/v4/internal/authorized_keys',
            GET: {},
            env: {
              'rack.attack.match_type' => match_type,
              'rack.attack.matched' => 'throttle_unauthenticated'
            }
          )
        )
      end

      it 'logs request information' do
        expect(Gitlab::AuthLogger).to receive(:error) do |arguments|
          expect(arguments).to include(
            message: 'Rack_Attack',
            env: match_type,
            remote_ip: '1.2.3.4',
            request_method: 'GET',
            path: '/api/v4/internal/authorized_keys',
            matched: 'throttle_unauthenticated'
          )

          if expected_status
            expect(arguments).to include(status: expected_status)
          else
            expect(arguments).not_to have_key(:status)
          end
        end

        subscriber.send(match_type, event)
      end

      context 'when event contains parameters with sensitive info' do
        let(:event) do
          ActiveSupport::Notifications::Event.new(
            event_name, Time.current, Time.current + 2.seconds, '1', request: double(
              :request,
              ip: '1.2.3.4',
              request_method: 'GET',
              path: '/api/v4/internal/authorized_keys',
              GET: {
                non_sensitive_query_param: 'non_sensitive_info',
                password: 's3cr3tp4ssw0rd'
              },
              env: {
                'rack.attack.match_type' => match_type,
                'rack.attack.matched' => 'throttle_unauthenticated',
                'rack.attack.match_data' => { limit: 1, period: 10 }
              }
            )
          )
        end

        it 'logs request information' do
          expect(Gitlab::AuthLogger).to receive(:error) do |arguments|
            expect(arguments).to include(
              message: 'Rack_Attack',
              env: match_type,
              remote_ip: '1.2.3.4',
              request_method: 'GET',
              path: '/api/v4/internal/authorized_keys?non_sensitive_query_param=' \
                'non_sensitive_info&password=%5BFILTERED%5D',
              matched: 'throttle_unauthenticated'
            )

            if expected_status
              expect(arguments).to include(status: expected_status)
            else
              expect(arguments).not_to have_key(:status)
            end
          end

          subscriber.send(match_type, event)
        end
      end
    end

    context 'matching user or deploy token authenticated information' do
      context 'when matching for user' do
        context 'when user not found' do
          let(:event) do
            ActiveSupport::Notifications::Event.new(
              event_name, Time.current, Time.current + 2.seconds, '1', request: double(
                :request,
                ip: '1.2.3.4',
                request_method: 'GET',
                path: '/api/v4/internal/authorized_keys',
                GET: {},
                env: {
                  'rack.attack.match_type' => match_type,
                  'rack.attack.matched' => 'throttle_authenticated_api',
                  'rack.attack.match_discriminator' => "user:#{non_existing_record_id}",
                  'rack.attack.match_data' => { limit: 1, period: 10 }
                }
              )
            )
          end

          it 'logs request information and user id' do
            expect(Gitlab::AuthLogger).to receive(:error) do |arguments|
              expect(arguments).to include(
                message: 'Rack_Attack',
                env: match_type,
                remote_ip: '1.2.3.4',
                request_method: 'GET',
                path: '/api/v4/internal/authorized_keys',
                matched: 'throttle_authenticated_api',
                user_id: non_existing_record_id
              )

              if expected_status
                expect(arguments).to include(status: expected_status)
              else
                expect(arguments).not_to have_key(:status)
              end
            end

            subscriber.send(match_type, event)
          end
        end

        context 'when user found' do
          let(:user) { create(:user) }
          let(:event) do
            ActiveSupport::Notifications::Event.new(
              event_name, Time.current, Time.current + 2.seconds, '1', request: double(
                :request,
                ip: '1.2.3.4',
                request_method: 'GET',
                path: '/api/v4/internal/authorized_keys',
                GET: {},
                env: {
                  'rack.attack.match_type' => match_type,
                  'rack.attack.matched' => 'throttle_authenticated_api',
                  'rack.attack.match_discriminator' => "user:#{user.id}",
                  'rack.attack.match_data' => { limit: 1, period: 10 }
                }
              )
            )
          end

          it 'logs request information and user meta' do
            expect(Gitlab::AuthLogger).to receive(:error) do |arguments|
              expect(arguments).to include(
                message: 'Rack_Attack',
                env: match_type,
                remote_ip: '1.2.3.4',
                request_method: 'GET',
                path: '/api/v4/internal/authorized_keys',
                matched: 'throttle_authenticated_api',
                user_id: user.id,
                'meta.user' => user.username
              )

              if expected_status
                expect(arguments).to include(status: expected_status)
              else
                expect(arguments).not_to have_key(:status)
              end
            end

            subscriber.send(match_type, event)
          end
        end
      end

      context 'when matching for deploy token' do
        context 'when deploy token found' do
          let(:deploy_token) { create(:deploy_token) }
          let(:event) do
            ActiveSupport::Notifications::Event.new(
              event_name, Time.current, Time.current + 2.seconds, '1', request: double(
                :request,
                ip: '1.2.3.4',
                request_method: 'GET',
                path: '/api/v4/internal/authorized_keys',
                GET: {},
                env: {
                  'rack.attack.match_type' => match_type,
                  'rack.attack.matched' => 'throttle_authenticated_api',
                  'rack.attack.match_discriminator' => "deploy_token:#{deploy_token.id}",
                  'rack.attack.match_data' => { limit: 1, period: 10 }
                }
              )
            )
          end

          it 'logs request information and user meta' do
            expect(Gitlab::AuthLogger).to receive(:error) do |arguments|
              expect(arguments).to include(
                message: 'Rack_Attack',
                env: match_type,
                remote_ip: '1.2.3.4',
                request_method: 'GET',
                path: '/api/v4/internal/authorized_keys',
                matched: 'throttle_authenticated_api',
                deploy_token_id: deploy_token.id
              )

              if expected_status
                expect(arguments).to include(status: expected_status)
              else
                expect(arguments).not_to have_key(:status)
              end
            end

            subscriber.send(match_type, event)
          end
        end
      end
    end
  end

  shared_examples 'emit metric' do |use_gauge: false|
    let(:event) do
      ActiveSupport::Notifications::Event.new(
        event_name, Time.current, Time.current + 2.seconds, '1', request: double(
          :request,
          ip: '1.2.3.4',
          request_method: 'GET',
          path: '/api/v4/internal/authorized_keys',
          GET: {},
          env: {
            'rack.attack.match_type' => match_type,
            'rack.attack.matched' => 'throttle_unauthenticated',
            'rack.attack.match_data' => { limit: 1, period: 10 }
          }
        )
      )
    end

    let(:event_counter) { instance_double(Prometheus::Client::Counter) }
    let(:throttle_limit) { instance_double(Prometheus::Client::Gauge) }
    let(:throttle_period) { instance_double(Prometheus::Client::Gauge) }

    it 'memoizes and increments counter' do
      expect(Gitlab::Metrics).to receive(:counter)
          .with(:gitlab_rack_attack_events_total, anything, anything).once.and_return(event_counter)

      expect(event_counter).to receive(:increment)
        .twice
        .with({ event_type: match_type.to_s, event_name: 'throttle_unauthenticated' })

      subscriber.send(match_type, event)
      subscriber.send(match_type, event)
    end

    context 'incomplete rack env' do
      let(:event) do
        ActiveSupport::Notifications::Event.new(
          event_name, Time.current, Time.current + 2.seconds, '1', request: double(
            :request,
            ip: '1.2.3.4',
            request_method: 'GET',
            path: '/api/v4/internal/authorized_keys',
            GET: {},
            env: {
              # omit rack.attack.matched and period in rack.attack.match_data
              'rack.attack.match_type' => match_type,
              'rack.attack.match_data' => { limit: 1 }
            }
          )
        )
      end

      it 'emits metric safely' do
        expect(Gitlab::Metrics).to receive(:counter)
          .with(:gitlab_rack_attack_events_total, anything, anything).once.and_return(event_counter)

        expect(event_counter).to receive(:increment)
          .with({ event_type: match_type.to_s, event_name: '' })

        subscriber.send(match_type, event)
      end

      it 'sets gauge where possible', if: use_gauge do
        expect(Gitlab::Metrics).to receive(:gauge)
          .with(:gitlab_rack_attack_throttle_limit, anything, anything).once.and_return(throttle_limit)

        expect(Gitlab::Metrics).not_to receive(:gauge)
            .with(:gitlab_rack_attack_throttle_period_seconds, anything, anything)

        expect(throttle_limit).to receive(:set)
          .with({ event_name: '' }, 1)

        subscriber.send(match_type, event)
      end
    end

    it 'sets gauge if throttle', if: use_gauge do
      expect(Gitlab::Metrics).to receive(:gauge)
          .with(:gitlab_rack_attack_throttle_limit, anything, anything).once.and_return(throttle_limit)

      expect(Gitlab::Metrics).to receive(:gauge)
          .with(:gitlab_rack_attack_throttle_period_seconds, anything, anything).once.and_return(throttle_period)

      expect(throttle_limit).to receive(:set)
        .twice
        .with({ event_name: 'throttle_unauthenticated' }, 1)

      expect(throttle_period).to receive(:set)
        .twice
        .with({ event_name: 'throttle_unauthenticated' }, 10)

      subscriber.send(match_type, event)
      subscriber.send(match_type, event)
    end

    it 'skips setting gauge if not throttle', if: !use_gauge do
      expect(Gitlab::Metrics).not_to receive(:gauge)

      subscriber.send(match_type, event)
      subscriber.send(match_type, event)
    end
  end

  describe '#throttle' do
    let(:match_type) { :throttle }
    let(:expected_status) { 429 }
    let(:event_name) { 'throttle.rack_attack' }

    it_behaves_like 'log into auth logger'
    it_behaves_like 'emit metric', use_gauge: true
  end

  describe '#blocklist' do
    let(:match_type) { :blocklist }
    let(:expected_status) { 403 }
    let(:event_name) { 'blocklist.rack_attack' }

    it_behaves_like 'log into auth logger'
    it_behaves_like 'emit metric'
  end

  describe '#track' do
    let(:match_type) { :track }
    let(:expected_status) { nil }
    let(:event_name) { 'track.rack_attack' }

    it_behaves_like 'log into auth logger'
    it_behaves_like 'emit metric'
  end

  describe '#safelist' do
    let(:event) do
      ActiveSupport::Notifications::Event.new(
        'safelist.rack_attack', Time.current, Time.current + 2.seconds, '1', request: double(
          :request,
          env: {
            'rack.attack.matched' => 'throttle_unauthenticated'
          }
        )
      )
    end

    it 'adds the matched name to safe request store' do
      subscriber.safelist(event)
      expect(Gitlab::SafeRequestStore[:instrumentation_throttle_safelist]).to eql('throttle_unauthenticated')
    end
  end
end
