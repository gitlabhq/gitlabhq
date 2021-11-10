# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  subject { described_class }

  describe '.throttled?', :clean_gitlab_redis_rate_limiting do
    let(:rate_limits) do
      {
        test_action: {
          threshold: 1,
          interval: 2.minutes
        },
        another_action: {
          threshold: 2,
          interval: 3.minutes
        }
      }
    end

    before do
      allow(described_class).to receive(:rate_limits).and_return(rate_limits)
    end

    context 'when the key is invalid' do
      context 'is provided as a Symbol' do
        context 'but is not defined in the rate_limits Hash' do
          it 'raises an InvalidKeyError exception' do
            key = :key_not_in_rate_limits_hash

            expect { subject.throttled?(key) }.to raise_error(Gitlab::ApplicationRateLimiter::InvalidKeyError)
          end
        end
      end

      context 'is provided as a String' do
        context 'and is a String representation of an existing key in rate_limits Hash' do
          it 'raises an InvalidKeyError exception' do
            key = rate_limits.keys[0].to_s

            expect { subject.throttled?(key) }.to raise_error(Gitlab::ApplicationRateLimiter::InvalidKeyError)
          end
        end

        context 'but is not defined in any form in the rate_limits Hash' do
          it 'raises an InvalidKeyError exception' do
            key = 'key_not_in_rate_limits_hash'

            expect { subject.throttled?(key) }.to raise_error(Gitlab::ApplicationRateLimiter::InvalidKeyError)
          end
        end
      end
    end

    shared_examples 'throttles based on key and scope' do
      let(:start_time) { Time.current.beginning_of_hour }

      it 'returns true when threshold is exceeded' do
        travel_to(start_time) do
          expect(subject.throttled?(:test_action, scope: scope)).to eq(false)
        end

        travel_to(start_time + 1.minute) do
          expect(subject.throttled?(:test_action, scope: scope)).to eq(true)

          # Assert that it does not affect other actions or scope
          expect(subject.throttled?(:another_action, scope: scope)).to eq(false)
          expect(subject.throttled?(:test_action, scope: [user])).to eq(false)
        end
      end

      it 'returns false when interval has elapsed' do
        travel_to(start_time) do
          expect(subject.throttled?(:test_action, scope: scope)).to eq(false)

          # another_action has a threshold of 3 so we simulate 2 requests
          expect(subject.throttled?(:another_action, scope: scope)).to eq(false)
          expect(subject.throttled?(:another_action, scope: scope)).to eq(false)
        end

        travel_to(start_time + 2.minutes) do
          expect(subject.throttled?(:test_action, scope: scope)).to eq(false)

          # Assert that another_action has its own interval that hasn't elapsed
          expect(subject.throttled?(:another_action, scope: scope)).to eq(true)
        end
      end
    end

    context 'when using ActiveRecord models as scope' do
      let(:scope) { [user, project] }

      it_behaves_like 'throttles based on key and scope'
    end

    context 'when using ActiveRecord models and strings as scope' do
      let(:scope) { [project, 'app/controllers/groups_controller.rb'] }

      it_behaves_like 'throttles based on key and scope'
    end
  end

  describe '.log_request' do
    let(:file_path) { 'master/README.md' }
    let(:type) { :raw_blob_request_limit }
    let(:fullpath) { "/#{project.full_path}/raw/#{file_path}" }

    let(:request) do
      double('request', ip: '127.0.0.1', request_method: 'GET', fullpath: fullpath)
    end

    let(:base_attributes) do
      {
        message: 'Application_Rate_Limiter_Request',
        env: type,
        remote_ip: '127.0.0.1',
        request_method: 'GET',
        path: fullpath
      }
    end

    context 'without a current user' do
      let(:current_user) { nil }

      it 'logs information to auth.log' do
        expect(Gitlab::AuthLogger).to receive(:error).with(base_attributes).once

        subject.log_request(request, type, current_user)
      end
    end

    context 'with a current_user' do
      let(:current_user) { user }

      let(:attributes) do
        base_attributes.merge({
                                user_id: current_user.id,
                                username: current_user.username
                              })
      end

      it 'logs information to auth.log' do
        expect(Gitlab::AuthLogger).to receive(:error).with(attributes).once

        subject.log_request(request, type, current_user)
      end
    end
  end
end
