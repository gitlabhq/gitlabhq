# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ApplicationRateLimiter, :clean_gitlab_redis_cache do
  let(:redis) { double('redis') }
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:rate_limits) do
    {
      test_action: {
        threshold: 1,
        interval: 2.minutes
      }
    }
  end
  let(:key) { rate_limits.keys[0] }

  subject { described_class }

  before do
    allow(Gitlab::Redis::Cache).to receive(:with).and_yield(redis)
    allow(described_class).to receive(:rate_limits).and_return(rate_limits)
  end

  shared_examples 'action rate limiter' do
    it 'increases the throttle count and sets the expiration time' do
      expect(redis).to receive(:incr).with(cache_key).and_return(1)
      expect(redis).to receive(:expire).with(cache_key, 120)

      expect(subject.throttled?(key, scope: scope)).to be_falsy
    end

    it 'returns true if the key is throttled' do
      expect(redis).to receive(:incr).with(cache_key).and_return(2)
      expect(redis).not_to receive(:expire)

      expect(subject.throttled?(key, scope: scope)).to be_truthy
    end

    context 'when throttling is disabled' do
      it 'returns false and does not set expiration time' do
        expect(redis).not_to receive(:incr)
        expect(redis).not_to receive(:expire)

        expect(subject.throttled?(key, scope: scope, threshold: 0)).to be_falsy
      end
    end
  end

  context 'when the key is an array of only ActiveRecord models' do
    let(:scope) { [user, project] }

    let(:cache_key) do
      "application_rate_limiter:test_action:user:#{user.id}:project:#{project.id}"
    end

    it_behaves_like 'action rate limiter'
  end

  context 'when they key a combination of ActiveRecord models and strings' do
    let(:project) { create(:project, :public, :repository) }
    let(:commit) { project.repository.commit }
    let(:path) { 'app/controllers/groups_controller.rb' }
    let(:scope) { [project, commit, path] }

    let(:cache_key) do
      "application_rate_limiter:test_action:project:#{project.id}:commit:#{commit.sha}:#{path}"
    end

    it_behaves_like 'action rate limiter'
  end

  describe '#log_request' do
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
      let(:current_user) { create(:user) }

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
