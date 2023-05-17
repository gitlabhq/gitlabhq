# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'Slack request verification' do
  describe 'unauthorized request' do
    shared_examples 'an unauthorized request' do
      specify do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    shared_examples 'a successful request that generates a tracked error' do
      specify do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).once

        subject

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when the slack_app_signing_secret setting is not set' do
      before do
        stub_application_setting(slack_app_signing_secret: nil)
      end

      it_behaves_like 'an unauthorized request'
    end

    context 'when the timestamp header has expired' do
      before do
        headers[::API::Integrations::Slack::Request::VERIFICATION_TIMESTAMP_HEADER] = 5.minutes.ago.to_i.to_s
      end

      it_behaves_like 'an unauthorized request'
    end

    context 'when the timestamp header is missing' do
      before do
        headers.delete(::API::Integrations::Slack::Request::VERIFICATION_TIMESTAMP_HEADER)
      end

      it_behaves_like 'an unauthorized request'
    end

    context 'when the signature header is missing' do
      before do
        headers.delete(::API::Integrations::Slack::Request::VERIFICATION_SIGNATURE_HEADER)
      end

      it_behaves_like 'an unauthorized request'
    end

    context 'when the signature is not verified' do
      before do
        headers[::API::Integrations::Slack::Request::VERIFICATION_SIGNATURE_HEADER] = 'unverified_signature'
      end

      it_behaves_like 'an unauthorized request'
    end

    context 'when type param is missing' do
      it_behaves_like 'a successful request that generates a tracked error'
    end
  end
end
