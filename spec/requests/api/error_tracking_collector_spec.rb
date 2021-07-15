# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ErrorTrackingCollector do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:setting) { create(:project_error_tracking_setting, project: project) }

  describe "POST /error_tracking/collector/api/:id/envelope" do
    let_it_be(:raw_event) { fixture_file('error_tracking/event.txt') }
    let_it_be(:url) { "/error_tracking/collector/api/#{project.id}/envelope" }

    let(:params) { raw_event }

    subject { post api(url), params: params }

    RSpec.shared_examples 'not found' do
      it 'reponds with 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    RSpec.shared_examples 'bad request' do
      it 'responds with 400' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'error tracking feature is disabled' do
      before do
        setting.update!(enabled: false)
      end

      it_behaves_like 'not found'
    end

    context 'feature flag is disabled' do
      before do
        stub_feature_flags(integrated_error_tracking: false)
      end

      it_behaves_like 'not found'
    end

    context 'empty body' do
      let(:params) { '' }

      it_behaves_like 'bad request'
    end

    context 'unknown request type' do
      let(:params) { fixture_file('error_tracking/unknown.txt') }

      it_behaves_like 'bad request'
    end

    context 'transaction request type' do
      let(:params) { fixture_file('error_tracking/transaction.txt') }

      it 'does nothing and returns no content' do
        expect { subject }.not_to change { ErrorTracking::ErrorEvent.count }

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    it 'writes to the database and returns no content' do
      expect { subject }.to change { ErrorTracking::ErrorEvent.count }.by(1)

      expect(response).to have_gitlab_http_status(:no_content)
    end
  end
end
