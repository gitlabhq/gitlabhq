# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ErrorTracking::Collector, feature_category: :error_tracking do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:setting) { create(:project_error_tracking_setting, :integrated, project: project) }
  let_it_be(:client_key) { create(:error_tracking_client_key, project: project) }

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

  RSpec.shared_examples 'successful request' do
    it 'writes to the database and returns OK', :aggregate_failures do
      expect { subject }.to change { ErrorTracking::ErrorEvent.count }.by(1)
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe "POST /error_tracking/collector/api/:id/envelope" do
    let_it_be(:raw_event) { fixture_file('error_tracking/event.txt') }
    let_it_be(:url) { "/error_tracking/collector/api/#{project.id}/envelope" }

    let(:params) { raw_event }
    let(:headers) { { 'X-Sentry-Auth' => "Sentry sentry_key=#{client_key.public_key}" } }

    subject { post api(url), params: params, headers: headers }

    it_behaves_like 'successful request'

    context 'intergrated error tracking feature flag is disabled' do
      before do
        stub_feature_flags(integrated_error_tracking: false)
      end

      it_behaves_like 'not found'
    end

    context 'error tracking feature is disabled' do
      before do
        setting.update!(enabled: false)
      end

      it_behaves_like 'not found'
    end

    context 'integrated error tracking is disabled' do
      before do
        setting.update!(integrated: false)
      end

      it_behaves_like 'not found'
    end

    context 'auth headers are missing' do
      let(:headers) { {} }

      it_behaves_like 'bad request'
    end

    context 'public key is wrong' do
      let(:headers) { { 'X-Sentry-Auth' => "Sentry sentry_key=glet_1fedb514e17f4b958435093deb02048c" } }

      it_behaves_like 'not found'
    end

    context 'public key is inactive' do
      let(:client_key) { create(:error_tracking_client_key, :disabled, project: project) }

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

      it 'does nothing and returns ok' do
        expect { subject }.not_to change { ErrorTracking::ErrorEvent.count }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'gzip body' do
      let(:standard_headers) do
        {
          'X-Sentry-Auth' => "Sentry sentry_key=#{client_key.public_key}",
          'HTTP_CONTENT_ENCODING' => 'gzip'
        }
      end

      let(:params) { ActiveSupport::Gzip.compress(raw_event) }

      context 'with application/x-sentry-envelope Content-Type' do
        let(:headers) { standard_headers.merge({ 'CONTENT_TYPE' => 'application/x-sentry-envelope' }) }

        it_behaves_like 'successful request'
      end

      context 'with unexpected Content-Type' do
        let(:headers) { standard_headers.merge({ 'CONTENT_TYPE' => 'application/gzip' }) }

        it 'responds with 415' do
          subject

          expect(response).to have_gitlab_http_status(:unsupported_media_type)
        end
      end
    end
  end

  describe "POST /error_tracking/collector/api/:id/store" do
    let_it_be(:raw_event) { fixture_file('error_tracking/parsed_event.json') }
    let_it_be(:url) { "/error_tracking/collector/api/#{project.id}/store" }

    let(:params) { raw_event }
    let(:headers) { { 'X-Sentry-Auth' => "Sentry sentry_key=#{client_key.public_key}" } }

    subject { post api(url), params: params, headers: headers }

    it_behaves_like 'successful request'

    context 'empty headers' do
      let(:headers) { {} }

      it_behaves_like 'bad request'
    end

    context 'empty body' do
      let(:params) { '' }

      it_behaves_like 'bad request'
    end

    context 'body with string instead of json' do
      let(:params) { '"********"' }

      it_behaves_like 'bad request'
    end

    context 'collector fails with validation error' do
      before do
        allow(::ErrorTracking::CollectErrorService)
          .to receive(:new).and_raise(Gitlab::ErrorTracking::ErrorRepository::DatabaseError)
      end

      it_behaves_like 'bad request'
    end

    context 'with platform field too long' do
      let(:params) do
        event = Gitlab::Json.parse(raw_event)
        event['platform'] = 'a' * 256
        Gitlab::Json.dump(event)
      end

      it_behaves_like 'bad request'
    end

    context 'gzip body' do
      let(:headers) do
        {
          'X-Sentry-Auth' => "Sentry sentry_key=#{client_key.public_key}",
          'HTTP_CONTENT_ENCODING' => 'gzip',
          'CONTENT_TYPE' => 'application/json'
        }
      end

      let(:params) { ActiveSupport::Gzip.compress(raw_event) }

      it_behaves_like 'successful request'
    end

    context 'body contains nullbytes' do
      let_it_be(:raw_event) { fixture_file('error_tracking/parsed_event_nullbytes.json') }

      it_behaves_like 'successful request'
    end

    context 'when JSON key transaction is empty string' do
      let_it_be(:raw_event) { fixture_file('error_tracking/php_empty_transaction.json') }

      it_behaves_like 'successful request'
    end

    context 'sentry_key as param and empty headers' do
      let(:url) { "/error_tracking/collector/api/#{project.id}/store?sentry_key=#{sentry_key}" }
      let(:headers) { {} }

      context 'key is wrong' do
        let(:sentry_key) { 'glet_1fedb514e17f4b958435093deb02048c' }

        it_behaves_like 'not found'
      end

      context 'key is empty' do
        let(:sentry_key) { '' }

        it_behaves_like 'bad request'
      end

      context 'key is correct' do
        let(:sentry_key) { client_key.public_key }

        it_behaves_like 'successful request'
      end
    end
  end
end
