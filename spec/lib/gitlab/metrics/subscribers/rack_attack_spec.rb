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
        ::Gitlab::Instrumentation::Storage[:rack_attack_instrumentation] = {
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
            fullpath: '/api/v4/internal/authorized_keys',
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
                fullpath: '/api/v4/internal/authorized_keys',
                env: {
                  'rack.attack.match_type' => match_type,
                  'rack.attack.matched' => 'throttle_authenticated_api',
                  'rack.attack.match_discriminator' => "user:#{non_existing_record_id}"
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
                fullpath: '/api/v4/internal/authorized_keys',
                env: {
                  'rack.attack.match_type' => match_type,
                  'rack.attack.matched' => 'throttle_authenticated_api',
                  'rack.attack.match_discriminator' => "user:#{user.id}"
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
                fullpath: '/api/v4/internal/authorized_keys',
                env: {
                  'rack.attack.match_type' => match_type,
                  'rack.attack.matched' => 'throttle_authenticated_api',
                  'rack.attack.match_discriminator' => "deploy_token:#{deploy_token.id}"
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

  describe '#throttle' do
    let(:match_type) { :throttle }
    let(:expected_status) { 429 }
    let(:event_name) { 'throttle.rack_attack' }

    it_behaves_like 'log into auth logger'
  end

  describe '#blocklist' do
    let(:match_type) { :blocklist }
    let(:expected_status) { 403 }
    let(:event_name) { 'blocklist.rack_attack' }

    it_behaves_like 'log into auth logger'
  end

  describe '#track' do
    let(:match_type) { :track }
    let(:expected_status) { nil }
    let(:event_name) { 'track.rack_attack' }

    it_behaves_like 'log into auth logger'
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
      expect(::Gitlab::Instrumentation::Storage[:instrumentation_throttle_safelist]).to eql('throttle_unauthenticated')
    end
  end
end
