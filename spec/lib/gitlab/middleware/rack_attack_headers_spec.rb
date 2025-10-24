# frozen_string_literal: true

require 'spec_helper'
require 'rack'

RSpec.describe Gitlab::Middleware::RackAttackHeaders, feature_category: :rate_limiting do
  let(:app) { instance_double(Rack::Builder) }
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }
  let(:status) { 200 }
  let(:headers) { {} }
  let(:body) { ['OK'] }

  before do
    allow(app).to receive(:call).with(env).and_return([status, headers, body])
  end

  describe '#call' do
    context 'when feature flag is disabled' do
      let(:env) do
        {
          'rack.attack.throttle_data' => {
            'throttle_unauthenticated_api' => {
              discriminator: '127.0.0.1',
              count: 5,
              period: 60,
              limit: 10,
              epoch_time: Time.now.to_i
            }
          }
        }
      end

      before do
        stub_feature_flags(rate_limiting_headers_for_unthrottled_requests: false)
      end

      it 'does not add rate limit headers' do
        result_status, result_headers, result_body = middleware.call(env)

        expect(result_status).to eq(200)
        expect(result_headers).to be_empty
        expect(result_body).to eq(['OK'])
      end
    end

    context 'when no throttle data is present' do
      it 'returns the response without adding headers' do
        result_status, result_headers, result_body = middleware.call(env)

        expect(result_status).to eq(200)
        expect(result_headers).to be_empty
        expect(result_body).to eq(['OK'])
      end
    end

    context 'when request was already throttled (429)' do
      let(:status) { 429 }
      let(:env) do
        {
          'rack.attack.throttle_data' => {
            'throttle_unauthenticated_api' => {
              discriminator: '127.0.0.1',
              count: 12,
              period: 60,
              limit: 10,
              epoch_time: Time.now.to_i
            }
          },
          'rack.attack.matched' => 'throttle_unauthenticated_api'
        }
      end

      it 'does not add headers (already added by throttled_responder)' do
        result_status, result_headers, _result_body = middleware.call(env)

        expect(result_status).to eq(429)
        expect(result_headers).to be_empty
      end
    end

    context 'when throttle data is present for a non-throttled request' do
      let(:epoch_time) { Time.now.to_i }
      let(:env) do
        {
          'rack.attack.throttle_data' => {
            'throttle_unauthenticated_api' => {
              discriminator: '127.0.0.1',
              count: 5,
              period: 60,
              limit: 10,
              epoch_time: epoch_time
            }
          }
        }
      end

      it 'adds rate limit headers to the response' do
        result_status, result_headers, result_body = middleware.call(env)

        expect(result_status).to eq(200)
        expect(result_body).to eq(['OK'])
        expect(result_headers).to include(
          'RateLimit-Name' => 'throttle_unauthenticated_api',
          'RateLimit-Limit' => '10',
          'RateLimit-Observed' => '5',
          'RateLimit-Remaining' => '5'
        )
        expect(result_headers).to have_key('RateLimit-Reset')
        expect(result_headers).not_to have_key('RateLimit-ResetTime')
        expect(result_headers).not_to have_key('Retry-After')
      end

      it 'preserves existing status and response headers' do
        headers['X-Custom-Header'] = 'custom-value'

        result_status, result_headers, _result_body = middleware.call(env)

        expect(result_status).to eq(200)
        expect(result_headers['X-Custom-Header']).to eq('custom-value')
        expect(result_headers).to have_key('RateLimit-Limit')
      end

      it 'calculates correct remaining count' do
        _result_status, result_headers, _result_body = middleware.call(env)

        expect(result_headers['RateLimit-Remaining']).to eq('5')
      end

      context 'when observed count exceeds limit' do
        let(:env) do
          {
            'rack.attack.throttle_data' => {
              'throttle_unauthenticated_api' => {
                discriminator: '127.0.0.1',
                count: 12,
                period: 60,
                limit: 10,
                epoch_time: epoch_time
              }
            }
          }
        end

        it 'sets remaining to 0' do
          _result_status, result_headers, _result_body = middleware.call(env)

          expect(result_headers['RateLimit-Remaining']).to eq('0')
        end
      end

      context 'when period is different from 60 seconds' do
        let(:env) do
          {
            'rack.attack.throttle_data' => {
              'throttle_authenticated_web' => {
                discriminator: '127.0.0.1',
                count: 50,
                period: 120,
                limit: 100,
                epoch_time: epoch_time
              }
            }
          }
        end

        it 'normalizes limit to 60-second window' do
          _result_status, result_headers, _result_body = middleware.call(env)

          # 100 requests per 120 seconds = 50 requests per 60 seconds (rounded up)
          expect(result_headers['RateLimit-Limit']).to eq('50')
          expect(result_headers['RateLimit-Observed']).to eq('50')
          expect(result_headers['RateLimit-Remaining']).to eq('50')
        end
      end
    end

    context 'when multiple throttles are present' do
      let(:env) do
        {
          'rack.attack.throttle_data' => {
            'throttle_unauthenticated_api' => {
              discriminator: '127.0.0.1',
              count: 5,
              period: 60,
              limit: 10,
              epoch_time: Time.now.to_i
            },
            'throttle_unauthenticated_web' => {
              discriminator: '127.0.0.1',
              count: 8,
              period: 60,
              limit: 10,
              epoch_time: Time.now.to_i
            }
          }
        }
      end

      it 'returns headers for the most restrictive throttle (lowest remaining)' do
        result_status, result_headers, _result_body = middleware.call(env)

        expect(result_status).to eq(200)
        # Should use throttle_unauthenticated_web (remaining: 2) over throttle_unauthenticated_api (remaining: 5)
        expect(result_headers['RateLimit-Name']).to eq('throttle_unauthenticated_web')
        expect(result_headers['RateLimit-Remaining']).to eq('2')
      end
    end

    context 'with different response status codes' do
      [200, 201, 301, 404, 500].each do |response_status|
        context "when response status is #{response_status}" do
          let(:status) { response_status }
          let(:env) do
            {
              'rack.attack.throttle_data' => {
                'throttle_unauthenticated_web' => {
                  discriminator: '127.0.0.1',
                  count: 3,
                  period: 60,
                  limit: 10,
                  epoch_time: Time.now.to_i
                }
              }
            }
          end

          it 'adds rate limit headers' do
            result_status, result_headers, _result_body = middleware.call(env)

            expect(result_status).to eq(response_status)
            expect(result_headers).to have_key('RateLimit-Limit')
          end
        end
      end
    end

    context 'when throttle data is invalid' do
      context 'when throttle name is nil' do
        let(:env) do
          {
            'rack.attack.throttle_data' => {
              nil => {
                discriminator: '127.0.0.1',
                count: 3,
                period: 60,
                limit: 10,
                epoch_time: Time.now.to_i
              }
            }
          }
        end

        it 'does not add rate limit headers' do
          result_status, result_headers, _result_body = middleware.call(env)

          expect(result_status).to eq(200)
          expect(result_headers).to be_empty
        end
      end

      context 'when throttle data is missing required keys' do
        context 'without count' do
          let(:env) do
            {
              'rack.attack.throttle_data' => {
                'throttle_unauthenticated_api' => {
                  discriminator: '127.0.0.1',
                  period: 60,
                  limit: 10,
                  epoch_time: Time.now.to_i
                }
              }
            }
          end

          it 'does not add rate limit headers' do
            result_status, result_headers, _result_body = middleware.call(env)

            expect(result_status).to eq(200)
            expect(result_headers).to be_empty
          end
        end

        context 'without epoch_time' do
          let(:env) do
            {
              'rack.attack.throttle_data' => {
                'throttle_unauthenticated_api' => {
                  discriminator: '127.0.0.1',
                  count: 5,
                  period: 60,
                  limit: 10
                }
              }
            }
          end

          it 'does not add rate limit headers' do
            result_status, result_headers, _result_body = middleware.call(env)

            expect(result_status).to eq(200)
            expect(result_headers).to be_empty
          end
        end

        context 'without period' do
          let(:env) do
            {
              'rack.attack.throttle_data' => {
                'throttle_unauthenticated_api' => {
                  discriminator: '127.0.0.1',
                  count: 5,
                  limit: 10,
                  epoch_time: Time.now.to_i
                }
              }
            }
          end

          it 'does not add rate limit headers' do
            result_status, result_headers, _result_body = middleware.call(env)

            expect(result_status).to eq(200)
            expect(result_headers).to be_empty
          end
        end

        context 'without limit' do
          let(:env) do
            {
              'rack.attack.throttle_data' => {
                'throttle_unauthenticated_api' => {
                  discriminator: '127.0.0.1',
                  count: 5,
                  period: 60,
                  epoch_time: Time.now.to_i
                }
              }
            }
          end

          it 'does not add rate limit headers' do
            result_status, result_headers, _result_body = middleware.call(env)

            expect(result_status).to eq(200)
            expect(result_headers).to be_empty
          end
        end
      end
    end
  end
end
