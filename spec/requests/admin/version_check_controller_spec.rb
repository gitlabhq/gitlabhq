# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::VersionCheckController, :enable_admin_mode, feature_category: :shared do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #version_check' do
    context 'when VersionCheck.response is nil' do
      before do
        allow_next_instance_of(VersionCheck) do |instance|
          allow(instance).to receive(:response).and_return(nil)
        end
        get admin_version_check_path
      end

      it 'returns nil' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_nil
      end

      it 'sets no-cache headers' do
        expect(response.headers['Cache-Control']).to eq('max-age=0, private, must-revalidate')
      end
    end

    context 'when VersionCheck.response is valid' do
      before do
        allow_next_instance_of(VersionCheck) do |instance|
          allow(instance).to receive(:response).and_return({ "severity" => "success" })
        end

        get admin_version_check_path
      end

      it 'returns the valid data' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ "severity" => "success" })
      end

      it 'sets proper cache headers' do
        expect(response.headers['Cache-Control']).to eq('max-age=60, private')
      end
    end
  end
end
