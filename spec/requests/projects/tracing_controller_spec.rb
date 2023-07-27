# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TracingController, feature_category: :tracing do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let(:path) { nil }
  let(:observability_tracing_ff) { true }

  subject do
    get path
    response
  end

  before do
    stub_feature_flags(observability_tracing: observability_tracing_ff)
    sign_in(user)
  end

  shared_examples 'tracing route request' do
    it_behaves_like 'observability csp policy' do
      before_all do
        project.add_developer(user)
      end

      let(:tested_path) { path }
    end

    context 'when user does not have permissions' do
      it 'returns 404' do
        expect(subject).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user has permissions' do
      before_all do
        project.add_developer(user)
      end

      it 'returns 200' do
        expect(subject).to have_gitlab_http_status(:ok)
      end

      context 'when feature is disabled' do
        let(:observability_tracing_ff) { false }

        it 'returns 404' do
          expect(subject).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'GET #index' do
    let(:path) { project_tracing_index_path(project) }

    it_behaves_like 'tracing route request'

    describe 'html response' do
      before_all do
        project.add_developer(user)
      end

      it 'renders the js-tracing element correctly' do
        element = Nokogiri::HTML.parse(subject.body).at_css('#js-tracing')

        expected_view_model = {
          tracingUrl: Gitlab::Observability.tracing_url(project),
          provisioningUrl: Gitlab::Observability.provisioning_url(project),
          oauthUrl: Gitlab::Observability.oauth_url
        }.to_json
        expect(element.attributes['data-view-model'].value).to eq(expected_view_model)
      end
    end
  end

  describe 'GET #show' do
    let(:path) { project_tracing_path(project, id: "test-trace-id") }

    it_behaves_like 'tracing route request'

    describe 'html response' do
      before_all do
        project.add_developer(user)
      end

      it 'renders the js-tracing element correctly' do
        element = Nokogiri::HTML.parse(subject.body).at_css('#js-tracing-details')

        expected_view_model = {
          tracingIndexUrl: project_tracing_index_path(project),
          traceId: 'test-trace-id',
          tracingUrl: Gitlab::Observability.tracing_url(project),
          provisioningUrl: Gitlab::Observability.provisioning_url(project),
          oauthUrl: Gitlab::Observability.oauth_url
        }.to_json

        expect(element.attributes['data-view-model'].value).to eq(expected_view_model)
      end
    end
  end
end
