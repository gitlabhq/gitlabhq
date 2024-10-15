# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Performance Bar for API requests', :request_store, :clean_gitlab_redis_cache,
  feature_category: :observability do
  context 'with user that has access to the performance bar' do
    let_it_be(:admin) { create(:admin) }

    context 'when cookie is set to true' do
      before do
        cookies[:perf_bar_enabled] = 'true'
      end

      it 'stores performance data' do
        get api("/users/#{admin.id}", admin)

        expect(Peek.adapter.get(headers['X-Request-Id'])).not_to be_empty
      end
    end

    context 'when cookie is missing' do
      it 'does not store performance data' do
        get api("/users/#{admin.id}", admin)

        expect(Peek.adapter.get(headers['X-Request-Id'])).to be_nil
      end
    end
  end

  context 'with user that does not have access to the performance bar' do
    let(:user) { create(:user) }

    it 'does not store performance data' do
      cookies[:perf_bar_enabled] = 'true'

      get api("/users/#{user.id}", user)

      expect(Peek.adapter.get(headers['X-Request-Id'])).to be_nil
    end
  end
end
