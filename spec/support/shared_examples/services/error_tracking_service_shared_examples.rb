# frozen_string_literal: true

RSpec.shared_examples 'error tracking service data not ready' do |service_call|
  context "when #{service_call} returns nil" do
    before do
      expect(error_tracking_setting)
        .to receive(service_call).and_return(nil)
    end

    it 'result is not ready' do
      expect(result).to eq(
        status: :error, http_status: :no_content, message: 'Not ready. Try again later')
    end
  end
end

RSpec.shared_examples 'error tracking service sentry error handling' do |service_call|
  context "when #{service_call} returns error" do
    before do
      allow(error_tracking_setting)
        .to receive(service_call)
        .and_return(
          error: 'Sentry response status code: 401',
          error_type: ErrorTracking::ProjectErrorTrackingSetting::SENTRY_API_ERROR_TYPE_NON_20X_RESPONSE
        )
    end

    it 'returns the error' do
      expect(result).to eq(
        status: :error,
        http_status: :bad_request,
        message: 'Sentry response status code: 401'
      )
    end
  end
end

RSpec.shared_examples 'error tracking service http status handling' do |service_call|
  context "when #{service_call} returns error with http_status" do
    before do
      allow(error_tracking_setting)
        .to receive(service_call)
        .and_return(
          error: 'Sentry API response is missing keys. key not found: "id"',
          error_type: ErrorTracking::ProjectErrorTrackingSetting::SENTRY_API_ERROR_TYPE_MISSING_KEYS
        )
    end

    it 'returns the error with correct http_status' do
      expect(result).to eq(
        status: :error,
        http_status: :internal_server_error,
        message: 'Sentry API response is missing keys. key not found: "id"'
      )
    end
  end
end

RSpec.shared_examples 'error tracking service unauthorized user' do
  context 'with unauthorized user' do
    let(:unauthorized_user) { create(:user) }

    subject { described_class.new(project, unauthorized_user) }

    it 'returns error' do
      result = subject.execute

      expect(result).to include(
        status: :error,
        message: 'Access denied',
        http_status: :unauthorized
      )
    end
  end
end

RSpec.shared_examples 'error tracking service disabled' do
  context 'with error tracking disabled' do
    before do
      error_tracking_setting.enabled = false
    end

    it 'raises error' do
      result = subject.execute

      expect(result).to include(status: :error, message: 'Error Tracking is not enabled')
    end
  end
end
