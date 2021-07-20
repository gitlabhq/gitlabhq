# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ProductAnalytics::CollectorApp' do
  let_it_be(:project) { create(:project) }

  let(:params) { {} }
  let(:raw_event) { Gitlab::Json.parse(fixture_file('product_analytics/event.json')) }

  subject { get '/-/collector/i', params: params }

  RSpec.shared_examples 'not found' do
    it 'repond with 404' do
      expect { subject }.not_to change { ProductAnalyticsEvent.count }

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'correct event params' do
    let(:params) { raw_event.merge(aid: project.id) }

    it 'repond with 200' do
      expect { subject }.to change { ProductAnalyticsEvent.count }.by(1)

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'feature disabled' do
      before do
        stub_feature_flags(product_analytics: false)
      end

      it_behaves_like 'not found'
    end
  end

  context 'empty event params' do
    it_behaves_like 'not found'
  end

  context 'invalid project id in params' do
    let(:params) do
      {
        aid: '-1',
        p: 'web',
        tna: 'sp',
        tv: 'js-2.14.0',
        eid: SecureRandom.uuid,
        duid: SecureRandom.uuid,
        sid: SecureRandom.uuid
      }
    end

    it_behaves_like 'not found'
  end
end
