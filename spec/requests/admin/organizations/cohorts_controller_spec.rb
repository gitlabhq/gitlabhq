# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Organizations::CohortsController, feature_category: :organization do
  let_it_be(:organization) { create(:common_organization) }
  let_it_be(:other_organization) { create(:organization) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:organization_owner) { create(:user, :organization_owner) }
  let_it_be(:regular_user) { create(:user) }

  describe 'GET #index' do
    subject(:request) { get organization_admin_cohorts_path(organization) }

    let(:other_organization_request) { get organization_admin_cohorts_path(other_organization) }

    it_behaves_like 'an organization admin area request'

    context 'when user is an organization owner' do
      before do
        sign_in(organization_owner)
      end

      it 'scopes cohorts to the organization' do
        expect_next_instance_of(CohortsService, organization: organization) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        request
      end
    end

    context 'when user is an instance admin', :enable_admin_mode do
      before do
        sign_in(admin)
      end

      it 'renders the index' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
