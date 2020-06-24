# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OauthAccessGrant do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application, owner: user) }

  describe '#delete' do
    it 'cascades to oauth_openid_requests' do
      access_grant = create(:oauth_access_grant, application: application)
      create(:oauth_openid_request, access_grant: access_grant)

      expect { access_grant.delete }.to change(Doorkeeper::OpenidConnect::Request, :count).by(-1)
    end
  end
end
