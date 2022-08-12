# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OauthAccessToken do
  let(:user) { create(:user) }
  let(:app_one) { create(:oauth_application) }
  let(:app_two) { create(:oauth_application) }
  let(:app_three) { create(:oauth_application) }
  let(:token) { create(:oauth_access_token, application_id: app_one.id) }

  describe 'scopes' do
    describe '.latest_per_application' do
      let!(:app_two_token1) { create(:oauth_access_token, application: app_two) }
      let!(:app_two_token2) { create(:oauth_access_token, application: app_two) }
      let!(:app_three_token1) { create(:oauth_access_token, application: app_three) }
      let!(:app_three_token2) { create(:oauth_access_token, application: app_three) }

      it 'returns only the latest token for each application' do
        expect(described_class.latest_per_application.map(&:id))
          .to match_array([app_two_token2.id, app_three_token2.id])
      end
    end
  end
end
