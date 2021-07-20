# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RateLimitHelpers, :clean_gitlab_redis_cache do
  let(:limiter_class) do
    Class.new do
      include ::Gitlab::RateLimitHelpers

      attr_reader :request

      def initialize(request)
        @request = request
      end
    end
  end

  let(:request) { instance_double(ActionDispatch::Request, request_method: 'GET', ip: '127.0.0.1', fullpath: '/') }
  let(:class_instance) { limiter_class.new(request) }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  describe '#archive_rate_limit_reached?' do
    context 'with a user' do
      it 'rate limits the user properly' do
        5.times do
          expect(class_instance.archive_rate_limit_reached?(user, project)).to be_falsey
        end

        expect(class_instance.archive_rate_limit_reached?(user, project)).to be_truthy
      end
    end

    context 'with an anonymous user' do
      before do
        stub_const('Gitlab::RateLimitHelpers::ARCHIVE_RATE_ANONYMOUS_THRESHOLD', 2)
      end

      it 'rate limits with higher limits' do
        2.times do
          expect(class_instance.archive_rate_limit_reached?(nil, project)).to be_falsey
        end

        expect(class_instance.archive_rate_limit_reached?(nil, project)).to be_truthy
        expect(class_instance.archive_rate_limit_reached?(user, project)).to be_falsey
      end
    end
  end
end
