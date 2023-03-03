# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Workhorse, :allow_forgery_protection, feature_category: :shared do
  include WorkhorseHelpers

  context '/authorize_upload' do
    let_it_be(:user) { create(:user) }

    let(:headers) { {} }

    subject { post(api('/internal/workhorse/authorize_upload'), headers: headers) }

    def expect_status(status)
      subject
      expect(response).to have_gitlab_http_status(status)
    end

    context 'without workhorse internal header' do
      it { expect_status(:forbidden) }
    end

    context 'with workhorse internal header' do
      let(:headers) { workhorse_internal_api_request_header }

      it { expect_status(:unauthorized) }

      context 'as a logged in user' do
        before do
          login_as(user)
        end

        it { expect_status(:success) }

        it 'returns the temp upload path' do
          subject
          expect(json_response['TempPath']).to eq(Rails.root.join('tmp/tests/public/uploads/tmp').to_s)
        end
      end
    end
  end
end
