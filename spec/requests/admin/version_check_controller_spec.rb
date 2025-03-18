# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::VersionCheckController, :enable_admin_mode, feature_category: :shared do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #version_check' do
    let(:version_check_response) { { 'success' => true, 'version' => '16.0.0' } }

    context 'when version check is successful' do
      before do
        allow(Rails.cache).to receive(:fetch).with("version_check").and_return(version_check_response)
      end

      it 'returns version check data' do
        get admin_version_check_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(version_check_response)
      end

      it 'sets cache expiration to 1 minute' do
        get admin_version_check_path

        expect(response.headers['Cache-Control']).to include('max-age=60')
      end
    end

    context 'when version check fails' do
      before do
        allow(VersionCheckHelper).to receive(:gitlab_version_check).and_return(nil)
      end

      it 'returns nil without cache headers' do
        get admin_version_check_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_nil
        expect(response.headers['Cache-Control']).not_to include('max-age=60')
      end
    end
  end
end
