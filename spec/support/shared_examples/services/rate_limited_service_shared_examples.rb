# frozen_string_literal: true

# shared examples for testing rate limited functionality of a service
#
# following resources are expected to be set (example):
#  it_behaves_like 'rate limited service' do
#    let(:key) { :issues_create }
#    let(:key_scope) { %i[project current_user external_author] }
#    let(:application_limit_key) { :issues_create_limit }
#    let(:service) { described_class.new(project: project, current_user: user, params: { title: 'title' }) }
#    let(:created_model) { Issue }
#  end

RSpec.shared_examples 'rate limited service' do
  describe '.rate_limiter_scoped_and_keyed' do
    it 'is set via the rate_limit call' do
      expect(described_class.rate_limiter_scoped_and_keyed).to be_a(RateLimitedService::RateLimiterScopedAndKeyed)

      expect(described_class.rate_limiter_scoped_and_keyed.key).to eq(key)
      expect(described_class.rate_limiter_scoped_and_keyed.opts[:scope]).to eq(key_scope)
      expect(described_class.rate_limiter_scoped_and_keyed.rate_limiter).to eq(Gitlab::ApplicationRateLimiter)
    end
  end

  describe '#rate_limiter_bypassed' do
    it 'is nil by default' do
      expect(service.rate_limiter_bypassed).to be_nil
    end
  end

  describe '#execute' do
    context 'when rate limiting is in effect', :freeze_time, :clean_gitlab_redis_rate_limiting do
      let(:user) { create(:user) }

      before do
        stub_application_setting(application_limit_key => 1)
      end

      subject do
        2.times { service.execute }
      end

      context 'when too many requests are sent by one user' do
        it 'raises an error' do
          expect do
            subject
          end.to raise_error(RateLimitedService::RateLimitedError)
        end

        it 'creates 1 issue' do
          expect do
            subject
          rescue RateLimitedService::RateLimitedError
          end.to change { created_model.count }.by(1)
        end
      end

      context 'when limit is higher than count of issues being created' do
        before do
          stub_application_setting(issues_create_limit: 2)
        end

        it 'creates 2 issues' do
          expect { subject }.to change { created_model.count }.by(2)
        end
      end
    end
  end
end
